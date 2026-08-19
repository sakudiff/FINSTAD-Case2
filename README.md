# FINSTAD Case 2 Portfolio Management and Risk Consultation

A reproducible six-asset portfolio construction, optimization, and risk assessment case study submitted for FINSTAD C01 (Term 1, AY 2026–2027) at De La Salle University. The analysis covers the sample period January 2, 2020 through December 31, 2025 and benchmarks results against the S&P 500 (SPY) using the Philippine 91-day Treasury Bill as the risk-free rate.

## Key Deliverables

| Deliverable | Link |
| --- | --- |
| Final paper (PDF) | [overleaf_project/main.pdf](overleaf_project/main.pdf) |
| Analytical pipeline (Quarto source) | [reports/finstad_analysis.qmd](reports/finstad_analysis.qmd) |
| Analytical pipeline (PDF render) | [reports/finstad_analysis.pdf](reports/finstad_analysis.pdf) |
| Appendix A (attached to the paper) | [overleaf_project/appendix.pdf](overleaf_project/appendix.pdf) |
| Presentation video (MP4, 25 min) | [media/FINSTAD_Case_2.mp4](media/FINSTAD_Case_2.mp4) |

## Project Overview

The study evaluates whether diversification across Philippine equities, international technology stocks, and cryptocurrency improves risk-adjusted performance relative to a single-asset benchmark. A portfolio of TEL, MER, AEV, NVDA, META, and BTC is constructed, optimized, and stress-tested against SPY.

The analytical pipeline performs daily log-return computation, exploratory data analysis, portfolio construction under equal-weight buy-and-hold and monthly rebalancing regimes, mean-variance optimization, and a full downside-risk assessment. The recommended portfolio is the Maximum Sharpe portfolio under monthly rebalancing for growth-oriented investors, with the Global Minimum Variance portfolio as the capital-preservation alternative.

## Assigned Portfolio Universe

| Asset | Class | Source |
| --- | --- | --- |
| TEL (PLDT Inc., NYSE ADR) | Philippine equity | Yahoo Finance |
| MER (Meralco) | Philippine equity | PSE EDGE |
| AEV (Aboitiz Equity Ventures) | Philippine equity | PSE EDGE |
| NVDA (NVIDIA Corporation) | International equity | Yahoo Finance |
| META (Meta Platforms) | International equity | Yahoo Finance |
| BTC (Bitcoin) | Cryptocurrency | Yahoo Finance |
| SPY (S&P 500 ETF Trust) | Benchmark | Yahoo Finance |
| PH 91-Day T-Bill (5.25%) | Risk-free rate | Bangko Sentral ng Pilipinas |

## Repository Structure

- `overleaf_project/` — the canonical manuscript tree (LaTeX source, chapters, tables, figures, bibliography, compiled `main.pdf`, and `appendix.pdf`)
- `reports/` — the Quarto analytical pipeline (`finstad_analysis.qmd`), its PDF render, and generated figures and tables
- `data/` — committed raw asset price series and the compiled `master_dataset.csv` used by the pipeline
- `chapters/` and `tables/` — editable working copies of the manuscript chapters and generated tables
- `media/` — the recorded presentation video
- `guidelines.md` — the original assignment prompt and scoring rubric

## Replication

The committed datasets under `data/` are the input source. The pipeline is `reports/finstad_analysis.qmd`, which loads `data/master_dataset.csv`, computes returns, generates all figures and tables, and renders to PDF via Quarto.

```bash
git clone https://github.com/sakudiff/FINSTAD-Case2.git
cd FINSTAD-Case2
quarto render reports/finstad_analysis.qmd
```

Required R packages

```r
install.packages(c(
  "tidyverse", "lubridate", "scales", "xts", "zoo",
  "PerformanceAnalytics", "nloptr", "quadprog", "MASS",
  "corrplot", "knitr", "kableExtra"
))
```

To recompile the paper from source, run the standard `pdflatex` and `biber` chain from `overleaf_project/`

```bash
cd overleaf_project
pdflatex main.tex
biber main
pdflatex main.tex
pdflatex main.tex
```

The compiled `main.pdf` embeds Appendix A (the pipeline render) through the `pdfpages` package, so the appendix pages are included automatically.

## Data Provenance

- Philippine closing prices from PSE EDGE are quoted in Philippine pesos and converted to US dollars using the daily PHP per USD spot rate
- US-listed and cryptocurrency instruments use adjusted daily prices from Yahoo Finance
- The Philippine 91-day Treasury Bill secondary market rate serves as the risk-free benchmark
- All series are aligned on a common trading calendar with no-trade days carried forward, and the master dataset is frozen in `data/master_dataset.csv` for exact reproducibility

## Citation Style

References follow APA 7 and are managed with `biblatex` (`style=apa`, `biber` backend). In-text citations use parenthetical `(Author, Year)` and narrative `Author (Year)` forms throughout the manuscript.
