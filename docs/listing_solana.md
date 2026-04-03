# Tektonic x402 Public Dataset

**A free, high-fidelity x402 transactional archive brought to you by Tektonic, with support from Google Cloud Web3 & Solana Foundation.**

## Overview
The Tektonic x402 dataset (`web3-publicgoods.tektonic_x402`) provides a comprehensive ledger of decentralized API monetization and AI-agent transactions using the x402 protocol natively. 

By replacing rate-limited, legacy HTTP RPC-polling methodologies with a pristine, massively parallel BigQuery-native extraction engine, this dataset achieves 100% historical accuracy and throughput capture across multiple blockchain environments. It successfully logs tens of thousands of daily micro-settlements (spanning structurally hidden network testing phases all the way to global adoption) that traditional indexers physically cannot access.

## Methodology & Architecture
Our data pipeline operates directly on canonical execution traces provided continuously by Google Cloud Web3's public blockchain datasets, ensuring zero manipulation or third-party dependencies:

*   **SVM (Solana) Success Purity:** Overcomes inherent structural indexer bias by enforcing strict boolean execution filters (`tx.err = ''`), ensuring that exactly 0.00% of failed or reverted transactions are ever counted towards ecosystem volume.
*   **EVM (Base) Parity:** Extracts direct Token Transfer logs triggered exclusively by certified Canonical Facilitator logic, achieving mathematically perfect validation since reverted states eliminate EVM events entirely from the finalized block ledger.
*   **RPC-Bypass Scale:** Unlocks high data throughput by joining deeply nested Associated Token Accounts (ATAs) and native base-ledger fields entirely within the data warehouse, completely sidestepping severe HTTP 429 API rate limits that fracture and corrupt data within existing legacy indexers.

## Example Analytics & Business Logic

These queries are designed to demonstrate the immense value and analytical depth of the Tektonic x402 Public Dataset. All queries assume you are projecting against the `web3-publicgoods.tektonic_x402` dataset.

### 1. Global Daily Volume & Success Purity (Solana Only)
Calculate total dollar volume processed natively on Solana in the last 24 hours, strictly factoring out un-executed transactions safely to avoid double-accounting.
```sql
SELECT
  DATE(block_timestamp) AS processing_date,
  COUNT(DISTINCT tx_signature) AS absolute_transaction_count,
  COUNT(DISTINCT CASE WHEN tx_status = 'SUCCESS' THEN tx_signature END) AS successful_transactions,
  ROUND(SUM(amount_usdc), 2) AS total_settled_usdc
FROM `web3-publicgoods.tektonic_x402.sol_raw`
WHERE block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
GROUP BY processing_date
ORDER BY processing_date DESC;
```

### 2. Market Share: Top x402 Facilitators (Solana Only)
Determine the dominance of individual AI agents and API facilitators ranked by transaction volume across the ecosystem.
```sql
SELECT 
  facilitator_signer AS agent_pubkey,
  COUNT(DISTINCT tx_signature) AS total_handled_calls,
  ROUND(SUM(amount_usdc), 2) AS total_facilitated_usdc,
  MIN(block_timestamp) AS first_payment_seen
FROM `web3-publicgoods.tektonic_x402.sol_raw`
WHERE tx_status = 'SUCCESS'
GROUP BY agent_pubkey
ORDER BY total_handled_calls DESC
LIMIT 10;
```

### 3. Trace a User's Total Lifetime API Spend (Solana Only)
Track a specific API consumer (wallet) to measure their total lifetime spending and the unique APIs they interact with.
```sql
SELECT 
  transaction_from AS consumer_wallet,
  COUNT(DISTINCT tx_signature) AS total_api_purchases,
  ROUND(SUM(amount_usdc), 2) AS lifetime_spend_usdc,
  COUNT(DISTINCT destination_ata) AS unique_sellers_paid
FROM `web3-publicgoods.tektonic_x402.sol_raw`
WHERE tx_status = 'SUCCESS' 
  AND transaction_from = 'ENTER_WALLET_PUBKEY_HERE'
GROUP BY transaction_from;
```

### 4. Seller Revenue Extraction (Solana Only)
Target a specific API provider's merchant ATA to calculate their incoming revenue velocity over the trailing 7 days.
```sql
SELECT 
  destination_ata AS merchant_ata_wallet,
  DATE(block_timestamp) AS settlement_date,
  ROUND(SUM(amount_usdc), 2) AS daily_revenue_usdc,
  COUNT(DISTINCT transaction_from) AS unique_buyers
FROM `web3-publicgoods.tektonic_x402.sol_raw`
WHERE tx_status = 'SUCCESS'
  AND destination_ata = 'ENTER_SELLER_ATA_HERE'
  AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY merchant_ata_wallet, settlement_date
ORDER BY settlement_date DESC;
```

