import os
import pandas as pd
import yfinance as yf

DATA_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "data"))
os.makedirs(DATA_DIR, exist_ok=True)

PSE_OVERRIDE_DIR = os.path.join(DATA_DIR, "pse")

START_DATE = "2020-01-01"
END_DATE = "2026-01-05"

# Group 3 (Charlie) Asset Universe
portfolio_tickers = {
    "TEL": "PHI",        # PLDT Inc. (NYSE ADR)
    "MER": "MAEOY",      # Manila Electric Co. / Meralco (OTC)
    "AEV": "ABTZY",      # Aboitiz Equity Ventures (OTC)
    "NVDA": "NVDA",      # NVIDIA Corp.
    "META": "META",      # Meta Platforms
    "BTC": "BTC-USD",    # Bitcoin
    "SPY": "SPY"         # S&P 500 ETF (Benchmark)
}

FX_TICKER = "USDPHP=X"


def longest_zero_volume_run(zero_vol: pd.Series) -> int:
    best = 0
    current = 0
    for is_zero in zero_vol:
        current = current + 1 if is_zero else 0
        best = max(best, current)
    return best


def print_quality_report(name: str, df: pd.DataFrame) -> None:
    zero_vol = df["Vol."].isna() | (df["Vol."] <= 0)
    traded = int((~zero_vol).sum())
    n_zero = int(zero_vol.sum())
    longest = longest_zero_volume_run(zero_vol.to_numpy())
    print(
        f"{name}: {traded} traded days, {n_zero} zero-volume days, "
        f"longest zero-volume run {longest} trading days"
    )


def _parse_dates(series: pd.Series) -> pd.Series:
    if series.astype(str).str.fullmatch(r"\d{2}/\d{2}/\d{4}").all():
        return pd.to_datetime(series, format="%m/%d/%Y")
    return pd.to_datetime(series)


def _parse_volume(series: pd.Series) -> pd.Series:
    cleaned = series.astype(str).str.replace(",", "", regex=False)
    suffix = cleaned.str.extract(r"([KMB])$", expand=False).map(
        {"K": 1e3, "M": 1e6, "B": 1e9}
    )
    number = cleaned.str.replace(r"[KMB]$", "", regex=True).astype(float)
    return (number * suffix.fillna(1.0)).round().astype("int64")


def load_pse_override(
    name: str, start: str, end: str, override_dir: str = PSE_OVERRIDE_DIR
) -> pd.DataFrame | None:
    """Load a PSE-listed daily CSV for an asset when present.

    Accepts the canonical PSE-EDGE schema (date, open, high, low, close,
    value_php, optional usd_*), stockanalysis.com exports (quoted fields,
    MM/DD/YYYY dates, K/M/B volume suffixes, optional Change % column), or
    plain Date,Price,Open,High,Low,Vol. CSVs. Prices are PHP and returned
    as-is; callers convert with the USD/PHP rate. usd_* columns are ignored
    so the project FX conversion stays the single authority."""
    path = os.path.join(override_dir, f"{name}.csv")
    if not os.path.exists(path):
        return None

    df = pd.read_csv(path, encoding="utf-8-sig")
    colmap = {
        "date": "Date", "price": "Price", "open": "Open", "high": "High",
        "low": "Low", "close": "Price", "volume": "Vol.", "vol": "Vol.",
        "value_php": "Vol.",
    }
    df = df.rename(columns={c: colmap[c.lower()] for c in df.columns if c.lower() in colmap})
    df = df.drop(columns=[c for c in df.columns if c.lower() == "change %"])
    df["Date"] = _parse_dates(df["Date"])
    df["Vol."] = _parse_volume(df["Vol."])
    df = df.sort_values("Date").drop_duplicates(subset="Date")
    df = df.set_index("Date")
    df.index = pd.to_datetime(df.index).tz_localize(None)

    window = df.loc[(df.index >= pd.Timestamp(start)) & (df.index < pd.Timestamp(end))]
    if window.empty:
        raise ValueError(
            f"PSE override {path} has no rows in {start}..{end}; "
            "re-export the full history for the sample window"
        )
    return window[["Price", "Open", "High", "Low", "Vol."]]


def fetch_fx_usdphp() -> pd.Series:
    """Daily PHP per USD close, used to convert PSE prices to USD."""
    df = yf.Ticker(FX_TICKER).history(start=START_DATE, end=END_DATE)
    if df.empty:
        raise ValueError(f"Failed to fetch FX series {FX_TICKER}")
    close = df["Close"]
    close.index = pd.to_datetime(close.index).tz_localize(None)
    return close[~close.index.duplicated()].sort_index()


