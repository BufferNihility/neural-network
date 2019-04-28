#include <softmax.cuh>

__global__ void operator_log_softmax_h(const float *input1, float *output,
                                       unsigned int *input1_shape,
                                       unsigned int input1_dims,
                                       unsigned int *temp_shape_ptr,
                                       unsigned int dim, unsigned int dim_stride,
                                       unsigned int size) {
  unsigned int index = blockIdx.x * blockDim.x + threadIdx.x;

  if (index < size) {
    unsigned int length = input1_shape[dim];

    unsigned int *loc = new unsigned int[input1_dims];
    index2loc(index, temp_shape_ptr, input1_dims - 1, loc);
    for (unsigned int i = input1_dims - 1; i > dim; i--) {
      loc[i] = loc[i - 1];
    }
    loc[dim] = 0;
    unsigned int base = loc2index(loc, input1_shape, input1_dims);
    delete[] loc;

    float max_ = -FLT_MIN;
    for (unsigned int i = 0; i < length; ++i) {
      max_ = fmaxf(max_, input1[base + i * dim_stride]);
    }

    double logsum = 0;
    for (unsigned int i = 0; i < length; ++i) {
      logsum += expf(input1[base + i * dim_stride] - max_);
    }
    logsum = max_ + logf(logsum);

    for (unsigned int i = 0; i < length; ++i) {
      output[base + i * dim_stride] = input1[base + i * dim_stride] - logsum;
    }
  }
}

Storage *operator_log_softmax(const Storage *input1, unsigned int dim) {
  const float *input1_ptr = thrust::raw_pointer_cast(input1->data.data());
  const unsigned int *input1_shape_ptr =
      thrust::raw_pointer_cast(input1->shape.data());
  Storage *output = new Storage(input1->shape);
  float *output_ptr = thrust::raw_pointer_cast(output->data.data());

  thrust::device_vector<unsigned int> temp_shape(input1->shape);
  temp_shape.erase(temp_shape.begin() + dim);
  unsigned int *temp_shape_ptr = thrust::raw_pointer_cast(temp_shape.data());

  unsigned int input1_dims = input1->shape.size();
  unsigned int dim_stride = 1;
  for (unsigned int i = dim + 1; i < input1_dims; i++) {
    dim_stride *= input1_shape_ptr[i];
  }

  unsigned int size = input1->data.size() / input1->shape[dim];
  unsigned int grid_size = ceil((float)(size) / BLOCK_SIZE);
  operator_log_softmax_h<<<grid_size, BLOCK_SIZE>>>(
      input1_ptr, output_ptr, input1_shape_ptr, input1_dims, temp_shape_ptr,
      dim dim_stride, size);
}

// Y = log_softmax(X) = x - log(exp(X) * 1_n) * 1_n^T
// dL/dX = dL/dY - (dL/dY * 1_n * exp(x)) / (exp(x) * 1_n)
Storage *operator_d_log_softmax(const Storage *input1, unsigned int dim,
                                const Storage *output_grads) {
  
}