import os
import pandas as pd
import yfinance as yf

DATA_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "data"))
os.makedirs(DATA_DIR, exist_ok=True)

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

print("=== Fetching Market Data for Group 3 (Charlie) ===")

asset_series = {}

for name, symbol in portfolio_tickers.items():
    print(f"Downloading {name} ({symbol})...")
    ticker = yf.Ticker(symbol)
    df = ticker.history(start=START_DATE, end=END_DATE)
    
    if df.empty:
        raise ValueError(f"Failed to fetch data for {name} ({symbol})")
    
    # Clean index and tz
    df.index = pd.to_datetime(df.index).tz_localize(None)
    df.index.name = "Date"
    
    # Save individual CSV
    out_df = df[['Close', 'Open', 'High', 'Low', 'Volume']].rename(
        columns={'Close': 'Price', 'Volume': 'Vol.'}
    )
    csv_path = os.path.join(DATA_DIR, f"{name}.csv")
    out_df.to_csv(csv_path)
    print(f"Saved {csv_path} ({len(out_df)} rows)")
    
    asset_series[name] = df['Close']

# Combine into master dataset aligned on business trading days (using SPY as trading calendar)
master_df = pd.DataFrame(asset_series)

# Align to SPY trading days (drops weekend crypto-only days to keep balanced panel)
master_df = master_df.loc[master_df['SPY'].notna()].copy()
master_df = master_df.sort_index()

# Add Risk-Free Rate column (PH 91-Day T-Bill average ~ 5.25% annual rate, 0.0525)
master_df['RF_Rate'] = 0.0525

# Format Date as YYYY-MM-DD
master_df.index = master_df.index.strftime('%Y-%m-%d')
master_df.index.name = 'Date'

master_csv_path = os.path.join(DATA_DIR, "master_dataset.csv")
master_df.to_csv(master_csv_path)
print(f"\nSuccessfully generated {master_csv_path}")
print(f"Dataset shape: {master_df.shape}")
print(master_df.head(10))
print(master_df.tail(10))