def convert_to_usd(df: pd.DataFrame, fx_php_per_usd: pd.Series) -> pd.DataFrame:
    # PSE trades on some days the FX feed does not publish; carry the last rate
    rate = fx_php_per_usd.reindex(df.index).ffill()
    out = df.copy()
    out[["Price", "Open", "High", "Low"]] = (
        out[["Price", "Open", "High", "Low"]].div(rate, axis=0)
    )
    median = out["Price"].median()
    if not (0.1 < median < 1000.0):
        raise ValueError(
            f"Converted USD prices look wrong (median {median:.2f}); "
            "check the FX direction and PSE price scale"
        )
    return out


def main() -> None:
    print("=== Fetching Market Data for Group 3 (Charlie) ===")

    overrides = {
        name: load_pse_override(name, START_DATE, END_DATE)
        for name in portfolio_tickers
    }
    fx = fetch_fx_usdphp() if any(v is not None for v in overrides.values()) else None

    asset_series = {}

    for name, symbol in portfolio_tickers.items():
        override = overrides[name]
        if override is not None:
            out_df = convert_to_usd(override, fx)
            print(f"Using PSE override for {name}: {len(out_df)} rows in window")
        else:
            print(f"Downloading {name} ({symbol})...")
            ticker = yf.Ticker(symbol)
            df = ticker.history(start=START_DATE, end=END_DATE)

            if df.empty:
                raise ValueError(f"Failed to fetch data for {name} ({symbol})")

            # Clean index and tz
            df.index = pd.to_datetime(df.index).tz_localize(None)
            df.index.name = "Date"

            out_df = df[['Close', 'Open', 'High', 'Low', 'Volume']].rename(
                columns={'Close': 'Price', 'Volume': 'Vol.'}
            )

        # Save per-asset panel: raw pull for yfinance assets, USD-converted
        # PSE closes for overrides. Raw OTC evidence stays in git history.
        csv_path = os.path.join(DATA_DIR, f"{name}.csv")
        out_df.to_csv(csv_path)
        print(f"Saved {csv_path} ({len(out_df)} rows)")

        # yfinance returns the last close with Volume 0 when an illiquid OTC
        # ticker does not trade. A zero-volume close is not a settlement price,
        # so it enters the master panel as missing instead of a fake 0-return day.
        valid_close = out_df["Price"].where(out_df["Vol."] > 0)
        asset_series[name] = valid_close
        print_quality_report(name, out_df)

    # Combine into master dataset aligned on business trading days (using SPY as trading calendar)
    master_df = pd.DataFrame(asset_series)

    # Align to SPY trading days (drops weekend crypto-only days to keep balanced panel)
    master_df = master_df.loc[master_df['SPY'].notna()].copy()
    master_df = master_df.sort_index()

    # Add Risk-Free Rate column (Ingest raw PH 91-Day T-Bill secondary market series from BSP/BTr)
    tbill_path = os.path.join(DATA_DIR, "PH_91D_TBill.csv")
    if os.path.exists(tbill_path):
        tbill_df = pd.read_csv(tbill_path)
        tbill_df['Date'] = pd.to_datetime(tbill_df['Date']).dt.strftime('%Y-%m-%d')
        tbill_dict = dict(zip(tbill_df['Date'], tbill_df['RF_Rate']))
        master_df['RF_Rate'] = master_df.index.map(lambda d: tbill_dict.get(d, 0.0525))
    else:
        master_df['RF_Rate'] = 0.0525

    # Format Date as YYYY-MM-DD
    master_df.index = master_df.index.strftime('%Y-%m-%d')
    master_df.index.name = 'Date'

    missing = master_df.isna().sum()
    if (missing > 0).any():
        print("\nMissing (no-trade) days per asset in master panel:")
        print(missing[missing > 0].to_string())
    else:
        print("\nNo missing days in master panel")

    master_csv_path = os.path.join(DATA_DIR, "master_dataset.csv")
    master_df.to_csv(master_csv_path)
    print(f"\nSuccessfully generated {master_csv_path}")
    print(f"Dataset shape: {master_df.shape}")
    print(master_df.head(10))
    print(master_df.tail(10))


if __name__ == "__main__":
    main()
