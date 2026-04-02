# Example Queries & Business Logic 

These queries are designed to demonstrate the immense value and analytical depth of the Tektonic x402 Public Dataset. All queries assume you are projecting against the `web3-publicgoods.tektonic_x402` dataset.

### 1. Global Daily Volume & Success Purity
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

### 2. Market Share: Top x402 Facilitators
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

### 3. Trace a User's Total Lifetime API Spend
Track a specific API consumer (wallet) to measure their total lifetime spending and the unique APIs they interact with. Replace the `transaction_from` placeholder with a valid Solana wallet.

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

### 4. Seller Revenue Extraction
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

### 5. Network Failure Rate Diagnostics
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
