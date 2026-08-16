# R script to generate all LaTeX tables and PDF/PNG figures for Overleaf
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(scales)
  library(xts)
  library(zoo)
  library(PerformanceAnalytics)
  library(nloptr)
  library(quadprog)
  library(MASS)
  library(corrplot)
  library(knitr)
  library(kableExtra)
})

project_root <- getwd()
data_path <- file.path(project_root, "data", "master_dataset.csv")
tables_dir <- file.path(project_root, "reports", "tables")
figures_dir <- file.path(project_root, "reports", "figures")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Ingestion & Filtering
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
returns_xts_eda <- returns_xts_carried
returns_xts_eda[is.na(prices_xts[-1, ])] <- NA
asset_returns_eda <- returns_xts_eda[, portfolio_assets]

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

# Table 1: Data Acquisition Summary
obs_counts <- sapply(asset_cols, function(a) sum(!is.na(raw_data[[a]])))
summary_df <- data.frame(
  Ticker = c(asset_cols, "PH 91D T-Bill"),
  Class = c("Domestic Equity", "Domestic Equity", "Domestic Equity", "International Equity", "International Equity", "Cryptocurrency", "Benchmark ETF", "Risk-Free Rate"),
  Exchange = c("PSE / NYSE (PHI)", "PSE / EDGE", "PSE / EDGE", "NASDAQ", "NASDAQ", "Global Crypto", "NYSE Arca", "BSP / BTr"),
  Obs = c(sprintf("%d Days", obs_counts[asset_cols]), sprintf("%d Days", nrow(raw_data))),
  Period = rep("Jan 2, 2020 -- Dec 31, 2025", 8)
)
tex_t1 <- kbl(summary_df, format = "latex", booktabs = TRUE, col.names = c("Asset Ticker", "Asset Class", "Exchange / Source", "Observations", "Sample Period"), caption = "Asset Universe and Data Acquisition Specifications", label = "data_summary") %>% kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 9)
writeLines(as.character(tex_t1), file.path(tables_dir, "tbl_data_summary.tex"))

# Table 2: Descriptive Statistics
stats_mat <- table.Stats(asset_returns_eda)
stats_df <- as.data.frame(stats_mat) %>% rownames_to_column(var = "Metric")
key_metrics <- c("Observations", "Arithmetic Mean", "Stdev", "Skewness", "Kurtosis", "Minimum", "Maximum")
stats_filtered <- stats_df %>% filter(Metric %in% key_metrics) %>% mutate(Metric = recode(Metric, "Arithmetic Mean" = "Mean"))
tex_t2 <- kbl(stats_filtered, format = "latex", booktabs = TRUE, digits = 4, caption = "Exploratory Financial Descriptive Statistics (Jan 2, 2020 -- Dec 31, 2025)", label = "desc_stats") %>% kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 8)
writeLines(as.character(tex_t2), file.path(tables_dir, "tbl_desc_stats.tex"))

# Table 3: Correlation Matrix
cor_mat <- cor(returns_xts_eda, use = "pairwise.complete.obs")
cor_df <- as.data.frame(cor_mat) %>% rownames_to_column(var = "Asset")
tex_t3 <- kbl(cor_df, format = "latex", booktabs = TRUE, digits = 4, caption = "Pairwise Asset Return Correlation Matrix (Jan 2, 2020 -- Dec 31, 2025)", label = "correlation") %>% kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 9)
writeLines(as.character(tex_t3), file.path(tables_dir, "tbl_correlation.tex"))

# Portfolio Performance & Optimization Calculations
w_eq <- rep(1/6, 6); names(w_eq) <- portfolio_assets
port_bnh <- Return.portfolio(R = asset_returns_smp, weights = w_eq, verbose = TRUE)
port_reb <- Return.portfolio(R = asset_returns_smp, weights = w_eq, rebalance_on = "months", verbose = TRUE)

eval_p <- function(r_s, name) {
  cum_r <- as.numeric(tail(cumprod(1 + r_s), 1)) - 1
  n_o   <- length(r_s)
  cagr  <- (1 + cum_r)^(252 / n_o) - 1
  sd_a  <- sd(as.numeric(r_s)) * sqrt(252)
  sh    <- (cagr - rf_annual) / sd_a
  mdd   <- as.numeric(maxDrawdown(r_s))
  data.frame(Strategy = name, Cumulative = sprintf("%.2f%%", cum_r*100), CAGR = sprintf("%.2f%%", cagr*100), Volatility = sprintf("%.2f%%", sd_a*100), Sharpe = sprintf("%.4f", sh), MaxDD = sprintf("%.2f%%", mdd*100), check.names=F)
}

