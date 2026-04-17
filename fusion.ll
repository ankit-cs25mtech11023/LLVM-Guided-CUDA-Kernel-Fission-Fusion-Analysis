; ModuleID = 'fusion.cu'
source_filename = "fusion.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

@__cudart_i2opi_f = internal unnamed_addr addrspace(1) constant [6 x i32] [i32 1011060801, i32 -614296167, i32 -181084736, i32 -64530479, i32 1313084713, i32 -1560706194], align 4

; Function Attrs: norecurse nounwind
define dso_local void @_Z12fused_kernelPffS_(float* nocapture noundef readonly %0, float noundef %1, float* nocapture noundef writeonly %2) local_unnamed_addr #0 {
  %4 = alloca [7 x i32], align 4
  %5 = alloca [7 x i32], align 4
  %6 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #5
  %7 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #5
  %8 = mul i32 %6, %7
  %9 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x() #5
  %10 = add i32 %8, %9
  %11 = icmp sgt i32 %10, 1048575
  br i1 %11, label %231, label %12

12:                                               ; preds = %3
  %13 = sext i32 %10 to i64
  %14 = getelementptr inbounds float, float* %0, i64 %13
  %15 = load float, float* %14, align 4, !tbaa !7
  %16 = fmul contract float %15, 2.000000e+00
  %17 = fadd contract float %16, %1
  %18 = bitcast [7 x i32]* %5 to i8*
  %19 = getelementptr inbounds [7 x i32], [7 x i32]* %5, i64 0, i64 6
  %20 = bitcast [7 x i32]* %4 to i8*
  %21 = getelementptr inbounds [7 x i32], [7 x i32]* %4, i64 0, i64 6
  br label %24

22:                                               ; preds = %208
  %23 = getelementptr inbounds float, float* %2, i64 %13
  store float %228, float* %23, align 4, !tbaa !7
  br label %231

24:                                               ; preds = %12, %208
  %25 = phi i32 [ 0, %12 ], [ %229, %208 ]
  %26 = phi float [ %17, %12 ], [ %228, %208 ]
  call void @llvm.lifetime.start.p0i8(i64 28, i8* nonnull %18) #5
  %27 = fmul float %26, 0x3FE45F3060000000
  %28 = call i32 @llvm.nvvm.f2i.rn(float %27) #5
  %29 = sitofp i32 %28 to float
  %30 = call float @llvm.fma.f32(float %29, float 0xBFF921FB40000000, float %26) #5
  %31 = call float @llvm.fma.f32(float %29, float 0xBE74442D00000000, float %30) #5
  %32 = call float @llvm.fma.f32(float %29, float 0xBCF84698A0000000, float %31) #5
  %33 = call float @llvm.fabs.f32(float %26) #5
  %34 = fcmp ogt float %33, 1.056150e+05
  br i1 %34, label %35, label %112

35:                                               ; preds = %24
  %36 = fcmp oeq float %33, 0x7FF0000000000000
  br i1 %36, label %37, label %39

37:                                               ; preds = %35
  %38 = fmul float %26, 0.000000e+00
  br label %112

39:                                               ; preds = %35
  %40 = bitcast float %26 to i32
  %41 = lshr i32 %40, 23
  %42 = shl i32 %40, 8
  %43 = or i32 %42, -2147483648
  br label %44

44:                                               ; preds = %44, %39
  %45 = phi i32 [ 0, %39 ], [ %54, %44 ]
  %46 = phi i32 [ 0, %39 ], [ %52, %44 ]
  %47 = zext i32 %45 to i64
  %48 = getelementptr inbounds [6 x i32], [6 x i32] addrspace(1)* @__cudart_i2opi_f, i64 0, i64 %47
  %49 = load i32, i32 addrspace(1)* %48, align 4
  %50 = call { i32, i32 } asm "{\0A\09mad.lo.cc.u32   $0, $2, $3, $4;\0A\09madc.hi.u32     $1, $2, $3,  0;\0A\09}", "=r,=r,r,r,r"(i32 %49, i32 %43, i32 %46) #6, !srcloc !11
  %51 = extractvalue { i32, i32 } %50, 0
  %52 = extractvalue { i32, i32 } %50, 1
  %53 = getelementptr inbounds [7 x i32], [7 x i32]* %5, i64 0, i64 %47
  store i32 %51, i32* %53, align 4
  %54 = add nuw nsw i32 %45, 1
  %55 = icmp eq i32 %54, 6
  br i1 %55, label %56, label %44, !llvm.loop !12

