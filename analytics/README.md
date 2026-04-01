# x402 Aggregate Analytics — Schema & Results

This directory contains SQL queries that compute the same aggregated statistics
shown on [x402scan.com](https://x402scan.com) — from the raw BigQuery extraction.

## Files

| File | Description |
| :--- | :--- |
| `sol_aggregate_stats.sql` | Solana aggregates against `bigquery-public-data.crypto_solana_mainnet_us` |
| `base_aggregate_stats.sql` | Base aggregates against pre-extracted `base_x402_extract` table or CDP API |
| `results/sol_summary.json` | Live summary output from GCP (Dec 16 2025) |
| `results/sol_per_seller.json` | Live per-seller stats from GCP |
| `results/sol_per_facilitator.json` | Live per-facilitator stats from GCP |
| `results/sol_hourly_activity.json` | Live hourly timeseries from GCP |
| `results/sol_per_buyer.json` | Live per-buyer stats from GCP |

---

## Aggregate Views (mirrors x402scan stats)

### 1. Dashboard Summary (`summary`)
| Field | Type | x402scan Equivalent |
| :--- | :--- | :--- |
| `total_transactions` | INTEGER | "Transactions" counter |
| `total_volume_usdc` | FLOAT | "Volume ($)" |
| `unique_buyers` | INTEGER | "Buyers" count |
| `unique_sellers` | INTEGER | "Sellers" count |
| `active_facilitators` | INTEGER | Active facilitator count |
| `period_start` / `period_end` | TIMESTAMP | Time window |

### 2. Per-Seller / Top Servers (`per_seller`)
| Field | Type | x402scan Equivalent |
| :--- | :--- | :--- |
| `seller_ata` / `seller_address` | STRING | Server address |
| `transaction_count` | INTEGER | "Txns" column |
| `total_volume_usdc` | FLOAT | "Volume" column |
| `unique_buyers` | INTEGER | "Buyers" column |
| `primary_facilitator` | STRING | Facilitator icon |
| `last_seen` | TIMESTAMP | "Latest" column |

### 3. Per-Facilitator (`per_facilitator`)
| Field | Type | x402scan Equivalent |
| :--- | :--- | :--- |
| `facilitator_signer` / `facilitator_name` | STRING | Facilitator name |
| `transaction_count` | INTEGER | "Transactions" |
| `total_volume_usdc` | FLOAT | "Volume" |
| `unique_buyers` | INTEGER | "Buyers" |
| `unique_sellers` | INTEGER | "Sellers" |

### 4. Hourly Timeseries (`hourly_activity`)
| Field | Type | x402scan Equivalent |
| :--- | :--- | :--- |
| `hour_bucket` | TIMESTAMP | X-axis on activity charts |
| `transaction_count` | INTEGER | Sparkline / bar height |
| `volume_usdc` | FLOAT | Volume chart |
| `unique_buyers` | INTEGER | Buyers trendline |

### 5. Per-Buyer (`per_buyer`)
| Field | Type | x402scan Equivalent |
| :--- | :--- | :--- |
| `buyer_ata` / `buyer_address` | STRING | Sender wallet |
| `transaction_count` | INTEGER | Total payments made |
| `total_spent_usdc` | FLOAT | Total USD spent |
| `unique_sellers_paid` | INTEGER | Unique servers accessed |

---

## Live GCP Results (Solana, 2025-12-16)

```
Summary:
  total_transactions:  21
  total_volume_usdc:   $19.819
  unique_buyers:       3
  unique_sellers:      3
  active_facilitators: 1

Facilitator breakdown:
  L54zkaPQFeTn1UsEqieEXBqWrPShiaZEPD7mS5WXfQg (Coinbase)
    → 21 txs | $19.82 volume | 3 buyers | 3 sellers

Hourly Activity:
  2025-12-16 12:00 UTC → 1 tx  | $9.90
  2025-12-16 22:00 UTC → 10 tx | $9.91
  2025-12-16 23:00 UTC → 10 tx | $0.01

Top Buyers:
  qhgsei5a… → 1 tx | $9.90 spent
  94U1Mm47… → 1 tx | $9.90 spent
  HNi2HcP9… → 19 tx | $0.019 spent (high-frequency micro-payments)
```

---

## How to Run

```bash
# Dry run first (Solana)
python3 -c "
import re, subprocess
sql = open('analytics/sol_aggregate_stats.sql').read()
q = sql.split('-- OUTPUT:')[0] + '\nSELECT * FROM summary;'
r = subprocess.run(['bq','query','--use_legacy_sql=false','--dry_run'], input=q.encode(), capture_output=True)
print(r.stderr.decode())
"

# Execute all aggregates
bq query --use_legacy_sql=false < analytics/sol_aggregate_stats.sql
```
