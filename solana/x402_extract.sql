-- =============================================================================
-- x402 Payment Extraction: Solana Network
-- Google Cloud BigQuery: bigquery-public-data.crypto_solana_mainnet_us
--
-- HOW x402 WORKS ON SOLANA:
--   1. A client signs an SPL Token transfer authorization off-chain.
--   2. The x402 facilitator wallet is the fee payer and signer on the transaction.
--   3. The USDC SPL token is transferred from the user ATA to the seller ATA.
--   4. The x402 fingerprint: a token transfer on USDC mint WHERE a known
--      facilitator pubkey appears as a SIGNER account on the transaction.
--
-- DATASET:  bigquery-public-data.crypto_solana_mainnet_us
--   Tables: `Transactions`   (partitioned on block_timestamp)
--           `Token Transfers` (partitioned on block_timestamp)
--           `Instructions`   (partitioned on block_timestamp)
--
-- !! CRITICAL COST WARNING !!
--   The Solana dataset is enormous. A single unpartitioned query can scan
--   100TB+ and generate a $5,000-$20,000 BigQuery bill.
--   You MUST keep the `block_timestamp` filter in the top-level CTE (signer_sigs).
--   NEVER remove the partition predicate, even when using LIMIT.
--
-- USDC on Solana mint: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
-- =============================================================================

DECLARE START_DATE DATE DEFAULT CURRENT_DATE() - 1;
DECLARE END_DATE   DATE DEFAULT CURRENT_DATE();

-- Convert dates to timestamps for the partition filter
DECLARE start_ts TIMESTAMP DEFAULT TIMESTAMP(START_DATE);
DECLARE end_ts   TIMESTAMP DEFAULT TIMESTAMP(END_DATE);

-- ---------------------------------------------------------------------------
-- Known x402 facilitator signer pubkeys on Solana.
-- Sourced from: github.com/Merit-Systems/x402scan/packages/external/facilitators
-- ---------------------------------------------------------------------------
DECLARE facilitator_pubkeys ARRAY<STRING> DEFAULT [
  -- Complete list from x402scan canonical registry (22 pubkeys)
  -- Last synced: 2026-03-30

  -- AnySpend
  '34DmdeSbEnng2bmbSj9ActckY49km2HdhiyAwyXZucqP',
  -- AurraCloud
  '8x8CzkTHTYkW18frrTR7HdCV6fsjenvcykJAXWvoPQW',
  -- Bitrefill
  'PcTZWki36z5Y82TAATKK48XUdfsgmS5oLkw2Ta7vWyK',
  -- Cascade
  '7NetKx8TuRMBpqYFKZCVetkNuvWCPTrgekmGrsJwTmfN',
  -- CodeNut
  'HsozMJWWHNADoZRmhDGKzua6XW6NNfNDdQ4CkE9i5wHt',
  -- Coinbase Developer Platform
  'L54zkaPQFeTn1UsEqieEXBqWrPShiaZEPD7mS5WXfQg',
  'BENrLoUbndxoNMUS5JXApGMtNykLjFXXixMtpDwDR9SP',
  'BFK9TLC3edb13K6v4YyH3DwPb5DSUpkWvb7XnqCL9b4F',
  'D6ZhtNQ5nT9ZnTHUbqXZsTx5MH2rPFiBBggX4hY1WePM',
  'GVJJ7rdGiXr5xaYbRwRbjfaJL7fmwRygFi1H6aGqDveb',
  'Hc3sdEAsCGQcpgfivywog9uwtk8gUBUZgsxdME1EJy88',
  -- Corbits
  'AepWpq3GQwL8CeKMtZyKtKPa7W91Coygh3ropAJapVdU',
  -- Daydreams
  'DuQ4jFMmVABWGxabYHFkGzdyeJgS1hp4wrRuCtsJgT9a',
  -- Dexter
  'DEXVS3su4dZQWTvvPnLDJLRK1CeeKG6K3QqdzthgAkNV',
  -- OpenFacilitator
  'Hbe1vdFs4EQVVAzcV12muHhr6DEKwrT9roMXGPLxLBLP',
  -- OpenX402
  '5xvht4fYDs99yprfm4UeuHSLxMBRpotfBtUCQqM3oDNG',
  -- PayAI
  '2wKupLR9q6wXYppw8Gr2NvWxKBUqm4PPJKkQfoxHDBg4',
  'CjNFTjvBhbJJd2B5ePPMHRLx1ELZpa8dwQgGL727eKww',
  '8B5UKhwfAyFW67h58cBkQj1Ur6QXRgwWJJcQp8ZBsDPa',
  -- RelAI
  '4x4ZhcqiT1FnirM8Ne97iVupkN4NcQgc2YYbE2jDZbZn',
  -- Ultravioleta DAO
  'F742C4VfFLQ9zRQyithoj5229ZgtX2WqKCSFKgH2EThq',
  -- x402 Jobs
  '561oabzy81vXYYbs1ZHR1bvpiEr6Nbfd6PGTxPshoz4p'
];