56:                                               ; preds = %44
  %57 = and i32 %41, 255
  %58 = extractvalue { i32, i32 } %50, 1
  %59 = add nsw i32 %57, -128
  %60 = lshr i32 %59, 5
  %61 = and i32 %40, -2147483648
  store i32 %58, i32* %19, align 4
  %62 = and i32 %41, 31
  %63 = sub nsw i32 6, %60
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds [7 x i32], [7 x i32]* %5, i64 0, i64 %64
  %66 = load i32, i32* %65, align 4
  %67 = sub nsw i32 5, %60
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds [7 x i32], [7 x i32]* %5, i64 0, i64 %68
  %70 = load i32, i32* %69, align 4
  %71 = icmp eq i32 %62, 0
  br i1 %71, label %84, label %72

72:                                               ; preds = %56
  %73 = sub nsw i32 4, %60
  %74 = sub nuw nsw i32 32, %62
  %75 = shl i32 %66, %62
  %76 = lshr i32 %70, %74
  %77 = add i32 %76, %75
  %78 = shl i32 %70, %62
  %79 = sext i32 %73 to i64
  %80 = getelementptr inbounds [7 x i32], [7 x i32]* %5, i64 0, i64 %79
  %81 = load i32, i32* %80, align 4
  %82 = lshr i32 %81, %74
  %83 = add i32 %82, %78
  br label %84

84:                                               ; preds = %72, %56
  %85 = phi i32 [ %77, %72 ], [ %66, %56 ]
  %86 = phi i32 [ %83, %72 ], [ %70, %56 ]
  %87 = lshr i32 %85, 30
  %88 = call i32 @llvm.fshl.i32(i32 %85, i32 %86, i32 2) #5
  %89 = shl i32 %86, 2
  %90 = lshr i32 %88, 31
  %91 = add nuw nsw i32 %90, %87
  %92 = icmp eq i32 %61, 0
  %93 = sub nsw i32 0, %91
  %94 = select i1 %92, i32 %91, i32 %93
  %95 = icmp sgt i32 %88, -1
  %96 = xor i32 %61, -2147483648
  %97 = select i1 %95, i32 %61, i32 %96
  %98 = xor i1 %95, true
  %99 = sext i1 %98 to i32
  %100 = xor i32 %88, %99
  %101 = xor i32 %89, %99
  %102 = zext i32 %100 to i64
  %103 = shl nuw i64 %102, 32
  %104 = zext i32 %101 to i64
  %105 = or i64 %103, %104
  %106 = sitofp i64 %105 to double
  %107 = fmul double %106, 0x3BF921FB54442D19
  %108 = fptrunc double %107 to float
  %109 = icmp eq i32 %97, 0
  %110 = fneg float %108
  %111 = select i1 %109, float %108, float %110
  br label %112

112:                                              ; preds = %24, %37, %84
  %113 = phi i32 [ %28, %24 ], [ %28, %37 ], [ %94, %84 ]
  %114 = phi float [ %32, %24 ], [ %38, %37 ], [ %111, %84 ]
  %115 = fmul float %114, %114
  %116 = and i32 %113, 1
  %117 = icmp eq i32 %116, 0
  %118 = select i1 %117, float %114, float 1.000000e+00
  %119 = call float @llvm.fma.f32(float %115, float %118, float 0.000000e+00) #5
  %120 = call float @llvm.fma.f32(float %115, float 0x3EF9758000000000, float 0xBF56C0FDA0000000) #5
  %121 = select i1 %117, float 0xBF29A82A60000000, float %120
  %122 = select i1 %117, float 0x3F8110BC80000000, float 0x3FA5555760000000
  %123 = call float @llvm.fma.f32(float %121, float %115, float %122) #5
  %124 = select i1 %117, float 0xBFC5555500000000, float 0xBFDFFFFFE0000000
  %125 = call float @llvm.fma.f32(float %123, float %115, float %124) #5
  %126 = call float @llvm.fma.f32(float %125, float %119, float %118) #5
  %127 = and i32 %113, 2
  %128 = icmp eq i32 %127, 0
  %129 = call float @llvm.fma.f32(float %126, float -1.000000e+00, float 0.000000e+00) #5
  %130 = select i1 %128, float %126, float %129
  call void @llvm.lifetime.end.p0i8(i64 28, i8* nonnull %18) #5
  call void @llvm.lifetime.start.p0i8(i64 28, i8* nonnull %20) #5
  br i1 %34, label %131, label %208

