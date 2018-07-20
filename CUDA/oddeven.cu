/**
   Odd-even sort algortihm implemented on CUDA for compilation using mexcuda on MATLAB
   Returns matrix with sorted rows and the corresponding ranks
   Usage:
   [sorted, ranks] = oddeven(A);

   Tested with MATLAB 2018a, TITAN X, GTX 770, and compiled using CUDA 9.0 and MSVC++ 2015
   Must use with a GPU with compute capability 2.0 and above

   Code is provided "as-is", but feel free to direct complaints to author though the latter reserves the right to ignore them

   Written by HaoRan Chang,
   Polaris Brain Dynamics Research Group,
   Canadian Centre for Behavioural Neuroscience,
   University of Lethbridge, AB, Canada

   Version history:
    2018-07-18: precision of input array reduced to 16-bit integer;
                can have 24k elements per block/column;
                ergo input matrix from MATLAB must be of type int16;
 */

#include "mex.h"
#include "gpu/mxGPUArray.h"
#include "matrix.h"

#define bool int
#define true 1
#define false 0

#define short int16_T

#define MAX_BLOCK_SIZE 1024

__global__
void populateIdx(short * const idx, int const m){
        int block_i = blockIdx.x;
        int i;

        for(i = 0; i < m; i++)
                idx[block_i*m + i] = i;
}

__global__
void oddevenSort(short const * const x, bool * const sorted, short * const results, short * const idx, int const * n, int const m, int last){
        int const tot_i = blockIdx.x * blockDim.x + threadIdx.x;
        int const block_i = blockDim.x;
        int const thread_i = threadIdx.x;
        int i;
        short buff;
        bool all_sort = true;

        int m_i = 0;
        for(i = 0; i < thread_i; i++)
                m_i += n[i];

        bool last_thread = last==thread_i;

        extern __shared__ short temp[];

        for(i = 0; i < n[thread_i]; i++)
                temp[m_i + i] = x[blockIdx.x * m + m_i + i];

        __syncthreads();

        while(all_sort) {
                all_sort = false;
                sorted[tot_i] = false;
                // __syncthreads();
                for(i = 0; i < n[thread_i] - (n[thread_i] % 2); i+=2) {
                        if(temp[m_i + i] > temp[m_i + i + 1]) {
                                buff = temp[m_i + i];
                                temp[m_i + i] = temp[m_i + i + 1];
                                temp[m_i + i + 1] = buff;

                                buff = idx[blockIdx.x*m + m_i + i];
                                idx[blockIdx.x*m + m_i + i] = idx[blockIdx.x*m + m_i + i + 1];
                                idx[blockIdx.x*m + m_i + i + 1] = buff;

                                sorted[tot_i] = true;
                        }
                }
                __syncthreads();

                for(i = 1; i < n[thread_i] - last_thread; i+=2) {
                        if(temp[m_i + i] > temp[m_i + i + 1]) {
                                buff = temp[m_i + i];
                                temp[m_i + i] = temp[m_i + i + 1];
                                temp[m_i + i + 1] = buff;

                                buff = idx[blockIdx.x*m + m_i + i];
                                idx[blockIdx.x*m + m_i + i] = idx[blockIdx.x*m + m_i + i + 1];
                                idx[blockIdx.x*m + m_i + i + 1] = buff;

                                sorted[tot_i] = true;
                        }
                }
                __syncthreads();

                for(i = 0; i < block_i; i++)
                        all_sort += sorted[blockIdx.x * blockDim.x + i];
        }

        for(i = 0; i < n[thread_i]; i++)
                results[blockIdx.x * m + m_i + i] = temp[m_i + i];
}

