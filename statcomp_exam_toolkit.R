# =====================================================================
# statcomp_exam_toolkit.R
# 统计计算开卷考试 — 工具函数库（7 类 · 23 函数）
#
# 用法：
#   source("statcomp_exam_toolkit.R")
# 然后即可直接调用下述函数，所有函数均支持 seed 参数以便复现。
#
# 接口约定：
#   - MC 类函数返回 c(est, se, var_est)
#   - Bootstrap 类函数返回 c(theta_hat, se, bias) 或矩阵
#   - MCMC 类函数返回 list(chain, reject_rate)
#     注：接受率 = 1 - reject_rate
# =====================================================================


# ============================================================
# 0. 小工具：mc_se / vrp / summ / print_result
# ============================================================

# Monte Carlo 标准误：sd(x) / sqrt(n)
mc_se <- function(x) sd(x) / sqrt(length(x))

# 方差缩减率：(var_simple - var_new) / var_simple，越接近 1 越好
vrp <- function(var_simple, var_new) (var_simple - var_new) / var_simple

# 一键输出 mean / var / sd / se
summ <- function(x) c(mean = mean(x), var = var(x), sd = sd(x), se = mc_se(x))

print_result <- function(name, value) {
  cat("\n---", name, "---\n"); print(value)
}


# ============================================================
# 1. 随机变量生成
# ============================================================

# 1.1 逆变换法：给定反函数 F^{-1}(u)，生成样本
inv_sample <- function(n, qfun, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  u <- runif(n)
  qfun(u)
}
# 例：Pareto F(x) = 1 - (2/x)^2，x >= 2  ->  x = 2 / sqrt(1 - u)
# inv_sample(5000, function(u) 2 / sqrt(1 - u), seed = 12)

# 1.2 离散逆变换
discrete_inv_sample <- function(n, values, probs, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  u <- runif(n)
  values[findInterval(u, c(0, cumsum(probs)), rightmost.closed = TRUE)]
}
# discrete_inv_sample(1000, c(1, 2, 3), c(.2, .5, .3))

# 1.3 接受拒绝法：返回 list(sample, accept_rate, iter)
accept_reject <- function(n, rproposal, dtarget_over_cproposal, seed = NULL,
                          max_iter = 1e7) {
  if (!is.null(seed)) set.seed(seed)
  x <- numeric(n); k <- 0; iter <- 0
  while (k < n && iter < max_iter) {
    iter <- iter + 1
    y <- rproposal(1); u <- runif(1)
    if (u <= dtarget_over_cproposal(y)) { k <- k + 1; x[k] <- y }
  }
  list(sample = x, accept_rate = n / iter, iter = iter)
}
# 例：f(x) ∝ x(1-x)，0<x<1；4*y*(1-y) 即接受概率
# accept_reject(5000, function(n) runif(n), function(y) 4 * y * (1 - y))

# 1.4 多元正态（Cholesky）
rmvnorm_chol <- function(n, mu, Sigma, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  p <- length(mu)
  z <- matrix(rnorm(n * p), nrow = n)
  L <- chol(Sigma)
  sweep(z %*% L, 2, mu, "+")
}

# 1.5 两正态混合
rnorm_mixture <- function(n, p, mu1, sd1, mu2, sd2, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  z <- rbinom(n, size = 1, prob = p)
  ifelse(z == 1, rnorm(n, mu1, sd1), rnorm(n, mu2, sd2))
}


# ============================================================
# 2. MC 积分与方差缩减
# ============================================================

# 2.1 简单 MC（[0,1]）
mc_integrate_unit <- function(g, n = 10000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  u <- runif(n); vals <- g(u)
  c(est = mean(vals), se = mc_se(vals), var_est = var(vals) / n)
}

# 2.2 简单 MC（[a,b]）
mc_integrate_ab <- function(g, a, b, n = 10000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  u <- runif(n, a, b); vals <- (b - a) * g(u)
  c(est = mean(vals), se = mc_se(vals), var_est = var(vals) / n)
}

