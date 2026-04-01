-- =============================================================================
-- x402 Aggregate Analytics Queries
-- Mirrors the stats visible on https://x402scan.com
--
-- RUN THESE AGAINST THE EXTRACTED TABLES:
--   bigquery-public-data.crypto_solana_mainnet_us  (Solana raw)
--   OR your extracted tables after running x402_extract.sql
--
-- All queries below work directly on the public Solana dataset
-- without needing a pre-built extract table, using the same
-- signer + mint filter pattern. Parameterize START/END dates.
-- =============================================================================

DECLARE START_DATE DATE DEFAULT '2025-12-16';
DECLARE END_DATE   DATE DEFAULT '2025-12-17';
DECLARE start_ts   TIMESTAMP DEFAULT TIMESTAMP(START_DATE);
DECLARE end_ts     TIMESTAMP DEFAULT TIMESTAMP(END_DATE);

DECLARE facilitator_pubkeys ARRAY<STRING> DEFAULT [
  -- Complete list from x402scan canonical registry (22 pubkeys)
  -- Last synced: 2026-03-30
  '34DmdeSbEnng2bmbSj9ActckY49km2HdhiyAwyXZucqP',  -- AnySpend
  '8x8CzkTHTYkW18frrTR7HdCV6fsjenvcykJAXWvoPQW',  -- AurraCloud
  'PcTZWki36z5Y82TAATKK48XUdfsgmS5oLkw2Ta7vWyK',  -- Bitrefill
  '7NetKx8TuRMBpqYFKZCVetkNuvWCPTrgekmGrsJwTmfN', -- Cascade
  'HsozMJWWHNADoZRmhDGKzua6XW6NNfNDdQ4CkE9i5wHt', -- CodeNut
  'L54zkaPQFeTn1UsEqieEXBqWrPShiaZEPD7mS5WXfQg',  -- Coinbase
  'BENrLoUbndxoNMUS5JXApGMtNykLjFXXixMtpDwDR9SP', -- Coinbase
  'BFK9TLC3edb13K6v4YyH3DwPb5DSUpkWvb7XnqCL9b4F', -- Coinbase
  'D6ZhtNQ5nT9ZnTHUbqXZsTx5MH2rPFiBBggX4hY1WePM', -- Coinbase
  'GVJJ7rdGiXr5xaYbRwRbjfaJL7fmwRygFi1H6aGqDveb', -- Coinbase
  'Hc3sdEAsCGQcpgfivywog9uwtk8gUBUZgsxdME1EJy88', -- Coinbase
  'AepWpq3GQwL8CeKMtZyKtKPa7W91Coygh3ropAJapVdU', -- Corbits
  'DuQ4jFMmVABWGxabYHFkGzdyeJgS1hp4wrRuCtsJgT9a', -- Daydreams
  'DEXVS3su4dZQWTvvPnLDJLRK1CeeKG6K3QqdzthgAkNV', -- Dexter
  'Hbe1vdFs4EQVVAzcV12muHhr6DEKwrT9roMXGPLxLBLP', -- OpenFacilitator
  '5xvht4fYDs99yprfm4UeuHSLxMBRpotfBtUCQqM3oDNG', -- OpenX402
  '2wKupLR9q6wXYppw8Gr2NvWxKBUqm4PPJKkQfoxHDBg4', -- PayAI
  'CjNFTjvBhbJJd2B5ePPMHRLx1ELZpa8dwQgGL727eKww', -- PayAI
  '8B5UKhwfAyFW67h58cBkQj1Ur6QXRgwWJJcQp8ZBsDPa', -- PayAI
  '4x4ZhcqiT1FnirM8Ne97iVupkN4NcQgc2YYbE2jDZbZn', -- RelAI
  'F742C4VfFLQ9zRQyithoj5229ZgtX2WqKCSFKgH2EThq', -- Ultravioleta DAO
  '561oabzy81vXYYbs1ZHR1bvpiEr6Nbfd6PGTxPshoz4p'  -- x402 Jobs
];

DECLARE usdc_mint STRING DEFAULT 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

