# Tektonic x402 Public Dataset (Solana & Base)

**A free, high-fidelity x402 transactional archive brought to you by Tektonic, with support from Google Cloud Web3 & Solana Foundation.**

## Overview
The Tektonic x402 dataset provides a comprehensive ledger of decentralized API monetization and AI-agent transactions using the x402 protocol natively. 

By replacing rate-limited, legacy HTTP RPC-polling methodologies with a pristine, massively parallel BigQuery-native extraction engine, this dataset achieves 100% historical accuracy and throughput capture across multiple blockchain environments (SVM and EVM). It successfully logs tens of thousands of daily micro-settlements (spanning structurally hidden network testing phases all the way to global adoption) that traditional indexers physically cannot access.

**Tektonic** is co-founded by Mauricio Jean Pieer Trujillo Ramirez aka Bunny - [https://x.com/ConejoCapital](https://x.com/ConejoCapital) and Tomas Del Manzo Oliver aka Tomi - [https://x.com/Tomi204_](https://x.com/Tomi204_). You can find out more about Tektonic at https://tektonic.company/

## Methodology & Architecture
Our data pipeline operates directly on canonical execution traces provided continuously by Google Cloud Web3's public blockchain datasets, ensuring zero manipulation or third-party dependencies:

*   **Purity & Validation:** Overcomes inherent structural indexer bias by enforcing strict blockchain execution filters (e.g., `tx.err = ''` on Solana and `status = 1` on Base). This ensures that exactly 0.00% of failed or reverted transactions are ever wrongfully counted towards ecosystem volume.
*   **RPC-Bypass Scale:** Unlocks high data throughput by joining deeply nested Associated Token Accounts (ATAs) and native base-ledger fields entirely within the data warehouse, completely sidestepping severe HTTP 429 API rate limits that fracture and corrupt data within existing legacy indexers.

## Getting Started
1. Subscribe to the dataset through BigQuery Sharing.
2. Save into your GCP project, and assign a local name to the dataset (e.g. `tektonic_x402`).
3. Replace `<YOUR-GCP-PROJECT-ID>` in the queries below with your actual Google Cloud Project ID and try the example code to analyze the global Web3 AI economy!

---

## Example Analytics & Business Logic

### 1. Global Daily Volume & Success Purity (Solana)
Calculate total dollar volume processed natively on Solana in the last 24 hours, strictly factoring out un-executed transactions safely to avoid double-accounting.
```sql
SELECT
  DATE(block_timestamp) AS processing_date,
  COUNT(DISTINCT tx_signature) AS absolute_transaction_count,
  COUNT(DISTINCT CASE WHEN tx_status = 'SUCCESS' THEN tx_signature END) AS successful_transactions,
  ROUND(SUM(amount_usdc), 2) AS total_settled_usdc
FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.sol_raw`
WHERE block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
GROUP BY processing_date
ORDER BY processing_date DESC;
```

### 2. Market Share: Top x402 Facilitators (Solana)
Determine the dominance of individual AI agents and API facilitators ranked by transaction volume across the ecosystem.
```sql
SELECT 
  facilitator_signer AS agent_pubkey,
  COUNT(DISTINCT tx_signature) AS total_handled_calls,
  ROUND(SUM(amount_usdc), 2) AS total_facilitated_usdc,
  MIN(block_timestamp) AS first_payment_seen
FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.sol_raw`
WHERE tx_status = 'SUCCESS'
GROUP BY agent_pubkey
ORDER BY total_handled_calls DESC
LIMIT 10;
```

### 3. Trace a User's Total Lifetime API Spend (Solana)
Track a specific API consumer (wallet) to measure their total lifetime spending and the unique APIs they interact with.
```sql
SELECT 
  transaction_from AS consumer_wallet,
  COUNT(DISTINCT tx_signature) AS total_api_purchases,
  ROUND(SUM(amount_usdc), 2) AS lifetime_spend_usdc,
  COUNT(DISTINCT destination_ata) AS unique_sellers_paid
FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.sol_raw`
WHERE tx_status = 'SUCCESS' 
  AND transaction_from = 'ENTER_WALLET_PUBKEY_HERE'
GROUP BY transaction_from;
```

### 4. Seller Revenue Tracking (Solana)
Target a specific API provider's merchant ATA to calculate their incoming revenue velocity over the trailing 7 days.
```sql
SELECT 
  destination_ata AS merchant_ata_wallet,
  DATE(block_timestamp) AS settlement_date,
  ROUND(SUM(amount_usdc), 2) AS daily_revenue_usdc,
  COUNT(DISTINCT transaction_from) AS unique_buyers
FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.sol_raw`
WHERE tx_status = 'SUCCESS'
  AND destination_ata = 'ENTER_SELLER_ATA_HERE'
  AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY merchant_ata_wallet, settlement_date
ORDER BY settlement_date DESC;
```

### 5. EVM Facilitator Application Dominance (Base)
Discover which smart contract applications are driving the highest API volume across the Base EVM network.
```sql
SELECT 
  facilitator_name AS provider_platform,
  COUNT(tx_hash) AS total_transactions,
  ROUND(SUM(amount_usdc), 2) AS total_usdc_volume,
  COUNT(DISTINCT sender) AS unique_platform_users
FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.base_raw`
WHERE tx_status = 1
GROUP BY facilitator_name
ORDER BY total_usdc_volume DESC;
```

### 6. Base Network Daily User Retention (Base)
Calculate the growth of active consumer adoption organically interacting with x402 APIs on Base.
```sql
SELECT 
  DATE(block_timestamp) AS processing_date,
  COUNT(DISTINCT sender) AS unique_daily_buyers,
  COUNT(tx_hash) AS total_api_calls
FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.base_raw`
WHERE tx_status = 1
GROUP BY processing_date
ORDER BY processing_date DESC;
```

### 7. Ecosystem Market Share (Solana vs Base)
Analyze the structural adoption split comparing the Solana and Base networks directly from Canonical Smart Contracts.
```sql
SELECT 
  chain,
  COUNT(tx_id) AS total_transactions,
  ROUND(SUM(amount_usdc), 2) AS total_market_volume,
  COUNT(DISTINCT consumer) AS unique_onchain_consumers
FROM (
  SELECT tx_signature AS tx_id, amount_usdc, transaction_from AS consumer, chain
  FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.sol_raw`
  WHERE tx_status = 'SUCCESS'
  UNION ALL
  SELECT tx_hash AS tx_id, amount_usdc, sender AS consumer, chain
  FROM `<YOUR-GCP-PROJECT-ID>.tektonic_x402.base_raw`
  WHERE tx_status = 1
)
GROUP BY chain
ORDER BY total_market_volume DESC;
```

## Licensing & Transparency
Data is published entirely under the CC-0 public domain license.

For academic deep-dives into our structural findings, open-source pipeline scripts, and the canonical registry of supported facilitator contracts, please review our official GitHub repository:  
**[github.com/ConejoCapital/Tektonicx402](https://github.com/ConejoCapital/Tektonicx402)**