DECLARE usdc_mint STRING DEFAULT 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

-- =============================================================================
-- MAIN QUERY
-- =============================================================================
-- Replace YOUR_PROJECT and YOUR_DATASET with your GCP project and dataset names.
CREATE OR REPLACE TABLE `YOUR_PROJECT.YOUR_DATASET.sol_x402_extract` AS

-- ---------------------------------------------------------------------------
-- STEP 1: Find all transaction signatures where a known x402 facilitator
--         wallet appears as a signer account.
--         PARTITION FILTER IS MANDATORY HERE -- this is the gate.
-- ---------------------------------------------------------------------------
WITH signer_sigs AS (
  SELECT DISTINCT
    tx.signature,
    CASE WHEN tx.err = '' THEN 'SUCCESS' ELSE 'FAILED' END AS tx_status,
    -- The first signer is typically the fee payer (facilitator)
    (
      SELECT a.pubkey
      FROM UNNEST(tx.accounts) AS a WITH OFFSET AS idx
      WHERE a.signer = TRUE
      ORDER BY idx
      LIMIT 1
    ) AS fee_payer,
    -- Identify which specific facilitator wallet signed this tx
    (
      SELECT a.pubkey
      FROM UNNEST(tx.accounts) AS a
      WHERE a.signer = TRUE AND a.pubkey IN UNNEST(facilitator_pubkeys)
      LIMIT 1
    ) AS matched_facilitator_signer
  FROM `bigquery-public-data.crypto_solana_mainnet_us.Transactions` AS tx
  WHERE
    tx.block_timestamp >= start_ts AND tx.block_timestamp < end_ts
    -- We removed tx.err = '' to capture ALL transactions intentionally,
    -- allowing analysts to filter off tx_status DOWNSTREAM.
    AND EXISTS (
      SELECT 1 FROM UNNEST(tx.accounts) AS a
      WHERE a.signer = TRUE AND a.pubkey IN UNNEST(facilitator_pubkeys)
    )
),

-- ---------------------------------------------------------------------------
-- STEP 2: Join to Token Transfers and filter on USDC mint.
-- ---------------------------------------------------------------------------
enriched AS (
  SELECT
    t.tx_signature,
    t.block_timestamp,
    s.tx_status,
    t.mint                                            AS token_mint,
    t.source                                          AS source_ata,
    t.destination                                     AS destination_ata,
    -- Zero out the volume if the transaction failed on-chain to prevent double-counting
    CASE WHEN s.tx_status = 'SUCCESS' THEN SAFE_DIVIDE(t.value, POW(10, t.decimals)) ELSE 0 END AS amount_usdc,
    s.fee_payer                                       AS transaction_from,
    s.matched_facilitator_signer                      AS facilitator_signer,
    ROW_NUMBER() OVER (
      PARTITION BY t.tx_signature
      ORDER BY t.block_timestamp, t.source, t.destination, t.value
    ) - 1 AS transfer_index,
    'solana' AS chain
  FROM `bigquery-public-data.crypto_solana_mainnet_us.Token Transfers` AS t
  JOIN signer_sigs AS s ON t.tx_signature = s.signature
  WHERE
    -- !! PARTITION PREDICATE ON TOKEN TRANSFERS -- DO NOT REMOVE !!
    -- NOTE: We use ±1 hour buffer because Token Transfers and Transactions
    -- can have slight block_timestamp discrepancies for the same tx_signature.
    -- The signer JOIN already limits results to facilitator-signed txs only.
    t.block_timestamp >= TIMESTAMP_SUB(start_ts, INTERVAL 1 HOUR)
    AND t.block_timestamp < TIMESTAMP_ADD(end_ts, INTERVAL 1 HOUR)
    -- Filter to USDC only
    AND t.mint = usdc_mint
    AND t.value IS NOT NULL
    AND t.decimals IS NOT NULL
)

SELECT *
FROM enriched
ORDER BY block_timestamp DESC;