# 2.3 对偶变量法 antithetic
mc_antithetic_unit <- function(g, n = 10000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  n2 <- floor(n / 2); u <- runif(n2)
  vals <- (g(u) + g(1 - u)) / 2
  c(est = mean(vals), se = mc_se(vals), var_est = var(vals) / n2)
}

# 2.4 控制变量法 control variate
#   θ̂ = mean(g(X) + c* (h(X) - E[h]))，c* = -Cov(g, h) / Var(h)
mc_control_variate <- function(g, h, eh, n = 10000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  u <- runif(n); gx <- g(u); hx <- h(u)
  cstar <- -cov(gx, hx) / var(hx)
  vals  <- gx + cstar * (hx - eh)
  c(est = mean(vals), se = mc_se(vals), var_est = var(vals) / n, cstar = cstar)
}

# 2.5 重要抽样 importance sampling
mc_importance <- function(g, rsamp, dsamp, n = 10000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- rsamp(n); vals <- g(x) / dsamp(x)
  c(est = mean(vals), se = mc_se(vals), var_est = var(vals) / n)
}

# 2.6 分层抽样 stratified
mc_stratified_unit <- function(g, m = 100, r = 100, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  vals <- numeric(m * r); k <- 0
  for (j in 1:m) {
    u <- ((j - 1) + runif(r)) / m
    vals[(k + 1):(k + r)] <- g(u); k <- k + r
  }
  c(est = mean(vals), se = mc_se(vals), var_est = var(vals) / length(vals))
}


# ============================================================
# 3. MC 统计推断（I 类错误与功效）
# ============================================================

# 通用拒绝率模拟器：传入数据生成函数和拒绝判定函数
simulate_rejection_rate <- function(rdata, reject, nsim = 1000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  mean(replicate(nsim, reject(rdata())))
}

# σ 已知 → Z 检验
normal_mean_reject_z <- function(x, mu0 = 0, sigma = 1, alpha = 0.05) {
  n <- length(x); z <- sqrt(n) * (mean(x) - mu0) / sigma
  abs(z) > qnorm(1 - alpha / 2)
}

# σ 未知 → t 检验
normal_mean_reject_t <- function(x, mu0 = 0, alpha = 0.05) {
  n <- length(x); tval <- sqrt(n) * (mean(x) - mu0) / sd(x)
  abs(tval) > qt(1 - alpha / 2, df = n - 1)
}

# 功效曲线（Z vs t）
power_curve_normal_mean <- function(mu_grid, n = 200, sigma = 1, alpha = 0.05,
                                    nsim = 1000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  out <- matrix(NA_real_, nrow = length(mu_grid), ncol = 2)
  colnames(out) <- c("z_known_sigma", "t_unknown_sigma")
  rownames(out) <- paste0("mu=", mu_grid)
  for (j in seq_along(mu_grid)) {
    mu <- mu_grid[j]
    out[j, 1] <- mean(replicate(nsim, {
      x <- rnorm(n, mu, sigma)
      normal_mean_reject_z(x, mu0 = 0, sigma = sigma, alpha = alpha)
    }))
    out[j, 2] <- mean(replicate(nsim, {
      x <- rnorm(n, mu, sigma)
      normal_mean_reject_t(x, mu0 = 0, alpha = alpha)
    }))
  }
  out
}


# ============================================================
# 4. Bootstrap & Jackknife
# ============================================================

# 核心：B 次有放回抽样
bootstrap_reps <- function(x, stat, B = 2000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- as.matrix(x); n <- nrow(x)
  replicate(B, {
    ind <- sample.int(n, size = n, replace = TRUE)
    stat(x[ind, , drop = FALSE])
  })
}

