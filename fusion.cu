#include <math.h>

#define N (1<<20)

__global__ void fused_kernel (float* A, float B, float* C) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= N) return;
    
    // Phase 1
    float x = A[i] * 2.0f + B;
    
    // Phase 2
    for (int k = 0; k < 100; k++) {
        x = sinf(x) + cosf(x);
    }
    
    // Phase 3
    C[i] = x;
}

int main() {
    // Boilerplate code here to allocate memory (cudaMalloc), 
    // launch the kernel (fused_kernel<<<...>>>), and free memory.
    return 0;
}