#include <memory>
#include <nll_loss.cuh>
 
// L = mean(sum(-log_P element_mul Y, 1), 0)
Storage *operator_nll_loss(const Storage *log_p, const Storage *y) {
  std::unique_ptr<Storage> nll_loss_batch(operator_mul(log_p, y));
  std::unique_ptr<Storage> nll_loss_sum(operator_sum(nll_loss_batch.get(), 1));
  return operator_mean(nll_loss_sum.get(), 0);
}

// L = 1_n^T * ((-log_P element_mul Y) * 1_k) / N
// dL/d(log_P) = -Y / N
Storage *operator_d_nll_loss(const Storage *y) {
  unsigned int batch_size = *y->shape.begin();
  return operator_mul(y, (float)-1 / batch_size);
}