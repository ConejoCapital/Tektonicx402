# Tektonic x402 Public Dataset

**License:** CC-0 (public domain)
**Supported by:** Google Cloud Web3 and the Solana Foundation

## Overview

The Tektonic x402 dataset provides a comprehensive ledger of x402 protocol payment settlements across Solana and Base. Data is extracted directly from Google Cloud's public blockchain datasets using production-grade SQL, with no third-party indexer dependencies.

By replacing rate-limited, legacy HTTP RPC-polling methodologies with a BigQuery-native extraction engine, this dataset achieves 100% historical accuracy and throughput capture across multiple blockchain environments, logging tens of thousands of daily micro-settlements that traditional indexers physically cannot access.

## Methodology

- **Solana:** Queries `bigquery-public-data.crypto_solana_mainnet_us` (Transactions + Token Transfers). Identifies x402 payments by matching known facilitator pubkeys as transaction signers on USDC transfers. Failed transactions are captured but zeroed in volume via strict `tx.err = ''` execution filtering.
- **Base (EVM):** Queries Analytics Hub community datasets for Base token transfers. Identifies x402 payments by matching `transaction_from` to known facilitator addresses on USDC `Transfer` events. Reverted transactions are naturally excluded since EVM eliminates events on revert.

## Verified Accuracy

Independent parity testing (March 30, 2026, Solana) confirmed this pipeline captures 8.9% more transactions and 6.6% more USDC volume than the leading public indexer, with zero failed-transaction contamination. See the full report: [PARITY_REPORT.md](./PARITY_REPORT.md).

## Source Code

Pipeline scripts, facilitator registries, and aggregate analytics queries:
**[github.com/ConejoCapital/Bigx402Query](https://github.com/ConejoCapital/Bigx402Query)**
