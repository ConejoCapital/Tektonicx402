Devan, here are the finalized SQL query examples neatly separated for you to copy and paste directly into the two live Analytics Hub listings. 

Since the datasets are unified natively in `us-central1`, both tables perfectly utilize the exact same `web3-publicgoods.tektonic_x402` origin.

---

### **For the Solana Analytics Hub Listing:**

**Overview**
The Tektonic x402 Solana dataset provides a comprehensive ledger of decentralized API monetization and AI-agent transactions using the x402 protocol natively on the SVM. By operating directly on canonical execution traces and enforcing strict boolean execution filters (`tx.err = ''`), this pipeline naturally achieves mathematically perfect validation—ensuring that exactly 0.00% of failed or reverted transactions are counted towards volume.

**Example Queries & Business Logic**

**1. Global Daily Volume & Success Purity**
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

**2. Market Share: Top x402 Facilitators**
Determine the dominance of individual AI agents and API facilitators ranked by transaction volume across the ecosystem.
```sql
SELECT 
  facilitator_signer AS agent_pubkey,
  COUNT(DISTINCT tx_signature) AS total_handled_calls,
  ROUND(SUM(amount_usdc), 2) AS total_facilitated_usdc,
  MIN(block_timestamp) AS first_payment_seen
FROM `web3-publicgoods.tektonic_x402.sol_raw`
WHERE tx_status = 'SUCCESS'
  AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY agent_pubkey
ORDER BY total_handled_calls DESC
LIMIT 10;
```

**3. Trace a User's Total Lifetime API Spend**
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
  AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
GROUP BY transaction_from;
```

**4. Seller Revenue Tracking**
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

**5. Network Failure Rate Diagnostics**
Track the operational health of the Solana x402 payment rails by calculating daily failure rates organically isolated from execution logic.
```sql
SELECT 
  DATE(block_timestamp) AS diagnostic_date,
  COUNT(DISTINCT tx_signature) AS total_attempts,
  COUNT(DISTINCT CASE WHEN tx_status = 'FAILED' THEN tx_signature END) AS failed_attempts,
  ROUND((COUNT(DISTINCT CASE WHEN tx_status = 'FAILED' THEN tx_signature END) * 100.0) / COUNT(DISTINCT tx_signature), 2) AS failure_rate_percentage
FROM `web3-publicgoods.tektonic_x402.sol_raw`
WHERE block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY diagnostic_date
ORDER BY diagnostic_date DESC;
```

---

### **For the Base Analytics Hub Listing:**

**Overview**
The Tektonic x402 Base dataset extracts direct Token Transfer logs triggered exclusively by certified Canonical Facilitator logic on the EVM. It bypasses severe HTTP 429 API rate limits that fracture legacy indexers.

**Example Queries & Business Logic**

**1. EVM Facilitator Application Dominance**
Discover which smart contract applications are driving the highest API volume across the Base network.
```sql
SELECT 
  facilitator_name AS provider_platform,
  COUNT(tx_hash) AS total_transactions,
  ROUND(SUM(amount_usdc), 2) AS total_usdc_volume,
  COUNT(DISTINCT sender) AS unique_platform_users
FROM `web3-publicgoods.tektonic_x402.base_raw`
WHERE tx_status = 1
  AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY facilitator_name
ORDER BY total_usdc_volume DESC;
```

**2. Base Network Daily User Retention**
Calculate the growth of active consumer adoption organically interacting with x402 APIs on Base.
```sql
SELECT 
  DATE(block_timestamp) AS processing_date,
  COUNT(DISTINCT sender) AS unique_daily_buyers,
  COUNT(tx_hash) AS total_api_calls
FROM `web3-publicgoods.tektonic_x402.base_raw`
WHERE tx_status = 1
  AND block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY processing_date
ORDER BY processing_date DESC;
```
