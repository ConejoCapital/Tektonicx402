import os
import logging
from google.cloud import bigquery_storage_v1
from google.cloud.bigquery_storage_v1 import types

# ==============================================================================
# x402 BigQuery Storage Write API Streamer (Template)
#
# Pushes high-throughput streaming x402 data directly into Google BigQuery
# using the BigQuery Storage Write API (gRPC).
#
# Prerequisites:
#   - google-cloud-bigquery-storage Python package
#   - A GCP service account with roles:
#       roles/bigquery.dataOwner
#       roles/bigquery.readSessionUser
#
# Usage:
#   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-service-account-key.json"
#   export BQ_PROJECT_ID="your-gcp-project"
#   export BQ_DATASET_ID="your-dataset"
#   python stream_to_bq.py
# ==============================================================================

PROJECT_ID = os.environ.get("BQ_PROJECT_ID", "YOUR_PROJECT_ID")
DATASET_ID = os.environ.get("BQ_DATASET_ID", "YOUR_DATASET_ID")
BASE_TABLE_ID = "base_raw"
SOLANA_TABLE_ID = "solana_raw"

logging.basicConfig(level=logging.INFO)


def create_write_stream(write_client, project_id, dataset_id, table_id):
    """Initializes a new write stream to a specific BigQuery table."""
    parent = write_client.table_path(project_id, dataset_id, table_id)
    write_stream = types.WriteStream()

    # COMMITTED type for streaming (vs PENDING for batch loading).
    # The first 2TB of COMMITTED ingestion is free per Google Cloud quotas.
    write_stream.type_ = types.WriteStream.Type.COMMITTED

    try:
        stream = write_client.create_write_stream(
            parent=parent, write_stream=write_stream
        )
        logging.info(f"Connected stream to {table_id}: {stream.name}")
        return stream
    except Exception as e:
        logging.error(f"Failed to create write stream for {table_id}.")
        logging.error("Verify service account has roles/bigquery.dataOwner "
                       "and roles/bigquery.readSessionUser.")
        raise e


def stream_x402_data():
    """
    Entry point for the streaming pipeline.

    In production, this function is called by an event listener that maps
    extracted x402 settlement rows into protocol buffer objects and flushes
    them to the BigQuery write stream.
    """
    credentials_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not credentials_path:
        logging.error("GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.")
        return

    logging.info("Initializing BigQuery Storage Write API client...")
    write_client = bigquery_storage_v1.BigQueryWriteClient()

    # Create write streams into target tables
    # base_stream = create_write_stream(write_client, PROJECT_ID, DATASET_ID, BASE_TABLE_ID)
    # sol_stream = create_write_stream(write_client, PROJECT_ID, DATASET_ID, SOLANA_TABLE_ID)

    logging.info("Write streams ready. Awaiting protocol buffer serialization.")


if __name__ == "__main__":
    stream_x402_data()
