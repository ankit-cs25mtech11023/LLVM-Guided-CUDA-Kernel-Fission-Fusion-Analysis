#include "llvm/Pass.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Metadata.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/IntrinsicInst.h" // Needed for Intrinsics
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include <map>
#include <set>

using namespace llvm;

enum class InstCategory {
	MEMORY_READ,
	MEMORY_WRITE,
	COMPUTE_LIGHT,   // add, mul, sub
	COMPUTE_HEAVY,   // sin, cos, div, sqrt
	CONTROL,         // branches, phi nodes
	SYNC,            // __syncthreads()
	INDEX_CALC,      // getelementptr (GEP)
	OTHER
};
enum class PhaseType {
    LOAD,
    COMPUTE,
    STORE,
    MIXED,
    PREAMBLE // Setup code (like thread ID calculations) before the real work
};

struct KernelPhase {
    int PhaseID;
    PhaseType Type;
    std::vector<BasicBlock*> Blocks;

    // Summary statistics for the cost model later
    int NumMemRead = 0;
    int NumMemWrite = 0;
    int NumComputeLight = 0;
    int NumComputeHeavy = 0;

    // Loop information
    bool ContainsLoop = false;
    int EstimatedLoopTripCount = 1; // default 1 means "no loop"
};

InstCategory classifyInstruction(Instruction *I) {
	// 1. Memory Operations
	if (isa<LoadInst>(I))  return InstCategory::MEMORY_READ;
	if (isa<StoreInst>(I)) return InstCategory::MEMORY_WRITE;
	
	// 2. Index Calculations
	if (isa<GetElementPtrInst>(I)) return InstCategory::INDEX_CALC;

	// 3. Control Flow
	if (isa<BranchInst>(I) || isa<SwitchInst>(I) || 
		isa<PHINode>(I) || isa<SelectInst>(I) || isa<ReturnInst>(I)) {
		return InstCategory::CONTROL;
	}

	// 4. Function Calls, Intrinsics, and Inline Assembly
	if (auto *CI = dyn_cast<CallInst>(I)) {
		// Check for inline PTX assembly
		if (CI->isInlineAsm()) {
			return InstCategory::COMPUTE_HEAVY;
		}

		// Safely check the function name for NVVM/CUDA specific calls
		Function *Callee = CI->getCalledFunction();
		if (Callee) {
			StringRef Name = Callee->getName();
			
			if (Name.contains("barrier") || Name.contains("syncthreads"))
				return InstCategory::SYNC;
			if (Name.startswith("llvm.nvvm.read.ptx.sreg"))
				return InstCategory::INDEX_CALC;
			if (Name.contains("sin") || Name.contains("cos") || Name.contains("exp") || Name.contains("log") || Name.contains("sqrt"))
				return InstCategory::COMPUTE_HEAVY;
			if (Name.contains("nvvm.f2i") || Name.contains("nvvm.i2f"))
				return InstCategory::COMPUTE_LIGHT; // fast type conversions
		}

		// Check for standard LLVM Intrinsics (fma, fabs, etc.)
		if (auto *II = dyn_cast<IntrinsicInst>(CI)) {
			switch (II->getIntrinsicID()) {
				case Intrinsic::fma:
				case Intrinsic::fabs:
				case Intrinsic::copysign:
					return InstCategory::COMPUTE_LIGHT;
				default:
					break; 
			}
		}
		
		return InstCategory::OTHER;
	}

	// 5. Standard Arithmetic
	if (auto *BO = dyn_cast<BinaryOperator>(I)) {
		unsigned Op = BO->getOpcode();
		if (Op == Instruction::UDiv || Op == Instruction::SDiv ||
			Op == Instruction::URem || Op == Instruction::SRem ||
			Op == Instruction::FDiv || Op == Instruction::FRem) {
			return InstCategory::COMPUTE_HEAVY;
		}
		return InstCategory::COMPUTE_LIGHT; 
	}
	
	if (isa<CmpInst>(I)) return InstCategory::COMPUTE_LIGHT;

	return InstCategory::OTHER;
}


PhaseType classifyBasicBlock(BasicBlock *BB, 
                             int memReads, int memWrites, 
                             int computeLight, int computeHeavy, int syncs) {
    
    // If there is a barrier, this block is a hard boundary.
    if (syncs > 0) return PhaseType::MIXED;

    int totalInstructions = memReads + memWrites + computeLight + computeHeavy;
    if (totalInstructions == 0) return PhaseType::PREAMBLE;

    // Calculate ratios
    float readRatio = (float)memReads / totalInstructions;
    float writeRatio = (float)memWrites / totalInstructions;
    float computeRatio = (float)(computeLight + computeHeavy) / totalInstructions;

    // Heuristics for dominant behavior
    if (readRatio > 0.5f) return PhaseType::LOAD;
    if (writeRatio > 0.5f) return PhaseType::STORE;
    if (computeRatio > 0.5f) return PhaseType::COMPUTE;

    return PhaseType::MIXED;
}