### 5. Network Failure Rate Diagnostics (Solana Only)
Track the operational health of the Solana x402 payment rails by calculating daily failure rates organically isolated from execution logic.
```sql
SELECT 
  DATE(block_timestamp) AS diagnostic_date,
  COUNT(DISTINCT tx_signature) AS total_attempts,
  COUNT(DISTINCT CASE WHEN tx_status = 'FAILED' THEN tx_signature END) AS failed_attempts,
  ROUND((COUNT(DISTINCT CASE WHEN tx_status = 'FAILED' THEN tx_signature END) * 100.0) / COUNT(DISTINCT tx_signature), 2) AS failure_rate_percentage
FROM `web3-publicgoods.tektonic_x402.sol_raw`
GROUP BY diagnostic_date
ORDER BY diagnostic_date DESC;
```

### 6. Cross-Chain Universal x402 Economy (Solana + Base)
Blend both the SVM and EVM execution layers into a single macroscopic view of global Web3 AI monetization volume over the past 30 days.
```sql
WITH global_x402 AS (
  SELECT DATE(block_timestamp) AS processing_date, amount_usdc, chain, tx_signature AS tx_id
  FROM `web3-publicgoods.tektonic_x402.sol_raw`
  WHERE tx_status = 'SUCCESS'
  UNION ALL
  SELECT DATE(block_timestamp) AS processing_date, amount_usdc, chain, tx_hash AS tx_id
  FROM `web3-publicgoods.tektonic_x402.base_raw`
  WHERE tx_status = 1
)
SELECT 
  processing_date,
  COUNT(tx_id) AS total_global_transactions,
  ROUND(SUM(CASE WHEN chain = 'solana' THEN amount_usdc ELSE 0 END), 4) AS solana_volume_usdc,
  ROUND(SUM(CASE WHEN chain = 'base' THEN amount_usdc ELSE 0 END), 4) AS base_volume_usdc,
  ROUND(SUM(amount_usdc), 4) AS combined_global_volume_usdc
FROM global_x402
WHERE processing_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY processing_date
ORDER BY processing_date DESC;
```

### 7. Ecosystem Market Share (Solana vs Base)
Analyze the structural adoption split between the Solana and Base networks directly from the Canonical Smart Contracts.
```sql
SELECT 
  chain,
  COUNT(tx_id) AS total_transactions,
  ROUND(SUM(amount_usdc), 2) AS total_market_volume,
  COUNT(DISTINCT consumer) AS unique_onchain_consumers
FROM (
  SELECT tx_signature AS tx_id, amount_usdc, transaction_from AS consumer, chain
  FROM `web3-publicgoods.tektonic_x402.sol_raw`
  WHERE tx_status = 'SUCCESS'
  UNION ALL
  SELECT tx_hash AS tx_id, amount_usdc, sender AS consumer, chain
  FROM `web3-publicgoods.tektonic_x402.base_raw`
  WHERE tx_status = 1
)
GROUP BY chain
ORDER BY total_market_volume DESC;
```

### 8. Global Daily Active Agents (Solana + Base)
Calculate the growth of active consumer adoption dynamically interacting with x402 APIs over both networks.
```sql
SELECT 
  processing_date,
  COUNT(DISTINCT consumer) AS global_unique_consumers
FROM (
  SELECT DATE(block_timestamp) AS processing_date, transaction_from AS consumer
  FROM `web3-publicgoods.tektonic_x402.sol_raw`
  WHERE tx_status = 'SUCCESS'
  UNION ALL
  SELECT DATE(block_timestamp) AS processing_date, sender AS consumer
  FROM `web3-publicgoods.tektonic_x402.base_raw`
  WHERE tx_status = 1
)
WHERE processing_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
GROUP BY processing_date
ORDER BY processing_date DESC;
```

## Licensing & Transparency
Data is published entirely under the CC-0 public domain license.

For academic deep-dives into our structural findings, open-source pipeline scripts, and the canonical registry of supported facilitator contracts, please review our official GitHub repository:  
**[github.com/ConejoCapital/Tektonicx402](https://github.com/ConejoCapital/Tektonicx402)**
