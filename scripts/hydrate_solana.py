import subprocess
import datetime

# BigQuery Table creation query
create_table_sql = """
CREATE TABLE IF NOT EXISTS `web3-publicgoods.tektonic_x402.sol_raw` (
    tx_signature STRING,
    block_timestamp TIMESTAMP,
    tx_status STRING,
    token_mint STRING,
    source_ata STRING,
    destination_ata STRING,
    amount_usdc FLOAT64,
    transaction_from STRING,
    facilitator_signer STRING,
    transfer_index INT64,
    chain STRING
)
PARTITION BY DATE(block_timestamp)
OPTIONS(
  description="Historical x402 extraction for Solana Mainnet"
);
"""

insert_chunk_sql_template = """
DECLARE start_ts TIMESTAMP DEFAULT TIMESTAMP('{start_time}');
DECLARE end_ts   TIMESTAMP DEFAULT TIMESTAMP('{end_time}');
DECLARE usdc_mint STRING DEFAULT 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

INSERT INTO `web3-publicgoods.tektonic_x402.sol_raw`
WITH signer_sigs AS (
  SELECT DISTINCT
    tx.signature,
    CASE WHEN tx.err = '' THEN 'SUCCESS' ELSE 'FAILED' END AS tx_status,
    (
      SELECT a.pubkey
      FROM UNNEST(tx.accounts) AS a WITH OFFSET AS idx
      WHERE a.signer = TRUE
      ORDER BY idx
      LIMIT 1
    ) AS fee_payer,
    (
      SELECT a.pubkey
      FROM UNNEST(tx.accounts) AS a
      WHERE a.signer = TRUE AND a.pubkey IN (
        '34DmdeSbEnng2bmbSj9ActckY49km2HdhiyAwyXZucqP', '8x8CzkTHTYkW18frrTR7HdCV6fsjenvcykJAXWvoPQW',
        'PcTZWki36z5Y82TAATKK48XUdfsgmS5oLkw2Ta7vWyK', '7NetKx8TuRMBpqYFKZCVetkNuvWCPTrgekmGrsJwTmfN',
        'HsozMJWWHNADoZRmhDGKzua6XW6NNfNDdQ4CkE9i5wHt', 'L54zkaPQFeTn1UsEqieEXBqWrPShiaZEPD7mS5WXfQg',
        'BENrLoUbndxoNMUS5JXApGMtNykLjFXXixMtpDwDR9SP', 'BFK9TLC3edb13K6v4YyH3DwPb5DSUpkWvb7XnqCL9b4F',
        'D6ZhtNQ5nT9ZnTHUbqXZsTx5MH2rPFiBBggX4hY1WePM', 'GVJJ7rdGiXr5xaYbRwRbjfaJL7fmwRygFi1H6aGqDveb',
        'Hc3sdEAsCGQcpgfivywog9uwtk8gUBUZgsxdME1EJy88', 'AepWpq3GQwL8CeKMtZyKtKPa7W91Coygh3ropAJapVdU',
        'DuQ4jFMmVABWGxabYHFkGzdyeJgS1hp4wrRuCtsJgT9a', 'DEXVS3su4dZQWTvvPnLDJLRK1CeeKG6K3QqdzthgAkNV',
        'Hbe1vdFs4EQVVAzcV12muHhr6DEKwrT9roMXGPLxLBLP', '5xvht4fYDs99yprfm4UeuHSLxMBRpotfBtUCQqM3oDNG',
        '2wKupLR9q6wXYppw8Gr2NvWxKBUqm4PPJKkQfoxHDBg4', 'CjNFTjvBhbJJd2B5ePPMHRLx1ELZpa8dwQgGL727eKww',
        '8B5UKhwfAyFW67h58cBkQj1Ur6QXRgwWJJcQp8ZBsDPa', '4x4ZhcqiT1FnirM8Ne97iVupkN4NcQgc2YYbE2jDZbZn',
        'F742C4VfFLQ9zRQyithoj5229ZgtX2WqKCSFKgH2EThq', '561oabzy81vXYYbs1ZHR1bvpiEr6Nbfd6PGTxPshoz4p'
      )
      LIMIT 1
    ) AS matched_facilitator_signer
  FROM `bigquery-public-data.crypto_solana_mainnet_us.Transactions` AS tx
  WHERE
    tx.block_timestamp >= start_ts AND tx.block_timestamp < end_ts
    AND EXISTS (
      SELECT 1 FROM UNNEST(tx.accounts) AS a
      WHERE a.signer = TRUE AND a.pubkey IN (
        '34DmdeSbEnng2bmbSj9ActckY49km2HdhiyAwyXZucqP', '8x8CzkTHTYkW18frrTR7HdCV6fsjenvcykJAXWvoPQW',
        'PcTZWki36z5Y82TAATKK48XUdfsgmS5oLkw2Ta7vWyK', '7NetKx8TuRMBpqYFKZCVetkNuvWCPTrgekmGrsJwTmfN',
        'HsozMJWWHNADoZRmhDGKzua6XW6NNfNDdQ4CkE9i5wHt', 'L54zkaPQFeTn1UsEqieEXBqWrPShiaZEPD7mS5WXfQg',
        'BENrLoUbndxoNMUS5JXApGMtNykLjFXXixMtpDwDR9SP', 'BFK9TLC3edb13K6v4YyH3DwPb5DSUpkWvb7XnqCL9b4F',
        'D6ZhtNQ5nT9ZnTHUbqXZsTx5MH2rPFiBBggX4hY1WePM', 'GVJJ7rdGiXr5xaYbRwRbjfaJL7fmwRygFi1H6aGqDveb',
        'Hc3sdEAsCGQcpgfivywog9uwtk8gUBUZgsxdME1EJy88', 'AepWpq3GQwL8CeKMtZyKtKPa7W91Coygh3ropAJapVdU',
        'DuQ4jFMmVABWGxabYHFkGzdyeJgS1hp4wrRuCtsJgT9a', 'DEXVS3su4dZQWTvvPnLDJLRK1CeeKG6K3QqdzthgAkNV',
        'Hbe1vdFs4EQVVAzcV12muHhr6DEKwrT9roMXGPLxLBLP', '5xvht4fYDs99yprfm4UeuHSLxMBRpotfBtUCQqM3oDNG',
        '2wKupLR9q6wXYppw8Gr2NvWxKBUqm4PPJKkQfoxHDBg4', 'CjNFTjvBhbJJd2B5ePPMHRLx1ELZpa8dwQgGL727eKww',
        '8B5UKhwfAyFW67h58cBkQj1Ur6QXRgwWJJcQp8ZBsDPa', '4x4ZhcqiT1FnirM8Ne97iVupkN4NcQgc2YYbE2jDZbZn',
        'F742C4VfFLQ9zRQyithoj5229ZgtX2WqKCSFKgH2EThq', '561oabzy81vXYYbs1ZHR1bvpiEr6Nbfd6PGTxPshoz4p'
      )
    )
),
enriched AS (
  SELECT
    t.tx_signature,
    t.block_timestamp,
    s.tx_status,
    t.mint AS token_mint,
    t.source AS source_ata,
    t.destination AS destination_ata,
    CASE WHEN s.tx_status = 'SUCCESS' THEN SAFE_DIVIDE(t.value, POW(10, t.decimals)) ELSE 0 END AS amount_usdc,
    s.fee_payer AS transaction_from,
    s.matched_facilitator_signer AS facilitator_signer,
    ROW_NUMBER() OVER (
      PARTITION BY t.tx_signature
      ORDER BY t.block_timestamp, t.source, t.destination, t.value
    ) - 1 AS transfer_index,
    'solana' AS chain
  FROM `bigquery-public-data.crypto_solana_mainnet_us.Token Transfers` AS t
  JOIN signer_sigs AS s ON t.tx_signature = s.signature
  WHERE
    t.block_timestamp >= TIMESTAMP_SUB(start_ts, INTERVAL 30 MINUTE)
    AND t.block_timestamp < TIMESTAMP_ADD(end_ts, INTERVAL 30 MINUTE)
    AND t.mint = usdc_mint
    AND t.value IS NOT NULL
    AND t.decimals IS NOT NULL
)
SELECT * FROM enriched;
"""