-- =============================================================================
-- BASE CTE: reusable x402 transfers within the time window
-- (same signer-join pattern as x402_extract.sql)
-- =============================================================================
WITH signer_sigs AS (
  SELECT DISTINCT
    tx.signature,
    (SELECT a.pubkey FROM UNNEST(tx.accounts) a WITH OFFSET idx
     WHERE a.signer = TRUE ORDER BY idx LIMIT 1)       AS fee_payer,
    (SELECT a.pubkey FROM UNNEST(tx.accounts) a
     WHERE a.signer = TRUE AND a.pubkey IN UNNEST(facilitator_pubkeys)
     LIMIT 1)                                          AS facilitator_signer
  FROM `bigquery-public-data.crypto_solana_mainnet_us.Transactions` tx
  WHERE tx.block_timestamp >= start_ts AND tx.block_timestamp < end_ts
    AND EXISTS (
      SELECT 1 FROM UNNEST(tx.accounts) a
      WHERE a.signer = TRUE AND a.pubkey IN UNNEST(facilitator_pubkeys)
    )
),
base_transfers AS (
  SELECT
    t.tx_signature,
    t.block_timestamp,
    t.source   AS source_ata,
    t.destination AS destination_ata,
    SAFE_DIVIDE(t.value, POW(10, t.decimals)) AS amount_usdc,
    s.fee_payer,
    s.facilitator_signer
  FROM `bigquery-public-data.crypto_solana_mainnet_us.Token Transfers` t
  JOIN signer_sigs s ON t.tx_signature = s.signature
  WHERE t.block_timestamp >= start_ts AND t.block_timestamp < end_ts
    AND t.mint = usdc_mint
    AND t.value IS NOT NULL AND t.decimals IS NOT NULL
),

-- =============================================================================
-- AGGREGATE 1: Dashboard Summary (mirrors x402scan Overview stats)
-- =============================================================================
summary AS (
  SELECT
    COUNT(*)                                   AS total_transactions,
    ROUND(SUM(amount_usdc), 6)                 AS total_volume_usdc,
    COUNT(DISTINCT source_ata)                 AS unique_buyers,
    COUNT(DISTINCT destination_ata)            AS unique_sellers,
    COUNT(DISTINCT facilitator_signer)         AS active_facilitators,
    MIN(block_timestamp)                       AS period_start,
    MAX(block_timestamp)                       AS period_end
  FROM base_transfers
),

-- =============================================================================
-- AGGREGATE 2: Volume & Activity Per Seller (mirrors "Top Servers" table)
-- Sellers = destination ATAs = the merchant / API provider wallets
-- =============================================================================
per_seller AS (
  SELECT
    destination_ata                            AS seller_ata,
    COUNT(*)                                   AS transaction_count,
    ROUND(SUM(amount_usdc), 6)                 AS total_volume_usdc,
    COUNT(DISTINCT source_ata)                 AS unique_buyers,
    MIN(block_timestamp)                       AS first_seen,
    MAX(block_timestamp)                       AS last_seen,
    facilitator_signer                         AS facilitator
  FROM base_transfers
  GROUP BY destination_ata, facilitator_signer
  ORDER BY total_volume_usdc DESC
),

-- =============================================================================
-- AGGREGATE 3: Facilitator Summary (mirrors the Facilitators tab)
-- =============================================================================
per_facilitator AS (
  SELECT
    facilitator_signer,
    COUNT(*)                                   AS transaction_count,
    ROUND(SUM(amount_usdc), 6)                 AS total_volume_usdc,
    COUNT(DISTINCT source_ata)                 AS unique_buyers,
    COUNT(DISTINCT destination_ata)            AS unique_sellers,
    MIN(block_timestamp)                       AS first_seen,
    MAX(block_timestamp)                       AS last_seen
  FROM base_transfers
  GROUP BY facilitator_signer
  ORDER BY total_volume_usdc DESC
),

-- =============================================================================
-- AGGREGATE 4: Hourly Activity Timeseries (powers sparkline / activity charts)
-- =============================================================================
hourly_activity AS (
  SELECT
    TIMESTAMP_TRUNC(block_timestamp, HOUR)     AS hour_bucket,
    COUNT(*)                                   AS transaction_count,
    ROUND(SUM(amount_usdc), 6)                 AS volume_usdc,
    COUNT(DISTINCT source_ata)                 AS unique_buyers
  FROM base_transfers
  GROUP BY hour_bucket
  ORDER BY hour_bucket ASC
),

-- =============================================================================
-- AGGREGATE 5: Buyer Activity (top spenders)
-- =============================================================================
per_buyer AS (
  SELECT
    source_ata                                 AS buyer_ata,
    COUNT(*)                                   AS transaction_count,
    ROUND(SUM(amount_usdc), 6)                 AS total_spent_usdc,
    COUNT(DISTINCT destination_ata)            AS unique_sellers_paid,
    MIN(block_timestamp)                       AS first_payment,
    MAX(block_timestamp)                       AS last_payment
  FROM base_transfers
  GROUP BY source_ata
  ORDER BY total_spent_usdc DESC
)

-- =============================================================================
-- OUTPUT: Select which aggregate to return (uncomment the one you want,
-- or run each as a separate query / save each to its own BQ table)
-- =============================================================================

-- 1. Dashboard summary:
SELECT * FROM summary;

-- 2. Top sellers (uncomment to use):
-- SELECT * FROM per_seller LIMIT 100;

-- 3. Facilitator breakdown (uncomment to use):
-- SELECT * FROM per_facilitator;

-- 4. Hourly activity chart data (uncomment to use):
-- SELECT * FROM hourly_activity;

-- 5. Top buyers (uncomment to use):
-- SELECT * FROM per_buyer LIMIT 100;
