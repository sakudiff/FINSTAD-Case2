# FINSTAD Case 2 Portfolio Management and Risk Consultation

This repository contains the quantitative data pipeline, R analysis code, and LaTeX document source for Group 3 Charlie in FINSTAD C01 under Professor Bobby Baylon.

Overleaf Live Document link is available at `https://overleaf.lazarusquant.uk/read/zckrmkctwjkq#dffd01`.

Submission deadline is Monday, August 17, 2026 at 2359HRS.

## Assigned Portfolio Universe

Group 3 Charlie evaluates the following seven asset classes over the sample period from January 2, 2020 through December 31, 2025.

- Philippine Stocks: TEL (PLDT Inc.), MER (Meralco), AEV (Aboitiz Equity Ventures)
- International Stocks: NVDA (NVIDIA Corporation), META (Meta Platforms)
- Cryptocurrency: BTC (Bitcoin)
- Benchmark: SPY (S&P 500 ETF Trust)
- Risk Free Rate: PH 91 Day Treasury Bill Benchmark

## Team Roles and Responsibility Matrix

| Report Section / Task | Assigned Team Member | Status |
| --- | --- | --- |
| Data Acquisition and Preparation | Aaron | Completed |
| Exploratory Financial Analysis | Aaron and Enrique | In Progress |
| Portfolio Construction and Evaluation | Team | Scheduled |
| Portfolio Optimization | Aaron | Scheduled |
| Portfolio Risk Assessment | Team | Scheduled |
| Executive Investment Recommendation | Iñigo | Scheduled |
| Introduction | Iñigo | Scheduled |
| Executive Presentation | Team | Scheduled |

## Workspace Directory Layout

- `data/` contains raw asset price CSV files and the compiled master dataset.
- `R/` contains R script data acquisition pipelines and analytical routines.
- `reports/` contains the LaTeX report source files and figures.
- `guidelines.md` contains the formal assignment prompt and scoring rubric.

## Data Acquisition and Running R Scripts

Execute the Python and R data scripts using `uv` or standard R environment.

```bash
uv run --with yfinance --with pandas python3 R/fetch_data.py
```

The script fetches historical daily prices for all seven tickers, aligns dates across trading calendars, attaches the risk free rate, and generates `data/master_dataset.csv`.

## Guide to Editing LaTeX Documents

Team members working on report sections can edit files in Overleaf or locally inside `reports/sections/`.

### Text Formatting

- Bold text uses `\textbf{text}`
- Italic text uses `\textit{text}`
- Code or fixed width font uses `\texttt{text}`
- Subscripts use `x_{i}` and superscripts use `x^{2}`

### Headings and Structure

- Main section heading uses `\section{Section Title}`
- Subsection heading uses `\subsection{Subsection Title}`
- Subsubsection heading uses `\subsubsection{Subsubsection Title}`

### Escaping Reserved Financial Symbols

LaTeX uses several characters for formatting syntax. Escape them with a backslash when writing text or numbers.

- Percent sign uses `\%` instead of `%` (an unescaped `%` comments out the rest of the line)
- Dollar sign uses `\$` instead of `$` (an unescaped `$` enters inline math mode)
- Underscore uses `\_` instead of `_` (an unescaped `_` creates a subscript)
- Ampersand uses `\&` instead of `&` (an unescaped `&` creates a table column separator)
- Hashtag or number sign uses `\#` instead of `#`

### Bullet Lists and Enumerations

Unordered lists use the `itemize` environment.

```latex
\begin{itemize}
  \item Primary recommendation is to allocate 40\% to international equities.
  \item Rebalancing monthly reduces overall portfolio volatility.
\end{itemize}
```

Numbered lists use the `enumerate` environment.

```latex
\begin{enumerate}
  \item Compute log returns for each asset class.
  \item Solve for the Global Minimum Variance portfolio weights.
\end{enumerate}
```

### Inserting Images and Figures

Place image files in `reports/figures/` and reference them using the standard figure environment.

```latex
\begin{figure}[H]
  \centering
  \safeincludegraphics[width=0.85\textwidth]{figures/figure_name.png}
  \caption{Descriptive Title of the Chart}
  \label{fig:figure_label}
\end{figure}
```

Reference the figure in text using `Figure~\ref{fig:figure_label}`.

### Side by Side Subfigures

Use `subfigure` blocks inside a `figure` environment to compare two charts side by side.

```latex
\begin{figure}[H]
  \centering
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \safeincludegraphics[width=\textwidth]{figures/price_plot.png}
    \caption{Historical Price Trajectories}
    \label{fig:sub_price}
  \end{subfigure}
  \hfill
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \safeincludegraphics[width=\textwidth]{figures/return_plot.png}
    \caption{Daily Return Distributions}
    \label{fig:sub_returns}
  \end{subfigure}
  \caption{Exploratory Asset Performance Comparison}
  \label{fig:side_by_side}
\end{figure}
```

### Creating Standard Tables

Tables follow the `booktabs` package format for academic presentation.

```latex
\begin{table}[H]
  \centering
  \caption{Portfolio Descriptive Statistics}
  \label{tab:desc_stats}
  \begin{tabular}{lrrrr}
    \toprule
    Asset & Mean Return & Volatility & Sharpe Ratio & Skewness \\
    \midrule
    TEL & 0.0004 & 0.0182 & 0.35 & -0.12 \\
    MER & 0.0005 & 0.0165 & 0.42 & 0.08 \\
    \bottomrule
  \end{tabular}
\end{table}
```

Reference the table in text using `Table~\ref{tab:desc_stats}`.

### Wide Landscape Tables

For wide tables like correlation heatmaps or multi metric risk matrices, use the `largetable` environment.

```latex
\begin{largetable}
  \caption{Full Asset Universe Correlation Matrix}
  \label{tab:corr_matrix}
  \begin{tabular}{lrrrrrrr}
    \toprule
    Asset & TEL & MER & AEV & NVDA & META & BTC & SPY \\
    \midrule
    TEL & 1.00 & 0.45 & 0.38 & 0.12 & 0.15 & 0.08 & 0.22 \\
    \bottomrule
  \end{tabular}
\end{largetable}
```

### Footnotes and Table Notes

- Footnotes in text use `\footnote{Source: LSEG Workspace and Bloomberg Terminal}`
- Notes inside tables use `\tablefootnote{Computed using daily log returns over 2020 through 2025}`

### Mathematical Equations

- Inline math uses single dollar signs like `$R_{i} = \ln(P_{t} / P_{t-1})$`
- Displayed equations use the equation environment.

```latex
\begin{equation}
  \text{Sharpe Ratio} = \frac{E[R_{p}] - R_{f}}{\sigma_{p}}
\end{equation}
```

### Code Listings for R Appendix

To embed R code in the appendix, use the `lstinputlisting` command or `listings` environment.

```latex
\lstinputlisting[language=R, caption={Data Acquisition and Cleaning Script}]{../R/fetch_data.py}
```

### References and Citations

Add BibTeX citations to `reports/references.bib` and cite them in text using `\autocite{citation_key}` for APA format.
