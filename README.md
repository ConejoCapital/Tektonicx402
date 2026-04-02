# Tektonicx402

**A free, high-fidelity x402 transactional archive brought to you by Tektonic, with support from Google Cloud Web3 and Solana Foundation.**

---

## Overview

The Tektonic x402 dataset provides a comprehensive, open-access ledger of decentralized API monetization and AI-agent payment settlements executed under the [x402 protocol](https://www.x402.org/). It indexes every onchain USDC micro-settlement across the **Base** and **Solana** blockchain networks, producing a complete historical record of machine-to-machine commerce currently available as a public good.

By replacing rate-limited, legacy HTTP RPC-polling methodologies with a BigQuery-native extraction engine operating directly on Google Cloud's public blockchain datasets, this pipeline achieves 100% historical accuracy and throughput capture, logging tens of thousands of daily micro-settlements that traditional indexers physically cannot access due to API throttling and pagination constraints.

**Who this is for:**
- **Researchers** studying decentralized API monetization, agentic commerce, or on-chain micro-payment dynamics
- **Data analysts** building dashboards, volume trackers, or facilitator leaderboards for the x402 ecosystem
- **AI developers** training models on real-world agent transaction patterns or integrating x402 settlement data into agentic workflows
- **Protocol teams** auditing facilitator behavior, measuring adoption, or benchmarking settlement accuracy
- - **Insitutional Fintechs** track adoption of agentic commerce and evaluate market opportunity.

---

## How x402 Works

x402 is an open payment protocol that reuses the dormant HTTP `402 Payment Required` status code to enable permissionless, per-request API monetization. When a client (human or AI agent) requests a gated resource:

1. The server returns **HTTP 402** with a structured payment requirements payload specifying the price, accepted token, and destination.
2. The client generates a signed authorization **off-chain** — an EIP-712 typed signature on EVM chains, or an SPL token approval on Solana.
3. The client retries the original request with an `X-PAYMENT` header containing the signed payload.
4. A **Facilitator** — a trusted intermediary service — verifies the cryptographic signature, submits the on-chain USDC settlement transaction, and confirms payment.
5. The server delivers the resource on **HTTP 200**.

The entire flow settles in a single block confirmation. No accounts, subscriptions, or API keys are required by the end-user.

### OnChain Fingerprint

The x402 protocol leaves a deterministic on-chain fingerprint that this pipeline detects:

| Chain | Detection Signal | On-Chain Event |
| :--- | :--- | :--- |
| **Base (EVM)** | Standard ERC-20 `Transfer` event WHERE `transaction_from` is a known facilitator wallet | `Transfer(address, address, uint256)` on the USDC contract |
| **Solana (SVM)** | USDC SPL token transfer WHERE a known facilitator pubkey appears as a **signer** on the parent transaction | `Token Transfers` table joined to `Transactions` signer accounts |

> **Important clarification:** x402 does NOT emit `TransferWithAuthorization` events on-chain. The EIP-3009 signature is used only off-chain during the client authorization step. The facilitator settles via a standard `transferFrom` call, producing a normal `Transfer` event. This distinction is critical for correct extraction logic.

---

## Methodology and Architecture

This pipeline operates directly on canonical execution traces streamed continuously by Google Cloud Web3's public blockchain datasets. There are no third-party indexer dependencies, no consumer-grade RPC polling, and no intermediate caching layers between the validator ledger and the extraction output.

### SVM (Solana) — Success Purity

The Solana Virtual Machine records both successful and failed transactions on-chain. Unlike EVM chains, where reverted transactions never emit token transfer events, Solana's `Token Transfers` table in BigQuery contains entries from failed transactions that were broadcast to validators but ultimately reverted during execution.

This pipeline enforces strict boolean execution filters to eliminate failed transaction contamination:

```sql
CASE WHEN tx.err = '' THEN 'SUCCESS' ELSE 'FAILED' END AS tx_status

CASE WHEN tx_status = 'SUCCESS'
  THEN SAFE_DIVIDE(t.value, POW(10, t.decimals))
  ELSE 0
END AS amount_usdc
```

Every transaction is preserved in the output for complete trace logging, but failed transactions are explicitly zeroed in the `amount_usdc` column. Downstream consumers can safely `SUM(amount_usdc)` without risk of double-counting, or filter on `WHERE tx_status = 'SUCCESS'` for pure settlement datasets. This achieves exactly 0.00% failed transaction contamination in volume reporting.

### EVM (Base) — Native Event Purity

On Base and all EVM-compatible chains, reverted transactions do not emit `Transfer` events in the block logs. This means the extraction pipeline inherits mathematically perfect failure filtering as a native property of the execution environment — no additional status checks are required. Every `Transfer` event in the dataset represents a confirmed, settled payment.

### RPC-Bypass Architecture

Traditional blockchain indexers resolve Solana Associated Token Accounts (ATAs) back to their parent human wallet addresses by issuing per-transaction RPC calls to public Solana endpoints. At scale — particularly when facilitators like Dexter generate 15,000+ micro-settlements per day — this approach collides with HTTP 429 rate limits, causing silent data loss.

This pipeline sidesteps the RPC bottleneck entirely by:
1. Outputting raw canonical ATA addresses directly into the extraction output
2. Deferring owner resolution to a native BigQuery `JOIN` against the `crypto_solana_mainnet_us.Accounts` table when needed
3. Processing all facilitators simultaneously in a single SQL execution rather than sequential per-facilitator polling

The result is zero data loss at any throughput level, with no dependency on external API availability.

---

## Repository Structure

```
tektonicx402/
├── README.md                        # This document
│
├── base/                            # Base network extraction
│   ├── x402_extract_bq.sql          # BigQuery SQL (100+ facilitator addresses, 28 organizations)
│   └── schema.md                    # Output schema and facilitator address registry
│
├── solana/                          # Solana network extraction
│   ├── x402_extract.sql             # BigQuery SQL (22 facilitator pubkeys, 15 organizations)
│   └── schema.md                    # Output schema and facilitator pubkey registry
│
├── analytics/                       # Aggregate statistics (5 views per chain)
│   ├── sol_aggregate_stats.sql      # Solana: summary, per-seller, per-facilitator, hourly, per-buyer
│   ├── base_aggregate_stats.sql     # Base: same 5 aggregate views
│   ├── README.md                    # Aggregate schema documentation
│   └── results/                     # Sample extraction outputs (JSON)
│
├── scripts/
│   └── stream_to_bq.py             # BigQuery Storage Write API streaming client (template)
│
└── docs/
    ├── PARITY_REPORT.md             # Verified data comparison report (March 30, 2026)
    └── analytics_hub_listing.md     # Public dataset description
```

---

## Data Sources

| Chain | BigQuery Dataset | Tables | Notes |
| :--- | :--- | :--- | :--- |
| **Solana** | `bigquery-public-data.crypto_solana_mainnet_us` | `Transactions`, `Token Transfers` | Google-operated validator nodes; partitioned on `block_timestamp` |
| **Base** | Analytics Hub Community Dataset (linked) | `token_transfers` or equivalent | Requires creating a linked dataset in your GCP project |

Both datasets are publicly accessible through Google Cloud BigQuery. No special permissions are required beyond a standard GCP project with BigQuery API enabled.

---

## Running the Extraction Queries

### Prerequisites

```bash
# Authenticate to Google Cloud
gcloud auth application-default login

# Verify BigQuery CLI is available
bq version
```

### Solana Extraction

```bash
# Always dry-run first to check estimated scan cost
bq query --use_legacy_sql=false --dry_run < solana/x402_extract.sql

# Execute the extraction
bq query --use_legacy_sql=false < solana/x402_extract.sql
```

The Solana query uses `DECLARE` statements for configurable date ranges. Edit `START_DATE` and `END_DATE` at the top of the file to control the extraction window.

### Base Extraction

```bash
bq query --use_legacy_sql=false --dry_run < base/x402_extract_bq.sql
bq query --use_legacy_sql=false < base/x402_extract_bq.sql
```

> **Note:** The Base query references a linked dataset. You must first create an Analytics Hub linked dataset in your GCP project and update the `FROM` clause with your project and dataset name. See comments in the SQL file.

---

## Known Facilitators

### Base — 28 Organizations, 100+ Addresses

| Facilitator | Addresses | Notes |
| :--- | :--- | :--- |
| Coinbase CDP | 25 wallets | Primary facilitator, fee-free USDC settlement |
| PayAI | 15 wallets | Multi-chain AI payment facilitator |
| Questflow | 10 wallets | AI workflow automation |
| Thirdweb | 10 wallets | Web3 developer platform |
| Heurist | 9 wallets | AI inference marketplace |
| X402rs | 6 wallets | Open-source Rust facilitator |
| CodeNut | 4 wallets | Developer tools |
| AurraCloud | 3 wallets | Cloud AI services |
| Meridian | 2 wallets | High-value settlements |
| Daydreams, OpenX402 | 2 wallets each | — |
| + 17 more | 1 wallet each | Virtuals, Dexter, Corbits, Cascade, Treasure, Polymer, etc. |

Full address list: [`base/x402_extract_bq.sql`](./base/x402_extract_bq.sql)

### Solana — 15 Organizations, 22 Pubkeys

| Facilitator | Pubkeys |
| :--- | :--- |
| Coinbase CDP | 6 pubkeys |
| PayAI | 3 pubkeys |
| AnySpend, AurraCloud, Bitrefill, Cascade, CodeNut | 1 each |
| Corbits, Daydreams, Dexter, OpenFacilitator, OpenX402 | 1 each |
| RelAI, Ultravioleta DAO, x402 Jobs | 1 each |

Full pubkey list: [`solana/x402_extract.sql`](./solana/x402_extract.sql)

> Facilitator registries are sourced from the [x402scan canonical facilitator list](https://github.com/Merit-Systems/x402scan). New facilitators should be added to the SQL `DECLARE` / `INSERT` blocks as they register with the protocol.

---

## Aggregate Analytics

The `analytics/` directory provides five pre-built aggregate views per chain that mirror the statistics displayed on [x402scan.com](https://x402scan.com):

| View | Description |
| :--- | :--- |
| **Summary** | Total transactions, volume, unique buyers, unique sellers, active facilitators |
| **Per-Seller** | Transaction count, volume, unique buyers per destination address |
| **Per-Facilitator** | Transaction count, volume, unique buyers, unique sellers per facilitator |
| **Hourly Activity** | Time-series bucketed by hour for transaction count, volume, and active buyers |
| **Per-Buyer** | Transaction count, total spent, unique sellers accessed per source address |

See [`analytics/README.md`](./analytics/README.md) for full schema definitions and sample outputs.

---

## Cost and Partition Warnings

### Solana — Mandatory Partition Filter

The `crypto_solana_mainnet_us` dataset is one of the largest public datasets in BigQuery. An unpartitioned query can scan **100 TB+** and generate a bill of **$5,000 to $20,000** in a single execution.

The `block_timestamp` partition predicate is enforced at the CTE level in `solana/x402_extract.sql` and must never be removed:

```sql
WHERE tx.block_timestamp >= start_ts AND tx.block_timestamp < end_ts
```

**Always dry-run before executing:**
```bash
bq query --use_legacy_sql=false --dry_run < solana/x402_extract.sql
```

Typical cost for a 1-day Solana window: **$0.50 – $2.00**. A 1-month window: **$5.00 – $15.00**.

### Base — Lower Cost

Base queries are significantly cheaper due to the smaller dataset size. A typical 1-day scan costs less than $0.30.

---

## Licensing

All data, queries, and documentation in this repository are published under the **CC-0 (Creative Commons Zero)** public domain dedication. You may use, modify, and redistribute any content without restriction or attribution.

---

## References

- [x402 Protocol — Official Site](https://www.x402.org/)
- [x402scan Explorer](https://www.x402scan.com/)
- [x402scan Open Source Repository](https://github.com/Merit-Systems/x402scan)
- [Google Cloud BigQuery — Solana Public Dataset](https://cloud.google.com/blog/products/data-analytics/solana-on-bigquery)
- [Coinbase CDP Analytics API](https://docs.cdp.coinbase.com/analytics/docs/welcome)