namespace {
	// Inherit from ModulePass for legacy PM
	
	struct KernelFissionPass : public ModulePass {
		static char ID; // Pass identification, replacement for typeid
		
		KernelFissionPass() : ModulePass(ID) {}

		void getAnalysisUsage(AnalysisUsage &AU) const override {
			AU.addRequired<LoopInfoWrapperPass>();
			AU.addRequired<ScalarEvolutionWrapperPass>();
			AU.setPreservesAll();
		}

		// Entry point for a ModulePass
		bool runOnModule(Module &M) override {
			NamedMDNode *NMD = M.getNamedMetadata("nvvm.annotations");
			if (!NMD) {
				// Return false to indicate the IR was NOT modified by this pass
				return false; 
			}

			std::vector<Function*> Kernels;

			for (unsigned i = 0; i < NMD->getNumOperands(); i++) {
				MDNode *MD = NMD->getOperand(i);
				
				// We expect a tuple like: {Function*, "kernel", 1}
				if (MD->getNumOperands() >= 3) {
					auto *MF = dyn_cast<ValueAsMetadata>(MD->getOperand(0));
					auto *MS = dyn_cast<MDString>(MD->getOperand(1));
					
					if (MF && MS && MS->getString() == "kernel") {
						if (auto *F = dyn_cast<Function>(MF->getValue())) {
							Kernels.push_back(F);
							errs() << "Discovered CUDA Kernel: " << F->getName() << "\n";
							
							std::vector<KernelPhase> Phases;
							KernelPhase CurrentPhase;
							CurrentPhase.PhaseID = 0;
							CurrentPhase.Type = PhaseType::PREAMBLE; // Start with preamble assumption

							LoopInfo &LI = getAnalysis<LoopInfoWrapperPass>(*F).getLoopInfo();
							ScalarEvolution &SE = getAnalysis<ScalarEvolutionWrapperPass>(*F).getSE();

							// Build a map: BasicBlock* -> its outermost Loop*
							std::map<BasicBlock*, Loop*> BBToLoop;
							for (Loop *L : LI) {
								for (BasicBlock *LBB : L->blocks()) {
									if (!BBToLoop.count(LBB))
										BBToLoop[LBB] = L;
								}
							}

							std::set<Loop*> ProcessedLoops;

							for (BasicBlock &BB : *F) {

								// --- Case 1: This BB is inside a loop ---
								if (BBToLoop.count(&BB)) {
									Loop *L = BBToLoop[&BB];
									if (ProcessedLoops.count(L)) continue; // already handled all BBs of this loop
									ProcessedLoops.insert(L);

									// Count instructions across ALL BBs in the loop
									int reads = 0, writes = 0, cLight = 0, cHeavy = 0, syncs = 0;
									for (BasicBlock *LBB : L->blocks()) {
										for (Instruction &I : *LBB) {
											InstCategory Cat = classifyInstruction(&I);
											if (Cat == InstCategory::MEMORY_READ)    reads++;
											else if (Cat == InstCategory::MEMORY_WRITE)  writes++;
											else if (Cat == InstCategory::COMPUTE_LIGHT) cLight++;
											else if (Cat == InstCategory::COMPUTE_HEAVY) cHeavy++;
											else if (Cat == InstCategory::SYNC)          syncs++;
										}
									}

									// A loop containing __syncthreads() cannot be split — treat as MIXED hard boundary
									PhaseType LoopType = (syncs > 0) ? PhaseType::MIXED : PhaseType::COMPUTE;

									// A loop is always its own phase — close whatever was open before it
									if (!CurrentPhase.Blocks.empty())
										Phases.push_back(CurrentPhase);

									CurrentPhase = KernelPhase();
									CurrentPhase.PhaseID = Phases.size();
									CurrentPhase.Type = LoopType;
									CurrentPhase.ContainsLoop = true;

									// Get static trip count; default to 100 if unknown (e.g. data-dependent bound)
									unsigned TC = SE.getSmallConstantTripCount(L);
									CurrentPhase.EstimatedLoopTripCount = (TC > 0) ? (int)TC : 100;

									for (BasicBlock *LBB : L->blocks())
										CurrentPhase.Blocks.push_back(LBB);

									CurrentPhase.NumMemRead      += reads;
									CurrentPhase.NumMemWrite     += writes;
									CurrentPhase.NumComputeLight += cLight;
									CurrentPhase.NumComputeHeavy += cHeavy;

									// Close the loop phase immediately — nothing merges into it from outside
									Phases.push_back(CurrentPhase);
									CurrentPhase = KernelPhase();
									CurrentPhase.PhaseID = Phases.size();
									CurrentPhase.Type = PhaseType::PREAMBLE;

								// --- Case 2: Normal BB, not inside any loop ---
								} else {
									int reads = 0, writes = 0, cLight = 0, cHeavy = 0, syncs = 0;
									for (Instruction &I : BB) {
										InstCategory Cat = classifyInstruction(&I);
										if (Cat == InstCategory::MEMORY_READ)    reads++;
										else if (Cat == InstCategory::MEMORY_WRITE)  writes++;
										else if (Cat == InstCategory::COMPUTE_LIGHT) cLight++;
										else if (Cat == InstCategory::COMPUTE_HEAVY) cHeavy++;
										else if (Cat == InstCategory::SYNC)          syncs++;
									}

									PhaseType BlockType = classifyBasicBlock(&BB, reads, writes, cLight, cHeavy, syncs);

									if (BlockType == CurrentPhase.Type || CurrentPhase.Blocks.empty()) {
										CurrentPhase.Type = BlockType;
										CurrentPhase.Blocks.push_back(&BB);
										CurrentPhase.NumMemRead      += reads;
										CurrentPhase.NumMemWrite     += writes;
										CurrentPhase.NumComputeLight += cLight;
										CurrentPhase.NumComputeHeavy += cHeavy;
									} else {
										Phases.push_back(CurrentPhase);
										CurrentPhase = KernelPhase();
										CurrentPhase.PhaseID = Phases.size();
										CurrentPhase.Type = BlockType;
										CurrentPhase.Blocks.push_back(&BB);
										CurrentPhase.NumMemRead      += reads;
										CurrentPhase.NumMemWrite     += writes;
										CurrentPhase.NumComputeLight += cLight;
										CurrentPhase.NumComputeHeavy += cHeavy;
									}
								}
							}
							// Push the very last phase
							if (!CurrentPhase.Blocks.empty()) {
								Phases.push_back(CurrentPhase);
							}

							// --- PRINT THE RESULTS ---
							errs() << "Detected " << Phases.size() << " Phases:\n";
							for (const auto &P : Phases) {
								errs() << "  Phase " << P.PhaseID << ": ";
								if (P.Type == PhaseType::LOAD) errs() << "LOAD\n";
								else if (P.Type == PhaseType::COMPUTE) errs() << "COMPUTE\n";
								else if (P.Type == PhaseType::STORE) errs() << "STORE\n";
								else if (P.Type == PhaseType::MIXED) errs() << "MIXED\n";
								else errs() << "PREAMBLE\n";
								
								errs() << "    Blocks: " << P.Blocks.size() << "\n";
								errs() << "    Stats -> Read: " << P.NumMemRead
									<< ", Write: " << P.NumMemWrite
									<< ", Compute: " << (P.NumComputeLight + P.NumComputeHeavy) << "\n";
								if (P.ContainsLoop)
									errs() << "    Loop: yes (trip count = " << P.EstimatedLoopTripCount << ")\n";
							}


							// std::map<InstCategory, int> CategoryCounts;

							// // A Function is a list of Basic Blocks
							// for (BasicBlock &BB : *F) {
							// 	// A Basic Block is a list of Instructions
							// 	for (Instruction &I : BB) {
							// 		InstCategory Cat = classifyInstruction(&I);
							// 		CategoryCounts[Cat]++;
							// 	}
							// }

							// // Print the summary for this kernel
							// errs() << "  Instruction Breakdown:\n";
							// errs() << "    Memory Reads  : " << CategoryCounts[InstCategory::MEMORY_READ] << "\n";
							// errs() << "    Memory Writes : " << CategoryCounts[InstCategory::MEMORY_WRITE] << "\n";
							// errs() << "    Compute Light : " << CategoryCounts[InstCategory::COMPUTE_LIGHT] << "\n";
							// errs() << "    Compute Heavy : " << CategoryCounts[InstCategory::COMPUTE_HEAVY] << "\n";
							// errs() << "    Control Flow  : " << CategoryCounts[InstCategory::CONTROL] << "\n";
							// errs() << "    Index Calc    : " << CategoryCounts[InstCategory::INDEX_CALC] << "\n";
						}
					}
				}
			}
			return false; 
		}
	};
}

// Initialize the ID to 0 (LLVM handles the actual assignment under the hood)
char KernelFissionPass::ID = 0;

// Register the pass so 'opt' can find it via the command line flag
static RegisterPass<KernelFissionPass> X("kernel-fission", "Kernel Fission Pass", false, false);			// Return false because this is purely an analysis step right now.