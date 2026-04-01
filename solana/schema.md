# x402 Solana Network Extraction Schema

## Table: `sol_x402_extract`

**Description:**  
Extracts USDC SPL token transfers from the Solana BigQuery public dataset where a known x402 facilitator wallet appears as a transaction signer. This is the canonical Solana x402 payment fingerprint.

**Data Source:** `bigquery-public-data.crypto_solana_mainnet_us`  
**Tables Used:** `Transactions`, `Token Transfers`, `Instructions`  
**Chain:** Solana Mainnet  
**Token:** USDC (`EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`)

---

## Why NOT `inst.parsed` JSON?

An earlier approach attempted to unnest `instructions` and parse JSON `inst.parsed` fields. This is incorrect for x402 extraction on Solana because:
1. The `bigquery-public-data.crypto_solana_mainnet_us` dataset provides a pre-decoded **`Token Transfers`** table — no JSON parsing needed.
2. x402's identifier is the **signer account** being a facilitator pubkey, joined from the `Transactions` table. The token movement itself is a standard USDC SPL transfer.

---

## Output Schema

| Column | Type | Description |
| :--- | :--- | :--- |
| `tx_signature` | `STRING` | The Solana transaction signature (base58) |
| `block_timestamp` | `TIMESTAMP` | Block timestamp (used for partitioning \u2014 always filter on this) |
| `token_mint` | `STRING` | USDC mint address (`EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`) |
| `source_ata` | `STRING` | Source Associated Token Account (ATA) \u2014 the buyer's USDC ATA |
| `destination_ata` | `STRING` | Destination ATA \u2014 the seller's USDC ATA |
| `amount_usdc` | `FLOAT64` | Transfer amount in human-readable USDC (raw value / 10^decimals) |
| `transaction_from` | `STRING` | Fee payer pubkey (first signer) |
| `facilitator_signer` | `STRING` | The matched x402 facilitator pubkey from the signer accounts list |
| `transfer_index` | `INTEGER` | Ordering index within the transaction (for deduplication) |
| `chain` | `STRING` | Always `solana` |

---

## Known Facilitator Pubkeys (Solana Mainnet)

| Facilitator | Pubkey | Active Since |
| :--- | :--- | :--- |
| coinbase | `L54zkaPQFeTn1UsEqieEXBqWrPShiaZEPD7mS5WXfQg` | 2025-10-24 |
| coinbase | `BENrLoUbndxoNMUS5JXApGMtNykLjFXXixMtpDwDR9SP` | 2025-12-16 |
| coinbase | `BFK9TLC3edb13K6v4YyH3DwPb5DSUpkWvb7XnqCL9b4F` | 2025-12-16 |
| coinbase | `D6ZhtNQ5nT9ZnTHUbqXZsTx5MH2rPFiBBggX4hY1WePM` | 2025-12-16 |
| coinbase | `GVJJ7rdGiXr5xaYbRwRbjfaJL7fmwRygFi1H6aGqDveb` | 2025-12-16 |
| coinbase | `Hc3sdEAsCGQcpgfivywog9uwtk8gUBUZgsxdME1EJy88` | 2025-12-16 |

> **Note:** Additional facilitators (e.g., Blockrun, SniperX) appear on x402scan but their Solana pubkeys are not yet published in the open-source repo. They can be added as they become known.

---

## Cost Warning

> **⚠️ CRITICAL:** The `crypto_solana_mainnet_us` dataset is one of the largest in BigQuery public data. The `block_timestamp` partition filter in the `signer_sigs` CTE is **mandatory**. Removing it will cause a full-table scan that may cost $5,000–$20,000 in a single query.
>
> Always run with `--dry_run` first to check estimated bytes scanned.
