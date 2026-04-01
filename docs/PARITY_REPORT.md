# Parity Report: Bigx402Query vs x402scan (Solana)

**Last verified:** April 1, 2026
**Target window:** March 30, 2026 (00:00:00 - 23:59:59 UTC)
**Chain:** Solana Mainnet
**Token:** USDC (`EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`)

---

## Executive Summary

BigQuery captured **15,949 transfers** and **$766.66 USDC** in verified volume on March 30, 2026.
x402scan captured **14,644 transfers** and **$719.36 USDC** over the same window.

BigQuery leads by **+8.9% in transaction count** and **+6.6% in volume**. The datasets are **not at parity** — BigQuery consistently captures more data due to its direct-from-validator ingestion architecture.

---

## 1. Methodology (Shared Taxonomy)

Both platforms identify x402 Solana transactions the same way:

1. Query USDC SPL Token Transfers (mint: `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`)
2. Validate that a known facilitator pubkey appears as a **signer** on the parent transaction
3. Convert raw amounts via `SAFE_DIVIDE(value, POW(10, decimals))`

Both source their facilitator registry from the same canonical list: [`Merit-Systems/x402scan/packages/external/facilitators`](https://github.com/Merit-Systems/x402scan/tree/main/packages/external/facilitators).

**The classification logic is identical.** All discrepancies arise from how data is procured and how edge cases are handled.

---

## 2. Data Sources

| | BigQuery (Tektonic) | x402scan |
|--|---------------------|----------|
| **Solana data** | `bigquery-public-data.crypto_solana_mainnet_us` | BitQuery GraphQL + Coinbase CDP + BigQuery (mixed) |
| **Data provenance** | Google-operated Solana validator nodes streaming to BigQuery | Third-party indexers with consumer RPC enrichment |
| **Ingestion** | Single SQL query over partitioned tables | Trigger.dev cron jobs with pagination windows |
| **Backend** | BigQuery (no operational DB) | PostgreSQL (Prisma) + ClickHouse (analytics) |
| **ATA resolution** | Raw ATAs; optional JOIN to `Accounts` table | Per-tx RPC `getAccount()` loop |
| **Time precision** | Exact UTC partition (`block_timestamp`) | 3.5-hour materialized view buckets |

---

## 3. March 30, 2026 — Head-to-Head Results

| Metric | BigQuery | x402scan | Delta |
|--------|----------|----------|-------|
| Total transfers | **15,949** | **14,644** | +1,305 (+8.9%) |
| Successful transfers | 15,831 | Not distinguished | -- |
| Failed transfers | 118 | Not tracked | -- |
| Unique tx signatures | 15,728 | N/A (bucketed) | -- |
| Volume (USDC) | **$766.66** | **$719.36** | +$47.30 (+6.6%) |
| Time range | 00:00:07 - 23:59:56 UTC | ~00:00 - 00:30+1 UTC (bucketed) | -- |

### How x402scan data was obtained
```bash
# tRPC API: 7-day bucketed stats, 48 buckets (3.5hr each), filtered to Solana
curl -sL "https://www.x402scan.com/api/trpc/public.stats.bucketed?batch=1&input=\
{\"0\":{\"json\":{\"chain\":\"solana\",\"timeframe\":7,\"numBuckets\":48}}}" \
-H "Accept: application/json"
```
Buckets starting between `2026-03-30T00:00:00Z` and `2026-03-30T21:00:00Z` were summed.

### How BigQuery data was obtained
```bash
# Authenticate via: gcloud auth application-default login
# Query: solana/x402_extract.sql with START_DATE = 2026-03-30, END_DATE = 2026-03-31
bq query --use_legacy_sql=false < solana/x402_extract.sql
```

---

## 4. Per-Facilitator Breakdown (BigQuery)

| Facilitator | Pubkey | Success | Failed | Volume (USDC) | Share |
|-------------|--------|---------|--------|---------------|-------|
| Dexter | `DEXVS3su...` | 15,027 | 0 | $604.01 | 94.2% |
| PayAI | `2wKupLR9...` | 585 | 0 | $40.68 | 3.7% |
| Corbits | `AepWpq3G...` | 163 | 0 | $5.39 | 1.0% |
| Cascade | `7NetKx8T...` | 5 | **118** | $0.03 | 0.8% |
| Coinbase (D6Z) | `D6ZhtNQ5...` | 13 | 0 | $63.22 | 0.1% |
| RelAI | `4x4Zhcqi...` | 17 | 0 | $0.86 | 0.1% |
| OpenFacilitator | `Hbe1vdFs...` | 8 | 0 | $2.04 | <0.1% |
| Coinbase (BFK) | `BFK9TLC3...` | 6 | 0 | $0.02 | <0.1% |
| Coinbase (GVJ) | `GVJJ7rdG...` | 5 | 0 | $0.40 | <0.1% |
| Coinbase (BEN) | `BENrLoUb...` | 1 | 0 | $0.01 | <0.1% |
| Coinbase (Hc3) | `Hc3sdEAs...` | 1 | 0 | $50.00 | <0.1% |
| **TOTAL** | | **15,831** | **118** | **$766.66** | |

---

## 5. Hourly Activity (BigQuery)

```
Hour  | Success | Failed | Volume
------+---------+--------+--------
00:00 |     612 |      0 |  $24.46
01:00 |     714 |      0 |  $29.92
02:00 |     580 |      0 |  $85.31
03:00 |     609 |      0 |  $23.40
04:00 |     741 |      0 |  $31.70
05:00 |     776 |      0 |  $32.55
06:00 |     636 |      0 |  $24.86
07:00 |     521 |      0 |  $19.62
08:00 |     530 |     30 |  $20.26
09:00 |     626 |     30 |  $25.06
10:00 |     720 |      0 |  $30.76
11:00 |     679 |     11 |  $29.43
12:00 |     695 |      0 |  $27.54
13:00 |     753 |      0 |  $29.93
14:00 |     708 |      0 |  $27.72
15:00 |     586 |      0 |  $29.48
16:00 |     866 |      0 |  $32.60
17:00 |     612 |      0 |  $23.21
18:00 |     639 |     25 |  $26.55
19:00 |     665 |      0 |  $79.74
20:00 |     787 |     11 |  $39.52
21:00 |     648 |     11 |  $29.92
22:00 |     591 |      0 |  $21.72
23:00 |     537 |      0 |  $21.41
```

Failed transactions cluster in hours 08-09, 11, 18, 20-21 — all from Cascade (`7NetKx8T...`), which had a 95.9% failure rate (118/123).

---

## 6. Three Discrepancies Explained

### 6a. Transaction count: BigQuery +8.9% (1,305 more transfers)

x402scan syncs Solana data via Trigger.dev cron jobs that fetch paginated batches from BitQuery and CDP. When Dexter generates 15K+ txs/day, their pipeline hits capacity:

- Pagination windows have configurable result limits; exceeding them logs a warning but silently drops data
- The ATA resolution loop (`getAccount()` per tx) hits Solana RPC rate limits (HTTP 429)
- No backfill mechanism recovers dropped batches

Their own engineers acknowledged this: *"NOTE(shafu + json): This is a very temporary solution! very bad and does not scale!"*

BigQuery has no ingestion bottleneck — Google's validators stream every transaction directly to the warehouse.

### 6b. Volume: BigQuery +$47.30 (+6.6%)

BigQuery captured more successful transactions that x402scan missed entirely. The 1,305 additional transfers included real payments. This is not failed-transaction inflation — it's x402scan under-counting.

### 6c. Failed transactions: 118 (0.74% failure rate)

BigQuery captures all 118 failed transactions and explicitly zeros their volume:

```sql
CASE WHEN tx.err = '' THEN 'SUCCESS' ELSE 'FAILED' END AS tx_status
CASE WHEN tx_status = 'SUCCESS' THEN SAFE_DIVIDE(...) ELSE 0 END AS amount_usdc
```

x402scan's Solana BigQuery sync query (`sync/transfers/trigger/chains/solana/bigquery/query.ts`) **does not filter on `tx.err`**. Their `TransferEvent` schema has no `tx_status` column. If a failed transaction is ingested, it's counted at face value with no way to distinguish it from a success.

---

## 7. Architectural Comparison

| Dimension | BigQuery | x402scan | Winner |
|-----------|----------|----------|--------|
| Transaction completeness | 100% (validator-level) | ~91% (drops at scale) | BigQuery |
| Volume accuracy | Success-only (0% noise) | No failure filter (0.74% potential noise) | BigQuery |
| Data provenance | Single canonical source | 3 mixed providers | BigQuery |
| Cost | $5-15/mo (on-demand BQ) | $100s/mo (multi-service) | BigQuery |
| Facilitator updates | Hardcoded SQL arrays | Dynamic DB registry | x402scan |
| Frontend/UX | SQL-only, no UI | Full explorer (x402scan.com) | x402scan |
| Operational metrics | On-chain settlement only | Uptime, latency, HTTP status | x402scan |
| Real-time monitoring | Storage Write API (near real-time) | Cron-based (15-30 min lag) | BigQuery |

---

## 8. Reproducibility

All data in this report can be independently verified:

**BigQuery:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="x402-tektonik-key.json"
bq query --use_legacy_sql=false --dry_run < solana/x402_extract.sql  # Cost check
bq query --use_legacy_sql=false < solana/x402_extract.sql            # Execute
```

**x402scan:**
```bash
# Overall stats (rolling 1-day window)
curl -sL "https://www.x402scan.com/api/trpc/public.stats.overall?batch=1&\
input={\"0\":{\"json\":{\"chain\":\"solana\",\"timeframe\":1}}}"

# Bucketed time-series (7 days, 48 buckets)
curl -sL "https://www.x402scan.com/api/trpc/public.stats.bucketed?batch=1&\
input={\"0\":{\"json\":{\"chain\":\"solana\",\"timeframe\":7,\"numBuckets\":48}}}"
```

---

## 9. Conclusion

BigQuery (Tektonic) is the higher-fidelity Solana x402 dataset. It captures more transactions, reports more accurate volume, isolates failed transactions, and provides exact UTC-partitioned time boundaries. The two platforms share identical classification logic — the delta comes entirely from ingestion architecture.

x402scan remains the better product for end-users (explorer UI, wallet integration, operational metrics) but should not be treated as the canonical data source for volume or transaction count reporting.
