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

### 1. EVM Facilitator Application Dominance (Base Only)
Discover which smart contract applications are driving the highest API volume across the Base network.
```sql
SELECT 
  facilitator_name AS provider_platform,
  COUNT(tx_hash) AS total_transactions,
  ROUND(SUM(amount_usdc), 2) AS total_usdc_volume,
  COUNT(DISTINCT sender) AS unique_platform_users
FROM `web3-publicgoods.tektonic_x402.base_raw`
WHERE tx_status = 1
GROUP BY facilitator_name
ORDER BY total_usdc_volume DESC;
```

### 2. Base Network Daily User Retention (Base Only)
Calculate the growth of active consumer adoption organically interacting with x402 APIs on Base.
```sql
SELECT 
  DATE(block_timestamp) AS processing_date,
  COUNT(DISTINCT sender) AS unique_daily_buyers,
  COUNT(tx_hash) AS total_api_calls
FROM `web3-publicgoods.tektonic_x402.base_raw`
WHERE tx_status = 1
GROUP BY processing_date
ORDER BY processing_date DESC;
```

### 3. Active Canonical Protocols (Base Only)
Count the active AI agent facilitators organically settling APIs utilizing the canonical x402 contracts over EVM.
```sql
SELECT 
  facilitator_name AS protocol,
  COUNT(DISTINCT sender) AS unique_consumers,
  COUNT(tx_hash) AS transaction_count
FROM `web3-publicgoods.tektonic_x402.base_raw`
WHERE tx_status = 1
GROUP BY protocol
ORDER BY unique_consumers DESC;
```

### 4. Base Top Premium Consumers (Base Only)
Find out exactly which EVM wallets are spending the highest total volume across decentralized enterprise infrastructure.
```sql
SELECT 
  sender AS api_consumer,
  ROUND(SUM(amount_usdc), 2) AS total_usdc_invested,
  COUNT(DISTINCT facilitator_name) AS unique_protocols_used
FROM `web3-publicgoods.tektonic_x402.base_raw`
WHERE tx_status = 1
GROUP BY api_consumer
ORDER BY total_usdc_invested DESC
LIMIT 5;
```

### 5. Base API Revenue Heatmap (Base Only)
Calculate the 14-day aggregated revenue streams mapped natively to specific facilitator deployments on Base.
```sql
SELECT 
  DATE(block_timestamp) AS active_date,
  facilitator_name,
  ROUND(SUM(amount_usdc), 2) AS daily_revenue
FROM `web3-publicgoods.tektonic_x402.base_raw`
WHERE tx_status = 1
  AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
GROUP BY active_date, facilitator_name
ORDER BY active_date DESC, daily_revenue DESC;
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
