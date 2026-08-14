# R script to generate and save all vector figures for LaTeX/Overleaf
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(scales)
  library(xts)
  library(zoo)
  library(PerformanceAnalytics)
  library(quadprog)
  library(MASS)
  library(corrplot)
})

project_root <- getwd()
data_path <- file.path(project_root, "data", "master_dataset.csv")
fig_dir1 <- file.path(project_root, "reports", "figures")
fig_dir2 <- file.path(project_root, "overleaf_project", "figures")
dir.create(fig_dir1, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir2, recursive = TRUE, showWarnings = FALSE)

raw_data <- read_csv(data_path, show_col_types = FALSE) %>%
  mutate(Date = as.Date(Date)) %>%
  filter(Date >= as.Date("2020-01-02") & Date <= as.Date("2025-12-31")) %>%
  arrange(Date)

asset_cols <- c("TEL", "MER", "AEV", "NVDA", "META", "BTC", "SPY")
portfolio_assets <- c("TEL", "MER", "AEV", "NVDA", "META", "BTC")

prices_mat <- as.matrix(raw_data[, asset_cols])
prices_xts <- xts(prices_mat, order.by = raw_data[["Date"]])
prices_carried <- na.locf(prices_xts)

returns_xts_carried <- Return.calculate(prices_carried, method = "log")[-1, ]
ret_smp <- exp(returns_xts_carried) - 1
asset_returns_smp <- ret_smp[, portfolio_assets]
rf_annual <- mean(raw_data[["RF_Rate"]], na.rm = TRUE)

qvrs_colors <- c(
  "TEL"  = "#1F2E7A", "MER"  = "#2E45B8", "AEV"  = "#475ED1",
  "NVDA" = "#1DC9A4", "META" = "#F97A1F", "BTC"  = "#E3120B", "SPY"  = "#595959"
)