131:                                              ; preds = %112
  %132 = fcmp oeq float %33, 0x7FF0000000000000
  br i1 %132, label %133, label %135

133:                                              ; preds = %131
  %134 = fmul float %26, 0.000000e+00
  br label %208

135:                                              ; preds = %131
  %136 = bitcast float %26 to i32
  %137 = lshr i32 %136, 23
  %138 = shl i32 %136, 8
  %139 = or i32 %138, -2147483648
  br label %140

140:                                              ; preds = %140, %135
  %141 = phi i32 [ 0, %135 ], [ %150, %140 ]
  %142 = phi i32 [ 0, %135 ], [ %148, %140 ]
  %143 = zext i32 %141 to i64
  %144 = getelementptr inbounds [6 x i32], [6 x i32] addrspace(1)* @__cudart_i2opi_f, i64 0, i64 %143
  %145 = load i32, i32 addrspace(1)* %144, align 4
  %146 = call { i32, i32 } asm "{\0A\09mad.lo.cc.u32   $0, $2, $3, $4;\0A\09madc.hi.u32     $1, $2, $3,  0;\0A\09}", "=r,=r,r,r,r"(i32 %145, i32 %139, i32 %142) #6, !srcloc !11
  %147 = extractvalue { i32, i32 } %146, 0
  %148 = extractvalue { i32, i32 } %146, 1
  %149 = getelementptr inbounds [7 x i32], [7 x i32]* %4, i64 0, i64 %143
  store i32 %147, i32* %149, align 4
  %150 = add nuw nsw i32 %141, 1
  %151 = icmp eq i32 %150, 6
  br i1 %151, label %152, label %140, !llvm.loop !12

152:                                              ; preds = %140
  %153 = and i32 %137, 255
  %154 = extractvalue { i32, i32 } %146, 1
  %155 = add nsw i32 %153, -128
  %156 = lshr i32 %155, 5
  %157 = and i32 %136, -2147483648
  store i32 %154, i32* %21, align 4
  %158 = and i32 %137, 31
  %159 = sub nsw i32 6, %156
  %160 = sext i32 %159 to i64
  %161 = getelementptr inbounds [7 x i32], [7 x i32]* %4, i64 0, i64 %160
  %162 = load i32, i32* %161, align 4
  %163 = sub nsw i32 5, %156
  %164 = sext i32 %163 to i64
  %165 = getelementptr inbounds [7 x i32], [7 x i32]* %4, i64 0, i64 %164
  %166 = load i32, i32* %165, align 4
  %167 = icmp eq i32 %158, 0
  br i1 %167, label %180, label %168

168:                                              ; preds = %152
  %169 = sub nsw i32 4, %156
  %170 = sub nuw nsw i32 32, %158
  %171 = shl i32 %162, %158
  %172 = lshr i32 %166, %170
  %173 = add i32 %172, %171
  %174 = shl i32 %166, %158
  %175 = sext i32 %169 to i64
  %176 = getelementptr inbounds [7 x i32], [7 x i32]* %4, i64 0, i64 %175
  %177 = load i32, i32* %176, align 4
  %178 = lshr i32 %177, %170
  %179 = add i32 %178, %174
  br label %180