# 标准误 + 偏差
bootstrap_se_bias <- function(x, stat, B = 2000, seed = NULL) {
  theta0 <- stat(as.matrix(x))
  reps   <- bootstrap_reps(x, stat, B, seed)
  c(theta_hat = theta0, se = sd(reps), bias = mean(reps) - theta0)
}

# 三种手写 CI：normal / basic / percentile
bootstrap_ci_manual <- function(x, stat, B = 2000, conf = 0.95, seed = NULL) {
  theta0 <- stat(as.matrix(x))
  reps   <- bootstrap_reps(x, stat, B, seed)
  alpha  <- 1 - conf; z <- qnorm(1 - alpha / 2); se <- sd(reps)
  q <- as.numeric(quantile(reps, c(alpha / 2, 1 - alpha / 2), type = 1))
  rbind(
    normal     = c(lower = theta0 - z * se,   upper = theta0 + z * se),
    basic      = c(lower = 2 * theta0 - q[2], upper = 2 * theta0 - q[1]),
    percentile = c(lower = q[1],              upper = q[2])
  )
}

# Bootstrap-t（嵌套）
bootstrap_t_ci <- function(x, stat, B = 500, R = 100, conf = 0.95, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- as.matrix(x); n <- nrow(x); theta0 <- stat(x)
  stat_b <- se_b <- numeric(B)
  boot_se <- function(z) sd(bootstrap_reps(z, stat, R))
  for (b in 1:B) {
    ind <- sample.int(n, size = n, replace = TRUE)
    xb  <- x[ind, , drop = FALSE]
    stat_b[b] <- stat(xb); se_b[b] <- boot_se(xb)
  }
  se0   <- sd(stat_b)
  tstat <- (stat_b - theta0) / se_b
  alpha <- 1 - conf
  q <- as.numeric(quantile(tstat, c(alpha / 2, 1 - alpha / 2), type = 1))
  c(lower = theta0 - q[2] * se0, upper = theta0 - q[1] * se0)
}

# Jackknife（留一法）
jackknife_se_bias <- function(x, stat) {
  x <- as.matrix(x); n <- nrow(x); theta0 <- stat(x)
  theta_j <- numeric(n)
  for (i in 1:n) theta_j[i] <- stat(x[-i, , drop = FALSE])
  theta_bar <- mean(theta_j)
  bias <- (n - 1) * (theta_bar - theta0)
  se   <- sqrt((n - 1) * mean((theta_j - theta_bar)^2))
  c(theta_hat = theta0, se = se, bias = bias)
}
# 例：Exp(λ) MLE λ̂ = 1 / mean(x)
# stat_lambda <- function(z) 1 / mean(z[, 1])
# bootstrap_se_bias(time, stat_lambda, B = 2000, seed = 12)


# ============================================================
# 5. MCMC：独立 MH / 随机游走 MH / 链诊断
# ============================================================

# 独立建议分布 MH
# 接受率 alpha = min(1, pi(y) * q(x_old) / (pi(x_old) * q(y)))
# 返回 reject_rate；接受率 = 1 - reject_rate
mh_independence <- function(n, target, rprop, dprop, x0, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- numeric(n); x[1] <- x0; reject <- 0
  for (i in 2:n) {
    y <- rprop(1)
    ratio <- target(y) * dprop(x[i - 1]) / (target(x[i - 1]) * dprop(y))
    if (runif(1) <= min(1, ratio)) x[i] <- y
    else                         { x[i] <- x[i - 1]; reject <- reject + 1 }
  }
  list(chain = x, reject_rate = reject / (n - 1))
}

# 随机游走 MH（对称提议，q 自抵消）
# 经验法则：随机游走链接受率以 20%–50% 为佳；独立 MH 与 Gibbs 不适用此区间
mh_random_walk <- function(n, target, x0, proposal_sd = 1, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- numeric(n); x[1] <- x0; reject <- 0
  for (i in 2:n) {
    y <- rnorm(1, mean = x[i - 1], sd = proposal_sd)
    ratio <- target(y) / target(x[i - 1])
    if (runif(1) <= min(1, ratio)) x[i] <- y
    else                         { x[i] <- x[i - 1]; reject <- reject + 1 }
  }
  list(chain = x, reject_rate = reject / (n - 1))
}