theme_quant <- function() {
  theme_minimal() +
    theme(
      text = element_text(color = "#0D0D0D"),
      plot.title = element_text(face = "bold", size = 12, margin = margin(b = 4)),
      plot.subtitle = element_text(size = 9.5, color = "#333333", margin = margin(b = 8)),
      plot.caption = element_text(size = 8, color = "#595959", hjust = 0, margin = margin(t = 6)),
      axis.title = element_text(size = 9, face = "bold", color = "#1A1A1A"),
      axis.text = element_text(size = 8, color = "#333333"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#F2F2F2", linewidth = 0.3),
      legend.position = "bottom",
      legend.title = element_blank(),
      axis.ticks = element_blank(),
      strip.background = element_rect(fill = "#EBEDFA", color = NA),
      strip.text = element_text(face = "bold", size = 9, color = "#141F52")
    )
}

save_fig <- function(p, filename) {
  ggsave(file.path(fig_dir1, filename), plot = p, width = 8, height = 5, device = cairo_pdf)
  ggsave(file.path(fig_dir2, filename), plot = p, width = 8, height = 5, device = cairo_pdf)
}

# 1. Price History
prices_norm_df <- as.data.frame(prices_carried) %>%
  rownames_to_column(var = "Date") %>%
  mutate(Date = as.Date(Date)) %>%
  pivot_longer(-Date, names_to = "Asset", values_to = "Price") %>%
  group_by(Asset) %>%
  mutate(Normalized_Price = (Price / first(Price)) * 100) %>%
  ungroup() %>%
  mutate(Asset = factor(Asset, levels = names(qvrs_colors)))

p1 <- ggplot(prices_norm_df, aes(x = Date, y = Normalized_Price, color = Asset)) +
  geom_line(linewidth = 0.75, alpha = 0.9) +
  scale_color_manual(values = qvrs_colors) +
  scale_y_log10(labels = label_comma(prefix = "$")) +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  labs(title = "Historical Normalized Price Trajectories (Log Scale)", subtitle = "Base = 100 on January 2, 2020 through December 31, 2025", x = NULL, y = "Normalized Index (Jan 2020 = 100)") +
  theme_quant()
save_fig(p1, "fig-price-history-1.pdf")

# 2. Portfolio Optimization
mu_ann <- colMeans(asset_returns_smp, na.rm = TRUE) * 252
Sigma_ann <- cov(asset_returns_smp, use = "pairwise.complete.obs") * 252
n_a <- length(mu_ann); asset_names <- names(mu_ann); w0 <- rep(1/n_a, n_a)

eval_f_v <- function(w) as.numeric(t(w) %*% Sigma_ann %*% w)
eval_g_v <- function(w) finite_grad(w, eval_f_v)
finite_grad <- function(w, func) {
  eps <- 1e-6
  g <- numeric(length(w))
  for (i in seq_along(w)) {
    w1 <- w; w1[i] <- w1[i] + eps
    w2 <- w; w2[i] <- w2[i] - eps
    g[i] <- (func(w1) - func(w2)) / (2 * eps)
  }
  g
}

# QP Solver for GMV and Sharpe
D <- 2 * Sigma_ann + diag(1e-6, n_a)
d <- rep(0, n_a)
Amat_gmv <- cbind(rep(1, n_a), diag(n_a))
bvec_gmv <- c(1, rep(0, n_a))
sol_gmv <- solve.QP(Dmat = D, dvec = d, Amat = Amat_gmv, bvec = bvec_gmv, meq = 1)
w_gmv <- sol_gmv$solution; names(w_gmv) <- asset_names

# Max Sharpe via grid sweep over frontier
target_returns <- seq(min(mu_ann), max(mu_ann), length.out = 100)
best_sharpe <- -Inf
w_sharpe <- w0

for (target in target_returns) {
  Amat <- cbind(rep(1, n_a), mu_ann, diag(n_a))
  bvec <- c(1, target, rep(0, n_a))
  sol <- tryCatch(solve.QP(Dmat = D, dvec = d, Amat = Amat, bvec = bvec, meq = 2), error = function(e) NULL)
  if (!is.null(sol)) {
    w_i <- sol$solution
    r_i <- sum(w_i * mu_ann)
    s_i <- sqrt(as.numeric(t(w_i) %*% Sigma_ann %*% w_i))
    sh_i <- (r_i - rf_annual) / s_i
    if (sh_i > best_sharpe) {
      best_sharpe <- sh_i
      w_sharpe <- w_i
    }
  }
}
names(w_sharpe) <- asset_names

gmv_ret <- sum(w_gmv * mu_ann); gmv_sd <- sqrt(as.numeric(t(w_gmv) %*% Sigma_ann %*% w_gmv))
sharpe_ret <- sum(w_sharpe * mu_ann); sharpe_sd <- sqrt(as.numeric(t(w_sharpe) %*% Sigma_ann %*% w_sharpe))

# Efficient Frontier Plot
frontier_list <- list()
for (i in seq_along(target_returns)) {
  target <- target_returns[i]
  Amat <- cbind(rep(1, n_a), mu_ann, diag(n_a))
  bvec <- c(1, target, rep(0, n_a))
  sol <- tryCatch(solve.QP(Dmat = D, dvec = d, Amat = Amat, bvec = bvec, meq = 2), error = function(e) NULL)
  if (!is.null(sol)) {
    w_i <- sol$solution
    frontier_list[[i]] <- data.frame(Target = target, Risk = sqrt(as.numeric(t(w_i) %*% Sigma_ann %*% w_i)), Return = sum(w_i * mu_ann))
  }
}
ef_df <- bind_rows(frontier_list) %>% filter(Return >= gmv_ret)

p2 <- ggplot(ef_df, aes(x = Risk, y = Return)) +
  geom_path(color = "#1F2E7A", linewidth = 0.9) +
  geom_point(data = data.frame(Risk = gmv_sd, Return = gmv_ret), aes(x = Risk, y = Return), color = "#E3120B", size = 3) +
  geom_point(data = data.frame(Risk = sharpe_sd, Return = sharpe_ret), aes(x = Risk, y = Return), color = "#1DC9A4", size = 3) +
  scale_x_continuous(labels = label_percent(accuracy = 1)) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(title = "Efficient Frontier: Risk-Return Tradeoff", subtitle = "Red = GMV | Teal = Maximum Sharpe Ratio", x = "Annualized Volatility (Risk)", y = "Annualized Expected Return") +
  theme_quant()
save_fig(p2, "fig-efficient-frontier-1.pdf")

# Allocation Bar Plot
weights_long_df <- data.frame(Asset = rep(asset_names, 2), Portfolio = rep(c("GMV", "Max Sharpe"), each = n_a), Weight = c(w_gmv, w_sharpe))
p3 <- ggplot(weights_long_df, aes(x = Asset, y = Weight, fill = Asset)) +
  geom_col() + facet_wrap(~ Portfolio) +
  scale_fill_manual(values = qvrs_colors) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(title = "Optimal Portfolio Allocation by Asset", subtitle = "Comparison between GMV and Maximum Sharpe portfolios", x = NULL, y = "Portfolio Weight") +
  theme_quant() + theme(legend.position = "none")
save_fig(p3, "fig-portfolio-allocation-1.pdf")

# Monte Carlo Distribution Plot
set.seed(123)
sim_returns <- mvrnorm(n = 10000, mu = mu_ann/252, Sigma = Sigma_ann/252)
colnames(sim_returns) <- asset_names
sim_shp <- as.numeric(sim_returns %*% w_sharpe)
port_ret_shp <- Return.portfolio(R = asset_returns_smp, weights = w_sharpe, rebalance_on = "months")

dist_df <- bind_rows(
  data.frame(Return = as.numeric(port_ret_shp), Source = "Historical"),
  data.frame(Return = sim_shp, Source = "Monte Carlo")
)

p4 <- ggplot(dist_df, aes(x = Return, fill = Source, color = Source)) +
  geom_density(alpha = 0.35, linewidth = 0.7) +
  scale_fill_manual(values = c("Historical" = "#1F2E7A", "Monte Carlo" = "#E3120B")) +
  scale_color_manual(values = c("Historical" = "#1F2E7A", "Monte Carlo" = "#E3120B")) +
  scale_x_continuous(labels = label_percent(accuracy = 1)) +
  labs(title = "Historical vs Monte Carlo Simulated Return Distribution", subtitle = "Max Sharpe Portfolio: comparing observed daily returns to 10,000 simulated draws", x = "Daily Portfolio Return", y = "Density") +
  theme_quant()
save_fig(p4, "fig-mc-distribution-1.pdf")

# Stress Test Plot
calc_w_shock <- function(date_range) {
  w_ret <- ret_smp[date_range]
  sapply(w_ret, function(col) prod(1 + col, na.rm = TRUE) - 1)
}
sh_covid  <- calc_w_shock("2020-02-19/2020-03-23")
sh_tech   <- calc_w_shock("2021-11-19/2022-01-27")
sh_crypto <- calc_w_shock("2022-05-05/2022-05-13")
sh_fed    <- calc_w_shock("2022-06-08/2022-06-16")
worst_obs <- pmin(sh_covid, sh_crypto, sh_fed, sh_tech)
sh_bswan  <- worst_obs * 1.5

stress_df <- tibble(
  Scenario = c("2020 COVID Crash", "2022 Crypto Winter", "Fed Rate Hike Shock", "Tech Sector Selloff", "Hypothetical Black Swan"),
  TEL = c(sh_covid["TEL"], sh_crypto["TEL"], sh_fed["TEL"], sh_tech["TEL"], sh_bswan["TEL"]),
  MER = c(sh_covid["MER"], sh_crypto["MER"], sh_fed["MER"], sh_tech["MER"], sh_bswan["MER"]),
  AEV = c(sh_covid["AEV"], sh_crypto["AEV"], sh_fed["AEV"], sh_tech["AEV"], sh_bswan["AEV"]),
  NVDA = c(sh_covid["NVDA"], sh_crypto["NVDA"], sh_fed["NVDA"], sh_tech["NVDA"], sh_bswan["NVDA"]),
  META = c(sh_covid["META"], sh_crypto["META"], sh_fed["META"], sh_tech["META"], sh_bswan["META"]),
  BTC = c(sh_covid["BTC"], sh_crypto["BTC"], sh_fed["BTC"], sh_tech["BTC"], sh_bswan["BTC"])
) %>% rowwise() %>% mutate(
  GMV_Impact = sum(c(TEL,MER,AEV,NVDA,META,BTC) * w_gmv[c("TEL","MER","AEV","NVDA","META","BTC")]),
  MaxSharpe_Impact = sum(c(TEL,MER,AEV,NVDA,META,BTC) * w_sharpe[c("TEL","MER","AEV","NVDA","META","BTC")])
) %>% ungroup() %>% dplyr::select(Scenario, GMV_Impact, MaxSharpe_Impact)

stress_long <- stress_df %>%
  pivot_longer(cols = c(GMV_Impact, MaxSharpe_Impact), names_to = "Portfolio", values_to = "Impact") %>%
  mutate(Portfolio = ifelse(Portfolio == "GMV_Impact", "GMV", "Max Sharpe"))

p5 <- ggplot(stress_long, aes(x = reorder(Scenario, Impact), y = Impact, fill = Portfolio)) +
  geom_col(position = "dodge") + coord_flip() +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  scale_fill_manual(values = c("GMV" = "#1F2E7A", "Max Sharpe" = "#E3120B")) +
  labs(title = "Portfolio Impact Under Stress Scenarios", subtitle = "Simulated instantaneous shock to portfolio value", x = NULL, y = "Portfolio Return Impact") +
  theme_quant()
save_fig(p5, "fig-stress-test-1.pdf")

cat("Successfully generated vector PDF figures!\n")