180:                                              ; preds = %168, %152
  %181 = phi i32 [ %173, %168 ], [ %162, %152 ]
  %182 = phi i32 [ %179, %168 ], [ %166, %152 ]
  %183 = lshr i32 %181, 30
  %184 = call i32 @llvm.fshl.i32(i32 %181, i32 %182, i32 2) #5
  %185 = shl i32 %182, 2
  %186 = lshr i32 %184, 31
  %187 = add nuw nsw i32 %186, %183
  %188 = icmp eq i32 %157, 0
  %189 = sub nsw i32 0, %187
  %190 = select i1 %188, i32 %187, i32 %189
  %191 = icmp sgt i32 %184, -1
  %192 = xor i32 %157, -2147483648
  %193 = select i1 %191, i32 %157, i32 %192
  %194 = xor i1 %191, true
  %195 = sext i1 %194 to i32
  %196 = xor i32 %184, %195
  %197 = xor i32 %185, %195
  %198 = zext i32 %196 to i64
  %199 = shl nuw i64 %198, 32
  %200 = zext i32 %197 to i64
  %201 = or i64 %199, %200
  %202 = sitofp i64 %201 to double
  %203 = fmul double %202, 0x3BF921FB54442D19
  %204 = fptrunc double %203 to float
  %205 = icmp eq i32 %193, 0
  %206 = fneg float %204
  %207 = select i1 %205, float %204, float %206
  br label %208

208:                                              ; preds = %112, %133, %180
  %209 = phi i32 [ %28, %112 ], [ %28, %133 ], [ %190, %180 ]
  %210 = phi float [ %32, %112 ], [ %134, %133 ], [ %207, %180 ]
  %211 = add i32 %209, 1
  %212 = fmul float %210, %210
  %213 = and i32 %211, 1
  %214 = icmp eq i32 %213, 0
  %215 = select i1 %214, float %210, float 1.000000e+00
  %216 = call float @llvm.fma.f32(float %212, float %215, float 0.000000e+00) #5
  %217 = call float @llvm.fma.f32(float %212, float 0x3EF9758000000000, float 0xBF56C0FDA0000000) #5
  %218 = select i1 %214, float 0xBF29A82A60000000, float %217
  %219 = select i1 %214, float 0x3F8110BC80000000, float 0x3FA5555760000000
  %220 = call float @llvm.fma.f32(float %218, float %212, float %219) #5
  %221 = select i1 %214, float 0xBFC5555500000000, float 0xBFDFFFFFE0000000
  %222 = call float @llvm.fma.f32(float %220, float %212, float %221) #5
  %223 = call float @llvm.fma.f32(float %222, float %216, float %215) #5
  %224 = and i32 %211, 2
  %225 = icmp eq i32 %224, 0
  %226 = call float @llvm.fma.f32(float %223, float -1.000000e+00, float 0.000000e+00) #5
  %227 = select i1 %225, float %223, float %226
  call void @llvm.lifetime.end.p0i8(i64 28, i8* nonnull %20) #5
  %228 = fadd contract float %130, %227
  %229 = add nuw nsw i32 %25, 1
  %230 = icmp eq i32 %229, 100
  br i1 %230, label %22, label %24, !llvm.loop !14

231:                                              ; preds = %3, %22
  ret void
}

; Function Attrs: nofree nosync nounwind readnone speculatable
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: nofree nosync nounwind readnone speculatable
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #1

; Function Attrs: nofree nosync nounwind readnone speculatable
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

; Function Attrs: mustprogress nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.nvvm.f2i.rn(float) #2

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fma.f32(float, float, float) #3

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare float @llvm.fabs.f32(float) #3

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.fshl.i32(i32, i32, i32) #3

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #4

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #4

attributes #0 = { norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_80" "target-features"="+ptx75,+sm_80" }
attributes #1 = { nofree nosync nounwind readnone speculatable }
attributes #2 = { mustprogress nofree nosync nounwind readnone speculatable willreturn }
attributes #3 = { nofree nosync nounwind readnone speculatable willreturn }
attributes #4 = { argmemonly nofree nosync nounwind willreturn }
attributes #5 = { nounwind }
attributes #6 = { nounwind readnone }

!llvm.module.flags = !{!0, !1, !2, !3}
!nvvm.annotations = !{!4}
!llvm.ident = !{!5, !6}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 11, i32 5]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{void (float*, float, float*)* @_Z12fused_kernelPffS_, !"kernel", i32 1}
!5 = !{!"Ubuntu clang version 14.0.0-1ubuntu1.1"}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = !{!8, !8, i64 0}
!8 = !{!"float", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C++ TBAA"}
!11 = !{i32 29562, i32 29566, i32 29611, i32 29656}
!12 = distinct !{!12, !13}
!13 = !{!"llvm.loop.unroll.count", i32 1}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
