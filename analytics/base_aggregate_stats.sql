-- =============================================================================
-- x402 Aggregate Analytics — Base Network
-- Mirrors the stats visible on https://x402scan.com
--
-- REQUIRES: Coinbase CDP Analytics API access for `base.events`
-- OR: pre-extracted base_x402_extract table from base/x402_extract.sql
--
-- If you have already run base/x402_extract.sql into a BQ table, replace
-- `base.events` references with your table: `your-project.google_web3.base_x402_extract`
-- =============================================================================

DECLARE START_DATE DATE DEFAULT '2025-12-16';
DECLARE END_DATE   DATE DEFAULT '2025-12-17';

-- Known Base facilitator addresses — COMPLETE registry
-- Source: github.com/Merit-Systems/x402scan/packages/external/facilitators
-- See base/x402_extract.sql for the full 100+ address INSERT block.
-- The aggregates below query the PRE-EXTRACTED table, so the facilitator
-- addresses are already baked into the data. This temp table is only needed
-- for Option B (direct CDP queries).
CREATE TEMP TABLE base_facilitators (address STRING, facilitator STRING);
-- NOTE: Insert the complete facilitator list from base/x402_extract.sql here
-- if running Option B (direct CDP queries). For Option A (pre-extracted table),
-- this temp table is unused — the extract already filtered by facilitator.

-- =============================================================================
-- BASE CTE: works against pre-extracted table or CDP base.events
-- If using the extracted table, change `base.events` → table reference below
-- =============================================================================
WITH base_transfers AS (
  -- OPTION A: Against pre-extracted table (recommended after running x402_extract.sql)
  SELECT
    tx_hash,
    block_timestamp,
    block_number,
    sender,
    recipient,
    amount_usdc,
    facilitator_address,
    facilitator_name,
    log_index
  FROM `YOUR_PROJECT.YOUR_DATASET.base_x402_extract`
  WHERE DATE(block_timestamp) BETWEEN START_DATE AND END_DATE

  -- OPTION B: Against CDP Analytics directly (requires CDP access)
  -- Uncomment the block below and comment out OPTION A
  /*
  SELECT
    e.transaction_hash    AS tx_hash,
    e.block_timestamp,
    e.block_number,
    e.parameters['from']::String                              AS sender,
    e.parameters['to']::String                               AS recipient,
    CAST(e.parameters['value']::UInt256 AS FLOAT64) / 1e6    AS amount_usdc,
    e.transaction_from                                        AS facilitator_address,
    f.facilitator                                             AS facilitator_name,
    e.log_index
  FROM base.events e
  JOIN base_facilitators f ON LOWER(e.transaction_from) = LOWER(f.address)
  WHERE DATE(e.block_timestamp) BETWEEN START_DATE AND END_DATE
    AND e.event_signature = 'Transfer(address,address,uint256)'
    AND LOWER(e.address) = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913'
  */
),

-- =============================================================================
-- AGGREGATE 1: Dashboard Summary
-- =============================================================================
summary AS (
  SELECT
    COUNT(*)                              AS total_transactions,
    ROUND(SUM(amount_usdc), 6)            AS total_volume_usdc,
    COUNT(DISTINCT sender)                AS unique_buyers,
    COUNT(DISTINCT recipient)             AS unique_sellers,
    COUNT(DISTINCT facilitator_address)   AS active_facilitators,
    MIN(block_timestamp)                  AS period_start,
    MAX(block_timestamp)                  AS period_end
  FROM base_transfers
),

-- =============================================================================
-- AGGREGATE 2: Per-Seller (Top Servers table)
-- =============================================================================
per_seller AS (
  SELECT
    recipient                             AS seller_address,
    COUNT(*)                              AS transaction_count,
    ROUND(SUM(amount_usdc), 6)            AS total_volume_usdc,
    COUNT(DISTINCT sender)                AS unique_buyers,
    MIN(facilitator_name)                 AS primary_facilitator,
    MIN(block_timestamp)                  AS first_seen,
    MAX(block_timestamp)                  AS last_seen
  FROM base_transfers
  GROUP BY recipient
  ORDER BY total_volume_usdc DESC
),

-- =============================================================================
-- AGGREGATE 3: Per-Facilitator
-- =============================================================================
per_facilitator AS (
  SELECT
    facilitator_address,
    facilitator_name,
    COUNT(*)                              AS transaction_count,
    ROUND(SUM(amount_usdc), 6)            AS total_volume_usdc,
    COUNT(DISTINCT sender)                AS unique_buyers,
    COUNT(DISTINCT recipient)             AS unique_sellers,
    MIN(block_timestamp)                  AS first_seen,
    MAX(block_timestamp)                  AS last_seen
  FROM base_transfers
  GROUP BY facilitator_address, facilitator_name
  ORDER BY total_volume_usdc DESC
),

-- =============================================================================
-- AGGREGATE 4: Hourly Activity Timeseries
-- =============================================================================
hourly_activity AS (
  SELECT
    TIMESTAMP_TRUNC(block_timestamp, HOUR) AS hour_bucket,
    COUNT(*)                               AS transaction_count,
    ROUND(SUM(amount_usdc), 6)             AS volume_usdc,
    COUNT(DISTINCT sender)                 AS unique_buyers
  FROM base_transfers
  GROUP BY hour_bucket
  ORDER BY hour_bucket ASC
),

-- =============================================================================
-- AGGREGATE 5: Top Buyers
-- =============================================================================
per_buyer AS (
  SELECT
    sender                                AS buyer_address,
    COUNT(*)                              AS transaction_count,
    ROUND(SUM(amount_usdc), 6)            AS total_spent_usdc,
    COUNT(DISTINCT recipient)             AS unique_sellers_paid,
    MIN(block_timestamp)                  AS first_payment,
    MAX(block_timestamp)                  AS last_payment
  FROM base_transfers
  GROUP BY sender
  ORDER BY total_spent_usdc DESC
)

-- Uncomment the view you want to run:
SELECT * FROM summary;
-- SELECT * FROM per_seller LIMIT 100;
-- SELECT * FROM per_facilitator;
-- SELECT * FROM hourly_activity;
-- SELECT * FROM per_buyer LIMIT 100;
