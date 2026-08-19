<!-- research-readme template: dataset-README -->

This archive was assembled on August 19, 2026.

# Portfolio Management and Risk Consultation (FINSTAD Case 2)

An archival record of a reproducible six-asset portfolio construction, optimization, and risk assessment case study submitted for FINSTAD C01 (Term 1, AY 2026–2027) at De La Salle University. The analysis covers the sample period January 2, 2020 through December 31, 2025 and benchmarks results against the S&P 500 (SPY) using the Philippine 91-day Treasury Bill as the risk-free rate.

## Key Deliverables

| Deliverable | Link |
| --- | --- |
| Final paper (PDF) | [overleaf_project/main.pdf](overleaf_project/main.pdf) |
| Analytical pipeline (Quarto source) | [reports/finstad_analysis.qmd](reports/finstad_analysis.qmd) |
| Analytical pipeline (PDF render) | [reports/finstad_analysis.pdf](reports/finstad_analysis.pdf) |
| Appendix A (attached to the paper) | [overleaf_project/appendix.pdf](overleaf_project/appendix.pdf) |
| Presentation video (MP4, 25 min) | [media/FINSTAD_Case_2.mp4](media/FINSTAD_Case_2.mp4) |

# General Information

## Title of Dataset

Portfolio Management and Risk Consultation (FINSTAD Case 2), Group 3 Charlie. Daily price and return data for six portfolio assets, the S&P 500 benchmark, and the Philippine risk-free rate, with the full analytical pipeline and manuscript.

## Author Information

**Principal Investigator**
Name: Cruz, Ricardo Miguel Iñigo
Institution: De La Salle University, Ramon V. Del Rosario College of Business

**Associate Investigators**
Name: Galedo, Enrique Lorenzo Hermoso
Institution: De La Salle University, Ramon V. Del Rosario College of Business

Name: Seballos, Josiah Dweyn Panganiban
Institution: De La Salle University, Ramon V. Del Rosario College of Business

Name: Seechung, Camille Castro
Institution: De La Salle University, Ramon V. Del Rosario College of Business

Name: Sison, Aaron Joshua Estacio
Institution: De La Salle University, Ramon V. Del Rosario College of Business

## Date of Data Collection

Daily observations from January 2, 2020 through December 31, 2025. Source files were downloaded in August 2026 from the providers listed under Ancillary Data.

## Geographic Location of Data Collection

Philippine equities sourced from the Philippine Stock Exchange. International equities, the benchmark, and cryptocurrency sourced from US and global market feeds.

## Funding Sources

Not disclosed.

# Sharing and Access Information

## Licenses and Restrictions

All rights reserved. This repository is an archival record of a course deliverable. Contact the authors for reuse permission.

## Recommended Citation

Cruz, R. M. I., Galedo, E. L., Seballos, J. D., Seechung, C., & Sison, A. J. (2026). *Portfolio management and risk consultation* [Archived course deliverable]. De La Salle University. https://github.com/sakudiff/FINSTAD-Case2

## Related Publications

The final manuscript is [overleaf_project/main.pdf](overleaf_project/main.pdf), which embeds the analytical pipeline render as Appendix A. The standalone pipeline render is [overleaf_project/appendix.pdf](overleaf_project/appendix.pdf).

## Ancillary Data

