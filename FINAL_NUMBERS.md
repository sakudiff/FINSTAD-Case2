# FINAL_NUMBERS.md — Frozen Numerical Authority

FINSTAD Case 2, Group 3 (Charlie). Single canonical execution: `reports/finstad_analysis.qmd` rendered with Quarto 1.10.18 on 2026-08-16, plus a byte-identical capture run (`/tmp/capture_final_numbers.R`) of the same chunk logic. All downstream prose, tables, figures, and the Overleaf manuscript must consume ONLY the values in this file.

## 1. Sample

- Start: 2020-01-02 (first price date)
- End: 2025-12-31 (no observation later than this date remains after filtering)
- Raw master rows after filter: 1,508
- Daily return observations: 1,507 (first return dated 2020-01-03)
- EDA-series observations per asset (no-trade days set to NA): TEL 1,507; MER 1,421; AEV 1,420; NVDA 1,507; META 1,507; BTC 1,507
- Risk-free rate: 5.25% annual (mean of RF_Rate column = 0.0525); daily log equivalent log(1.0525)/252
- The raw dataset's 2026-01-02 row is excluded by the code filter; it is not part of any metric.

## 2. Asset annualized simple-return moments (mean x 252, sd x sqrt(252))

| Asset | Ann. mean | Ann. vol |
|-------|-----------|----------|
| TEL   | 12.96%    | 31.13%   |
| MER   | 12.49%    | 31.38%   |
| AEV   | -5.26%    | 38.91%   |
| NVDA  | 71.65%    | 53.18%   |
| META  | 28.99%    | 43.82%   |
| BTC   | 61.49%    | 61.39%   |
| SPY   | 16.02%    | 20.75%   |

Expected-return vector used in optimization (mu_ann, simple daily mean x 252): TEL 0.12965, MER 0.12490, AEV -0.05261, NVDA 0.71651, META 0.28989, BTC 0.61487.

Annualized volatility from the optimization covariance matrix (sqrt(diag(Sigma_ann)), simple daily returns x 252): TEL 31.13%, MER 31.38%, AEV 38.91%, NVDA 53.18%, META 43.82%, BTC 61.39%. This is the convention quoted in Chapter 05 prose.

## 2a. SPY benchmark descriptive statistics (PerformanceAnalytics::table.Stats on the EDA log-return series)

Observations 1,507; Mean (daily log return) 0.0005; Stdev 0.0131; Skewness -0.5584; Kurtosis (excess) 13.3891; Minimum -0.1159; Maximum 0.0999; annualized volatility 20.80% (0.0131 x sqrt(252)).

## 3. Correlations (EDA series, pairwise complete) — values usable in prose

- MER–NVDA 0.0121, MER–META 0.0172, MER–BTC 0.0286, MER–AEV 0.2959, MER–TEL 0.1187
- TEL–AEV 0.0884, TEL–NVDA 0.1894, TEL–META 0.1647, TEL–BTC 0.1615
- AEV–NVDA 0.0155, AEV–META 0.0356, AEV–BTC 0.0155
- NVDA–META 0.5333, NVDA–BTC 0.3204, META–BTC 0.2438
- SPY–NVDA 0.7052, SPY–META 0.6285, SPY–BTC 0.3880

## 4. Performance (equal-weight strategies, simple returns)

| Strategy           | Cumulative | CAGR   | Ann. vol | Sharpe (Rf 5.25%) | Max DD  |
|--------------------|------------|--------|----------|-------------------|---------|
| Buy & Hold         | 743.04%    | 42.83% | 35.12%   | 1.0700            | -58.21% |
| Monthly Rebalanced | 384.85%    | 30.21% | 24.18%   | 1.0325            | -43.20% |
| SPY benchmark      | 129.06%    | 14.87% | 20.75%   | 0.4635            | -33.72% |

- Terminal wealth per USD 1.00: B&H 8.43, Rebalanced 4.85, SPY 2.29
- B&H final (2025-12-31) weights: TEL 3.20%, MER 3.11%, AEV 0.92%, NVDA 61.75%, META 6.26%, BTC 24.77%
- B&H vs Rebalanced cumulative gap: 358.19 pp (743.04 - 384.85)

## 4a. Calendar-year strategy returns (simple returns, carried price series)

| Year | Buy & Hold | Monthly Rebalanced | SPY |
|------|------------|--------------------|-----|
| 2020 | 84.72%     | 70.37%             | 17.24% |
| 2021 | 54.93%     | 46.80%             | 28.73% |
| 2022 | -49.57%    | -36.77%            | -18.18% |
| 2023 | 125.47%    | 85.09%             | 26.18% |
| 2024 | 116.05%    | 50.88%             | 24.89% |
| 2025 | 19.92%     | 9.78%              | 17.72% |

## 4b. Calendar-year asset returns (simple returns, carried price series)

| Year | TEL    | MER    | AEV    | NVDA    | META    | BTC    |
|------|--------|--------|--------|---------|---------|--------|
| 2020 | 51.43% | -2.20% | -4.29% | 118.02% | 30.21%  | 315.17% |
| 2021 | 36.56% | -5.47% | 7.75%  | 125.48% | 23.13%  | 59.67% |
| 2022 | -31.70% | -7.63% | -3.29% | -50.26% | -64.22% | -64.15% |
| 2023 | 11.92% | 35.53% | -21.55% | 239.02% | 194.13% | 153.57% |
| 2024 | 0.81%  | 16.71% | -26.51% | 171.25% | 66.05%  | 121.93% |
| 2025 | 1.48%  | 16.38% | -19.34% | 38.92%  | 13.09%  | -6.34% |

