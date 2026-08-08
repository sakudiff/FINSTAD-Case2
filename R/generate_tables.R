# R script to generate dynamic LaTeX table snippets for FINSTAD Case 2
suppressPackageStartupMessages({
  library(tidyverse)
  library(xts)
  library(PerformanceAnalytics)
  library(kableExtra)
})

# Resolve project root
project_root <- getwd()
if (!dir.exists(file.path(project_root, "data"))) {
  project_root <- normalizePath("..")
}

data_path <- file.path(project_root, "data", "master_dataset.csv")
tables_dir <- file.path(project_root, "reports", "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Data Ingestion
raw_data <- read_csv(data_path, show_col_types = FALSE)
prices_df <- raw_data %>%
  mutate(Date = as.Date(Date)) %>%
  arrange(Date)

asset_cols <- c("TEL", "MER", "AEV", "NVDA", "META", "BTC", "SPY")
prices_mat <- as.matrix(prices_df[, asset_cols])
prices_xts <- xts(prices_mat, order.by = prices_df[["Date"]])

returns_xts <- Return.calculate(prices_xts, method = "log")[-1, ]
portfolio_assets <- c("TEL", "MER", "AEV", "NVDA", "META", "BTC")
asset_returns <- returns_xts[, portfolio_assets]

# Gap-aware series: carried prices with no-trade days set back to NA, so
# resumption-day returns (full gap moves) enter the moments and correlations
prices_carried <- zoo::na.locf(prices_xts)
returns_carried <- Return.calculate(prices_carried, method = "log")[-1, ]
returns_gapaware <- returns_carried
returns_gapaware[is.na(prices_xts[-1, ])] <- NA

# Table 1: Asset Universe & Data Acquisition Summary
obs_counts <- sapply(asset_cols, function(a) sum(!is.na(prices_df[[a]])))

summary_data <- data.frame(
  Ticker = c(asset_cols, "PH 91D T-Bill"),
  Asset_Class = c("Domestic Equity", "Domestic Equity", "Domestic Equity",
                  "International Equity", "International Equity", "Cryptocurrency",
                  "Benchmark ETF", "Risk-Free Rate"),
  Market_Exchange = c("PSE / NYSE (PHI)", "PSE / EDGE (Primary)", "PSE / EDGE (Primary)",
                      "NASDAQ", "NASDAQ", "Global Crypto", "NYSE Arca", "BSP / Bureau of Treasury"),
  Observations = c(sprintf("%d of %d Trading Days", obs_counts[asset_cols], nrow(prices_df)),
                   sprintf("%d Trading Days", nrow(prices_df))),
  Sample_Period = c(rep("Jan 2, 2020 -- Jan 2, 2026", 8))
)

tex_summary <- kbl(
  summary_data,
  format = "latex",
  booktabs = TRUE,
  col.names = c("Asset Ticker", "Asset Class", "Primary Source / Exchange", "Observations", "Sample Period"),
  caption = "Asset Universe and Data Acquisition Specifications",
  label = "data_summary"
) %>%
  kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 9)

writeLines(as.character(tex_summary), file.path(tables_dir, "tbl_data_summary.tex"))

# Table 2: Descriptive Statistics Matrix
stats_mat <- table.Stats(returns_gapaware)
stats_df <- as.data.frame(stats_mat) %>%
  rownames_to_column(var = "Metric")

# Filter key statistical rows
key_metrics <- c("Observations", "Arithmetic Mean", "Stdev", "Skewness", "Kurtosis", "Minimum", "Maximum")
stats_filtered <- stats_df %>%
  filter(Metric %in% key_metrics) %>%
  mutate(Metric = recode(Metric, "Arithmetic Mean" = "Mean"))

tex_stats <- kbl(
  stats_filtered,
  format = "latex",
  booktabs = TRUE,
  digits = 4,
  caption = "Exploratory Financial Descriptive Statistics (Daily Log Returns, Jan 2, 2020 -- Jan 2, 2026)",
  label = "desc_stats"
) %>%
  kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 8)

writeLines(as.character(tex_stats), file.path(tables_dir, "tbl_desc_stats.tex"))

# Table 3: Correlation Matrix
cor_mat <- cor(returns_gapaware, use = "pairwise.complete.obs")
cor_df <- as.data.frame(cor_mat) %>%
  rownames_to_column(var = "Asset")

tex_corr <- kbl(
  cor_df,
  format = "latex",
  booktabs = TRUE,
  digits = 4,
  caption = "Pairwise Asset Return Correlation Matrix (Jan 2, 2020 -- Jan 2, 2026)",
  label = "correlation"
) %>%
  kable_styling(latex_options = c("HOLD_position", "scale_down"), font_size = 9)

writeLines(as.character(tex_corr), file.path(tables_dir, "tbl_correlation.tex"))

cat("Successfully generated LaTeX tables in", tables_dir, "\n")