def run_bq(query):
    res = subprocess.run(
        ["bq", "query", "--use_legacy_sql=false", "--project_id=web3-publicgoods", "--location=us-central1", query],
        text=True
    )
    if res.returncode != 0:
        print(f"Error executing query: bq exited with {res.returncode}")
        return False
    return True

print("Creating native partitioned sol_raw table...")
if not run_bq(create_table_sql):
    exit(1)

# Start from July 2, 2025 up to today (~April 2, 2026)
# Chunking by 30 days to avoid Google Cloud execution slot limits!
start_date = datetime.datetime(2025, 7, 2, tzinfo=datetime.timezone.utc)
end_date = datetime.datetime(2026, 4, 3, tzinfo=datetime.timezone.utc) # capture through today

current_start = start_date
while current_start < end_date:
    current_end = current_start + datetime.timedelta(days=30)
    if current_end > end_date:
        current_end = end_date
    
    start_str = current_start.strftime('%Y-%m-%d %H:%M:%S')
    end_str = current_end.strftime('%Y-%m-%d %H:%M:%S')
    
    print(f"Hydrating Solana block temporal range: {start_str} to {end_str}")
    chunk_query = insert_chunk_sql_template.format(start_time=start_str, end_time=end_str)
    
    if run_bq(chunk_query):
        print(f"✅ Chunk {start_str} successfully ingested into web3-publicgoods.tektonic_x402.sol_raw")
    else:
        print(f"❌ FAILED to ingest chunk {start_str}")
        break

    current_start = current_end

print("🎉 Historical Solana Hydration Complete!")