perf_df <- rbind(eval_p(port_bnh$returns, "Equal-Weight (Buy & Hold)"), eval_p(port_reb$returns, "Equal-Weight (Monthly Rebalanced)"), eval_p(ret_smp[, "SPY"], "SPDR S&P 500 ETF (SPY Benchmark)"))
tex_t4 <- kbl(perf_df, format = "latex", booktabs = TRUE, caption = "Portfolio Performance Summary Comparison (Jan 2, 2020 -- Dec 31, 2025)", label = "portfolio_performance") %>% kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 9)
writeLines(as.character(tex_t4), file.path(tables_dir, "tbl_portfolio_performance.tex"))

# Optimization Solvers
mu_ann <- colMeans(asset_returns_smp, na.rm = TRUE) * 252
Sigma_ann <- cov(asset_returns_smp, use = "pairwise.complete.obs") * 252
n_a <- length(mu_ann); asset_names <- names(mu_ann); w0 <- rep(1/n_a, n_a)

eval_f_v <- function(w) as.numeric(t(w) %*% Sigma_ann %*% w)
eval_g_v <- function(w) nl.grad(w, eval_f_v)
eval_eq  <- function(w) sum(w) - 1
eval_jac <- function(w) nl.jacobian(w, eval_eq)

gmv_res <- nloptr(x0=w0, eval_f=eval_f_v, eval_grad_f=eval_g_v, lb=rep(0,n_a), ub=rep(1,n_a), eval_g_eq=eval_eq, eval_jac_g_eq=eval_jac, opts=list(algorithm="NLOPT_LD_SLSQP", xtol_rel=1e-8))
w_gmv <- gmv_res$solution; names(w_gmv) <- asset_names

eval_f_s <- function(w) { p_r <- sum(w*mu_ann); p_sd <- sqrt(as.numeric(t(w)%*%Sigma_ann%*%w)); -(p_r - rf_annual)/p_sd }
eval_g_s <- function(w) nl.grad(w, eval_f_s)

shp_res <- nloptr(x0=w0, eval_f=eval_f_s, eval_grad_f=eval_g_s, lb=rep(0,n_a), ub=rep(1,n_a), eval_g_eq=eval_eq, eval_jac_g_eq=eval_jac, opts=list(algorithm="NLOPT_LD_SLSQP", xtol_rel=1e-8))
w_sharpe <- shp_res$solution; names(w_sharpe) <- asset_names

# Table 5: Optimal Weights
w_opt_df <- data.frame(Asset = asset_names, GMV = sprintf("%.2f%%", w_gmv*100), MaxSharpe = sprintf("%.2f%%", w_sharpe*100))
tex_t5 <- kbl(w_opt_df, format = "latex", booktabs = TRUE, col.names = c("Asset", "GMV Weight", "Max Sharpe Weight"), caption = "Optimal Portfolio Weights: GMV vs Maximum Sharpe", label = "optimal_weights") %>% kable_styling(latex_options = c("HOLD_position"), font_size = 9)
writeLines(as.character(tex_t5), file.path(tables_dir, "tbl_optimal_weights.tex"))

# Risk Assessment Tables
port_ret_gmv <- Return.portfolio(R = asset_returns_smp, weights = w_gmv, rebalance_on = "months")
port_ret_shp <- Return.portfolio(R = asset_returns_smp, weights = w_sharpe, rebalance_on = "months")

v_h_g95 <- abs(as.numeric(VaR(port_ret_gmv, p=0.95, method="historical")))
v_h_g99 <- abs(as.numeric(VaR(port_ret_gmv, p=0.99, method="historical")))
v_p_g95 <- abs(as.numeric(VaR(port_ret_gmv, p=0.95, method="gaussian")))
v_p_g99 <- abs(as.numeric(VaR(port_ret_gmv, p=0.99, method="gaussian")))
e_h_g95 <- abs(as.numeric(ES(port_ret_gmv, p=0.95, method="historical")))
e_h_g99 <- abs(as.numeric(ES(port_ret_gmv, p=0.99, method="historical")))
e_p_g95 <- abs(as.numeric(ES(port_ret_gmv, p=0.95, method="gaussian")))
e_p_g99 <- abs(as.numeric(ES(port_ret_gmv, p=0.99, method="gaussian")))