# 链诊断：去 burn-in 后输出均值、标准差、分位数
chain_check <- function(chain, burn = floor(length(chain) / 2),
                        probs = c(.1, .25, .5, .75, .9)) {
  y <- chain[(burn + 1):length(chain)]
  list(mean = mean(y), sd = sd(y), quantile = quantile(y, probs))
}
# 例：Cauchy 目标 + t_2 建议分布
# target <- function(x) 1 / (pi * (1 + x^2))
# ans <- mh_independence(50000, target, function(n) rt(n, 2),
#                        function(x) dt(x, 2), x0 = rt(1, 2), seed = 12)


# ============================================================
# 6. 数值求根
# ============================================================

# 二分法（要求 f(a) * f(b) < 0）
bisection_solve <- function(f, lower, upper, tol = 1e-8, max_iter = 1000) {
  fl <- f(lower); fu <- f(upper)
  if (fl * fu > 0) stop("f(lower) and f(upper) must have opposite signs")
  for (it in 1:max_iter) {
    mid <- (lower + upper) / 2; fm <- f(mid)
    if (abs(fm) < tol || (upper - lower) / 2 < tol)
      return(list(root = mid, value = fm, iter = it))
    if (fl * fm <= 0) { upper <- mid; fu <- fm }
    else              { lower <- mid; fl <- fm }
  }
  list(root = (lower + upper) / 2, value = f((lower + upper) / 2), iter = max_iter)
}

# Newton-Raphson
newton_solve <- function(f, fp, x0, tol = 1e-8, max_iter = 1000, trace = FALSE) {
  x_old <- x0
  for (it in 1:max_iter) {
    x_new <- x_old - f(x_old) / fp(x_old)
    if (trace) cat(it, x_old, x_new, abs(x_new - x_old), "\n")
    if (abs(x_new - x_old) < tol)
      return(list(root = x_new, value = f(x_new), iter = it))
    x_old <- x_new
  }
  list(root = x_old, value = f(x_old), iter = max_iter)
}
# 例：Exp(λ) MLE
# f  <- function(lambda) length(time) / lambda - sum(time)
# fp <- function(lambda) -length(time) / lambda^2
# newton_solve(f, fp, x0 = 6, trace = TRUE)


# ============================================================
# 7. EM 算法：em_norm2（两正态混合）
# ============================================================

em_norm2 <- function(x, p = 0.5, mu1 = quantile(x, .25), mu2 = quantile(x, .75),
                     sd1 = sd(x), sd2 = sd(x), tol = 1e-8, max_iter = 1000) {
  loglik_old <- -Inf
  for (it in 1:max_iter) {
    # E 步
    dens1 <- p * dnorm(x, mu1, sd1)
    dens2 <- (1 - p) * dnorm(x, mu2, sd2)
    w <- dens1 / (dens1 + dens2)
    # M 步
    p   <- mean(w)
    mu1 <- sum(w * x) / sum(w)
    mu2 <- sum((1 - w) * x) / sum(1 - w)
    sd1 <- sqrt(sum(w * (x - mu1)^2) / sum(w))
    sd2 <- sqrt(sum((1 - w) * (x - mu2)^2) / sum(1 - w))
    loglik <- sum(log(p * dnorm(x, mu1, sd1) + (1 - p) * dnorm(x, mu2, sd2)))
    if (abs(loglik - loglik_old) < tol) break
    loglik_old <- loglik
  }
  list(p = p, mu1 = mu1, mu2 = mu2, sd1 = sd1, sd2 = sd2,
       loglik = loglik, iter = it)
}
# 初值默认取 25% / 75% 分位数；数据强双峰时手工指定 mu1, mu2 可加速收敛。