__global__
void getRanks(short * const results, short * const idx, float * const ranks, int const m){
        int block_i = blockIdx.x + 1;

        int i, buff;
        float count = 0.0f;
        do {
                i = (int) count;
                buff = (int) count;
                while(results[block_i*m - buff - 1] == results[block_i*m - buff - 2])
                        buff++;
                do {
                        ranks[(block_i-1)*m + idx[block_i*m - i - 1]] = (buff - count) / 2.0f + count + 1.0f;
                        i++;
                } while(i <= buff);
                count = buff + 1.0f;
        } while(count < m);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
        if(nrhs != 1)
                mexErrMsgTxt("There needs to be only one input you dummy -_-\"");

        short const *x;
        short *results, *idx;
        float *ranks;
        bool *sorted;
        mxGPUArray const *x_pr, *el_gpu_pr;
        mxGPUArray *sort, *res, *ranks_pr, *idx_pr;
        mxArray *el_pr;
        mwSize const *dims;
        mwSize dimensions[2];
        int i, last;
        int const *el_per_thread_gpu;

        int BLOCK_SIZE;

        mxInitGPU();

        x_pr = mxGPUCreateFromMxArray(prhs[0]);
        x = (short const *) (mxGPUGetDataReadOnly(x_pr));

        dims = mxGPUGetDimensions(x_pr);
        int const m = dims[0];
        int const n = dims[1];

        el_pr = mxCreateNumericMatrix(MAX_BLOCK_SIZE, 1, mxINT32_CLASS, mxREAL);
        int *el_per_thread = (int *) mxGetData(el_pr);
        for(i = 0; i < m - 1; i += 2)
                el_per_thread[i/2 % MAX_BLOCK_SIZE] += 2;
        if(m/MAX_BLOCK_SIZE > 0) {
                el_per_thread[MAX_BLOCK_SIZE - 1] += m%2;
                last = MAX_BLOCK_SIZE - 1;
                BLOCK_SIZE = MAX_BLOCK_SIZE;
        }else{
                el_per_thread[m/2 - 1] += m%2;
                last = m/2 - 1;
                BLOCK_SIZE = m/2 + m%2;
        }
        el_gpu_pr = mxGPUCreateFromMxArray(el_pr);
        el_per_thread_gpu = (int const *) mxGPUGetDataReadOnly(el_gpu_pr);

        res = mxGPUCreateGPUArray(mxGPUGetNumberOfDimensions(x_pr), dims,
                                  mxINT16_CLASS, mxGPUGetComplexity(x_pr),
                                  MX_GPU_DO_NOT_INITIALIZE);

        ranks_pr = mxGPUCreateGPUArray(mxGPUGetNumberOfDimensions(x_pr), dims,
                                       mxSINGLE_CLASS, mxGPUGetComplexity(x_pr),
                                       MX_GPU_DO_NOT_INITIALIZE);

        idx_pr = mxGPUCreateGPUArray(mxGPUGetNumberOfDimensions(x_pr), dims,
                                     mxINT16_CLASS, mxGPUGetComplexity(x_pr),
                                     MX_GPU_DO_NOT_INITIALIZE);
        idx = (short *) mxGPUGetData(idx_pr);

        populateIdx<<<n, 1>>>(idx, m);

        dimensions[0] = BLOCK_SIZE;
        dimensions[1] = n;
        sort = mxGPUCreateGPUArray(mxGPUGetNumberOfDimensions(x_pr), dimensions,
                                   mxINT32_CLASS, mxREAL,
                                   MX_GPU_DO_NOT_INITIALIZE);

        results = (short *) (mxGPUGetData(res));
        ranks = (float *) (mxGPUGetData(ranks_pr));
        sorted = (bool *) (mxGPUGetData(sort));

        oddevenSort<<<n, BLOCK_SIZE, m*sizeof(short)>>>(x, sorted, results, idx, el_per_thread_gpu, m, last);

        getRanks<<<n, 1>>>(results, idx, ranks, m);

        plhs[0] = mxGPUCreateMxArrayOnGPU(res);
        plhs[1] = mxGPUCreateMxArrayOnGPU(idx_pr);
        plhs[2] = mxGPUCreateMxArrayOnGPU(ranks_pr);

        mxGPUDestroyGPUArray(x_pr);
        mxGPUDestroyGPUArray(res);
        mxGPUDestroyGPUArray(sort);
        mxGPUDestroyGPUArray(el_gpu_pr);
        mxGPUDestroyGPUArray(idx_pr);
        mxGPUDestroyGPUArray(ranks_pr);
        mxDestroyArray(el_pr);

        return;
}