## 4c. Reopening returns after the 2020-03-17/18 PSE suspension (2020-03-19 close vs last pre-suspension close, log returns)

MER -16.68%, AEV -11.75%.

## 4d. Max drawdown peak/trough dates (running-peak convention: depth measured from the running maximum wealth preceding the deepest trough)

Buy & Hold: peak 2021-11-08, trough 2022-10-14, depth -58.21%. Monthly Rebalanced: peak 2021-12-27, trough 2022-10-12, depth -43.20%. Buy & Hold NVDA weight peak: 62.29% on 2025-12-26.

## 5. Optimization (long-only, fully invested, annualized mu/Sigma, Rf 5.25%)

GMV (nloptr SLSQP, status 4 NLOPT_XTOL_REACHED; quadprog cross-check max \|dw\| 5e-7): - Weights: TEL 31.01%, MER 31.23%, AEV 16.85%, NVDA 3.15%, META 12.86%, BTC 4.90% (sum = 1.0000, min = 0.0315) - Return 16.03%, Vol 20.22%, Sharpe 0.5332

Max Sharpe (nloptr SLSQP, status 4 NLOPT_XTOL_REACHED; 7-start robustness all converge to identical solution): - Weights: TEL 0.00%, MER 18.42%, AEV 0.00%, NVDA 55.44%, META 0.00%, BTC 26.14% (sum = 1.0000, min = 0.0000) - Return 58.10%, Vol 38.25%, Sharpe 1.3815 - Recomputed Sharpe from weights, mu_ann, Sigma_ann: 1.3815 (objective recomputation matches) - quadprog frontier-sweep tangency cross-check: Sharpe 1.3815, max weight deviation 0.0061 (grid resolution) - Domestic weight in GMV (TEL+AEV+MER): 79.09%; NVDA+BTC concentration in Max Sharpe: 81.58%

## 6. Risk (daily, portfolio simple returns rebalanced monthly to final weights)

| Portfolio | Hist VaR 95 | Hist VaR 99 | Par VaR 95 | Par VaR 99 | Hist ES 95 | Hist ES 99 | Par ES 95 | Par ES 99 |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| GMV | 1.80% | 3.27% | 2.03% | 2.90% | 2.85% | 4.67% | 2.56% | 3.33% |
| Max Sharpe | 3.39% | 5.64% | 3.74% | 5.38% | 5.11% | 8.55% | 4.74% | 6.19% |

- Empirical 99% ES exceeds parametric 99% ES for Max Sharpe by 8.55 - 6.19 = 2.36 pp (236 bps, 38.1% relative). For GMV: 4.67 - 3.33 = 1.34 pp (40.2% relative). The 95% comparison shows the same direction for GMV (2.85 \> 2.56) and Max Sharpe (5.11 \> 4.74).

## 7. Monte Carlo (10,000 draws, MASS::mvrnorm, seed 123, mu/252, Sigma/252)

| Portfolio  | MC VaR 95% | MC ES 95% |
|------------|------------|-----------|
| GMV        | 2.02%      | 2.54%     |
| Max Sharpe | 3.68%      | 4.72%     |

## 8. Stress scenarios (window cumulative simple returns; Black Swan = worst observed window shock x 1.5)

Scenario windows: COVID 2020-02-19..2020-03-23; Crypto Winter 2022-05-05..2022-05-13; Fed Hike 2022-06-08..2022-06-16; Tech Selloff 2021-11-19..2022-01-27.

| Scenario                | GMV impact | Max Sharpe impact |
|-------------------------|------------|-------------------|
| 2020 COVID Crash        | -22.55%    | -28.83%           |
| 2022 Crypto Winter      | -4.90%     | -14.40%           |
| Fed Rate Hike Shock     | -9.47%     | -18.65%           |
| Tech Sector Selloff     | +3.71%     | -24.58%           |
| Hypothetical Black Swan | -35.89%    | -45.30%           |

Per-asset window shocks: COVID: TEL -9.06%, MER -19.37%, AEV -40.82%, NVDA -28.24%, META -32.00%, BTC -36.74%. Crypto Winter: TEL +1.12%, MER -2.05%, AEV -8.81%, NVDA -12.92%, META -11.10%, BTC -26.24%. Fed Hike: TEL -13.27%, MER +0.65%, AEV -6.09%, NVDA -17.55%, META -17.78%, BTC -34.58%. Tech Selloff: TEL +6.51%, MER +8.37%, AEV +20.26%, NVDA -30.71%, META -13.01%, BTC -34.78%. Black Swan (1.5x worst observed): TEL -19.91%, MER -29.06%, AEV -61.24%, NVDA -46.07%, META -48.00%, BTC -55.10%.

## 9. Generation provenance

- Table/PDF regeneration: `R/generate_all_overleaf_assets.R` (tables to reports/tables/), `R/generate_all_figures.R` (figures to reports/figures/ and overleaf_project/figures/), both executed from repo root against data/master_dataset.csv with the same 2020-01-02..2025-12-31 filter.