- [Philippine Stock Exchange EDGE](https://edge.pse.com.ph), daily OHLCV for MER and AEV
- [Yahoo Finance](https://finance.yahoo.com), historical price data and foreign exchange rates for the US-listed, benchmark, and cryptocurrency series, plus the PHP per USD spot rate
- [Bangko Sentral ng Pilipinas](https://www.bsp.gov.ph), 91-day Treasury Bill secondary market rates

## Derived From

Yes. All price series derive from the providers above. The compiled dataset is frozen in `data/master_dataset.csv` and is the sole input to the analytical pipeline.

# Data and File Overview

## File List

- `data/master_dataset.csv`, the compiled input, 9 columns and 1,509 daily rows spanning January 2, 2020 through January 2, 2026
- `data/*.csv`, raw daily price series per asset, plus `data/pse/` for the Philippine Stock Exchange source files
- `reports/finstad_analysis.qmd`, the analytical pipeline, the single implementation that loads the master dataset, computes returns, and generates all figures and tables
- `reports/finstad_analysis.pdf`, the rendered pipeline output
- `overleaf_project/`, the canonical manuscript tree, including LaTeX source, chapters, tables, figures, bibliography, the compiled `main.pdf`, and `appendix.pdf`
- `chapters/` and `tables/`, editable working copies of the manuscript chapters and generated tables
- `media/FINSTAD_Case_2.mp4`, the recorded presentation video
- `guidelines.md`, the original assignment prompt and scoring rubric

## Relationships Between Files

The pipeline consumes `data/master_dataset.csv` and writes the figures and tables under `reports/`. Those generated assets populate the manuscript in `overleaf_project/`, which compiles to `main.pdf` with the pipeline render attached as Appendix A.

## Additional Related Data

None beyond the providers listed under Ancillary Data.

## Dataset Versions

Single version. This archive reflects the final submission state as of August 17, 2026.

# Methodological Information

## Collection Methods

The portfolio universe spans seven assets across four asset classes, alongside the benchmark index and domestic risk-free rate. US-listed and cryptocurrency instruments were ingested via automated Python REST scripts leveraging the yfinance API. Philippine equities MER and AEV were sourced from the official PSE EDGE portal, while PLDT was represented via its NYSE-listed ADR (PHI) as a market-data proxy. Philippine closing prices quoted in pesos were converted to US dollars using the daily PHP per USD spot rate (WM/Refinitiv via the USDPHP=X feed). The master date index was anchored to the SPY trading calendar of 1,508 days. The risk-free benchmark is the annualized Philippine 91-day Treasury Bill secondary market rate at 5.25 percent.

## Processing Methods

Daily log returns, calendar alignment across all series, and no-trade day handling. The analysis layer carries the last observed price across no-trade days for wealth aggregation and backtesting, so the resumption-day return captures the full gap move. Descriptive statistics and correlations are computed on observed returns only, and no-trade days are never assigned a zero return. All series share a common trading calendar in the compiled master dataset.

## Software Requirements

- R 4.6.1 with `tidyverse`, `lubridate`, `scales`, `xts`, `zoo`, `PerformanceAnalytics`, `nloptr`, `quadprog`, `MASS`, `corrplot`, `knitr`, and `kableExtra`
- Quarto 1.10.18 or newer
- A TeX distribution with `pdflatex` and `biber` for the manuscript

## Quality Assurance

The pipeline runs a data validation and summary check on the compiled input. The master dataset is frozen to guarantee exact reproducibility, and every figure and table in the manuscript reflects the final analytical state. Re-rendering the pipeline and comparing the generated tables against the committed copies verifies the archive.

## Personnel

Cruz, Ricardo Miguel Iñigo. Galedo, Enrique Lorenzo Hermoso. Seballos, Josiah Dweyn Panganiban. Seechung, Camille Castro. Sison, Aaron Joshua Estacio.

# Data-Specific Information

## Number of Variables

Nine columns in the master dataset, eight of which are analytical variables plus the date index.

## Number of Cases or Rows

1,509 daily rows in the compiled dataset. The pipeline filters to the sample end of December 31, 2025, giving 1,508 analyzed trading dates.

## Variable List

| Column | Description |
| --- | --- |
| `Date` | Trading date index |
| `TEL` | PLDT Inc., NYSE ADR, USD |
| `MER` | Meralco, USD |
| `AEV` | Aboitiz Equity Ventures, USD |
| `NVDA` | NVIDIA Corporation, USD |
| `META` | Meta Platforms, USD |
| `BTC` | Bitcoin, USD |
| `SPY` | S&P 500 ETF Trust benchmark, USD |
| `RF_Rate` | Philippine 91-day Treasury Bill rate, annualized |

## Missing Data Codes

Empty cells denote no-trade days for Philippine-listed instruments, where the PSE calendar has no session, plus gaps in the captured PSE EDGE records. The Philippine series were cross-checked against Bloomberg and LSEG Workspace, which returned the same prices and the same missing dates, since those vendors source Philippine equity data from the PSE. No imputation is applied to the stored panel. At the analysis layer, the last observed price is carried across no-trade days for wealth aggregation and backtesting, while descriptive statistics and correlations use observed returns only.

## Specialized Formats or Abbreviations

All prices are USD denominated. Returns are daily log returns. The risk-free rate is expressed as an annualized decimal equivalent.

# Replication

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

# Assigned Portfolio Universe

| Asset | Class | Exchange / Source |
| --- | --- | --- |
| TEL (PLDT Inc., NYSE ADR) | Philippine equity | PSE / NYSE (PHI) |
| MER (Meralco) | Philippine equity | PSE / EDGE |
| AEV (Aboitiz Equity Ventures) | Philippine equity | PSE / EDGE |
| NVDA (NVIDIA Corporation) | International equity | NASDAQ |
| META (Meta Platforms) | International equity | NASDAQ |
| BTC (Bitcoin) | Cryptocurrency | Global crypto |
| SPY (S&P 500 ETF Trust) | Benchmark | NYSE Arca |
| PH 91-Day T-Bill (5.25%) | Risk-free rate | BSP / BTr |

# Citation for This Project

How to cite this archive in academic work.

**APA 7**

Cruz, R. M. I., Galedo, E. L., Seballos, J. D., Seechung, C., & Sison, A. J. (2026). *Portfolio management and risk consultation* [Archived course deliverable]. De La Salle University. https://github.com/sakudiff/FINSTAD-Case2

**BibTeX**

```bibtex
@misc{cruz2026portfolio,
  author       = {Cruz, Ricardo Miguel I{\~n}igo and Galedo, Enrique Lorenzo Hermoso and Seballos, Josiah Dweyn Panganiban and Seechung, Camille Castro and Sison, Aaron Joshua Estacio},
  title        = {Portfolio Management and Risk Consultation},
  year         = {2026},
  howpublished = {Archived course deliverable, De La Salle University},
  url          = {https://github.com/sakudiff/FINSTAD-Case2}
}
```

The manuscript's own references follow the same APA 7 style, managed with `biblatex` and the `biber` backend.