v_h_s95 <- abs(as.numeric(VaR(port_ret_shp, p=0.95, method="historical")))
v_h_s99 <- abs(as.numeric(VaR(port_ret_shp, p=0.99, method="historical")))
v_p_s95 <- abs(as.numeric(VaR(port_ret_shp, p=0.95, method="gaussian")))
v_p_s99 <- abs(as.numeric(VaR(port_ret_shp, p=0.99, method="gaussian")))
e_h_s95 <- abs(as.numeric(ES(port_ret_shp, p=0.95, method="historical")))
e_h_s99 <- abs(as.numeric(ES(port_ret_shp, p=0.99, method="historical")))
e_p_s95 <- abs(as.numeric(ES(port_ret_shp, p=0.95, method="gaussian")))
e_p_s99 <- abs(as.numeric(ES(port_ret_shp, p=0.99, method="gaussian")))

risk_df <- data.frame(
  Portfolio = rep(c("GMV", "Max Sharpe"), each = 4),
  Metric    = rep(c("Historical VaR", "Parametric VaR", "Historical ES (CVaR)", "Parametric ES (CVaR)"), 2),
  `95% CI`  = sprintf("%.2f%%", c(v_h_g95, v_p_g95, e_h_g95, e_p_g95, v_h_s95, v_p_s95, e_h_s95, e_p_s95)*100),
  `99% CI`  = sprintf("%.2f%%", c(v_h_g99, v_p_g99, e_h_g99, e_p_g99, v_h_s99, v_p_s99, e_h_s99, e_p_s99)*100),
  check.names = FALSE
)
tex_t6 <- kbl(risk_df, format = "latex", booktabs = TRUE, caption = "Historical and Parametric VaR / CVaR Summary (Daily, 95 percent and 99 percent Confidence)", label = "var_summary") %>% kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 9)
writeLines(as.character(tex_t6), file.path(tables_dir, "tbl_var_summary.tex"))

# Monte Carlo Simulation Table
set.seed(123)
n_sims <- 10000
sim_returns <- mvrnorm(n = n_sims, mu = mu_ann/252, Sigma = Sigma_ann/252)
colnames(sim_returns) <- asset_names
sim_gmv <- as.numeric(sim_returns %*% w_gmv)
sim_shp <- as.numeric(sim_returns %*% w_sharpe)

mc_v_g95 <- quantile(sim_gmv, 0.05); mc_v_s95 <- quantile(sim_shp, 0.05)
mc_e_g95 <- mean(sim_gmv[sim_gmv <= mc_v_g95]); mc_e_s95 <- mean(sim_shp[sim_shp <= mc_v_s95])

mc_df <- data.frame(
  Portfolio = c("GMV", "Max Sharpe"),
  `MC VaR (95%)` = sprintf("%.2f%%", c(abs(mc_v_g95), abs(mc_v_s95))*100),
  `MC ES (95%)`  = sprintf("%.2f%%", c(abs(mc_e_g95), abs(mc_e_s95))*100),
  check.names = FALSE
)
tex_t7 <- kbl(mc_df, format = "latex", booktabs = TRUE, caption = "Monte Carlo Simulated VaR and Expected Shortfall (10,000 Simulations)", label = "mc_summary") %>% kable_styling(latex_options = c("HOLD_position"), font_size = 9)
writeLines(as.character(tex_t7), file.path(tables_dir, "tbl_mc_summary.tex"))

# Stress Testing Table
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

stress_tex_df <- stress_df %>% mutate(
  `GMV Portfolio Impact` = sprintf("%.2f%%", GMV_Impact * 100),
  `Max Sharpe Portfolio Impact` = sprintf("%.2f%%", MaxSharpe_Impact * 100)
) %>% dplyr::select(Scenario, `GMV Portfolio Impact`, `Max Sharpe Portfolio Impact`)

tex_t8 <- kbl(stress_tex_df, format = "latex", booktabs = TRUE, caption = "Portfolio Impact Under Stress Scenarios", label = "stress_summary") %>% kable_styling(latex_options = c("HOLD_position"), font_size = 9)
writeLines(as.character(tex_t8), file.path(tables_dir, "tbl_stress_summary.tex"))

cat("All LaTeX tables generated in reports/tables/\n")
