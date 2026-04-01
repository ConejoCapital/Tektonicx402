# x402 Base Network Extraction Schema

## Table: `base_x402_extract`

**Description:**  
Extracts standard ERC-20 `Transfer` events from the USDC contract on Base mainnet where the transaction was submitted by a known x402 facilitator wallet. This is the canonical on-chain fingerprint of an x402 payment settlement on Base.

**Data Source:** Coinbase CDP Analytics API (`base.events`) or raw Base logs export  
**Chain:** Base Mainnet (Chain ID: 8453)  
**Token:** USDC (`0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`)

---

## Why NOT `TransferWithAuthorization`?

x402 leverages EIP-3009 off-chain for the *client signature step*, but the final on-chain settlement is a standard `transferFrom` call made by the facilitator. This emits the canonical `Transfer(address,address,uint256)` event — NOT a `TransferWithAuthorization` event. The x402 signal is the **`transaction_from`** field being a known facilitator address.

---

## Output Schema

| Column | Type | Description |
| :--- | :--- | :--- |
| `tx_hash` | `STRING` | The Base transaction hash |
| `block_timestamp` | `TIMESTAMP` | Block timestamp of the settlement |
| `block_number` | `INTEGER` | Base block number |
| `log_index` | `INTEGER` | Log index within the transaction (for deduplication) |
| `sender` | `STRING` | The USDC sender — the end-user/agent paying for the resource |
| `recipient` | `STRING` | The USDC recipient — the seller/API provider |
| `facilitator_address` | `STRING` | The wallet that submitted the tx (`transaction_from`) — the x402 facilitator |
| `facilitator_name` | `STRING` | Human-readable facilitator name (e.g., `coinbase`, `virtuals`, `thirdweb`) |
| `token_address` | `STRING` | USDC contract address on Base (`0x833589f...`) |
| `token_symbol` | `STRING` | Always `USDC` |
| `amount_usdc` | `FLOAT64` | Settlement amount in human-readable USDC (raw value / 1e6) |
| `chain` | `STRING` | Always `base` |

---

## Known Facilitators (Base Mainnet)

| Facilitator | Wallet Address | Active Since |
| :--- | :--- | :--- |
| coinbase | `0x9fb2714af0a84816f5c6322884f2907e33946b88` | 2025-10-31 |
| coinbase | `0xcbb10c30a9a72fae9232f41cbbd566a097b4e03a` | 2025-10-31 |
| coinbase | `0x47d8b3c9717e976f31025089384f23900750a5f4` | 2025-11-11 |
| coinbase | `0x94701e1df9ae06642bf6027589b8e05dc7004813` | 2025-11-11 |
| coinbase | `0x552300992857834c0ad41c8e1a6934a5e4a2e4ca` | 2025-11-11 |
| coinbase | `0xd7469bf02d221968ab9f0c8b9351f55f8668ac4f` | 2025-11-11 |
| coinbase | `0x88800e08e20b45c9b1f0480cf759b5bf2f05180c` | 2025-11-11 |
| coinbase | `0x6831508455a716f987782a1ab41e204856055cc2` | 2025-11-11 |
| coinbase | `0xdc8fbad54bf5151405de488f45acd555517e0958` | 2025-11-11 |
| coinbase | `0x91d313853ad458addda56b35a7686e2f38ff3952` | 2025-11-11 |
| coinbase | `0xadd5585c776b9b0ea77e9309c1299a40442d820f` | 2025-11-11 |
| coinbase | `0x4ffeffa616a1460570d1eb0390e264d45a199e91` | 2025-11-11 |
| coinbase | `0x8f5cb67b49555e614892b7233cfddebfb746e531` | 2025-12-16 |
| coinbase | `0x67b9ce703d9ce658d7c4ac3c289cea112fe662af` | 2025-12-16 |
| coinbase | `0x68a96f41ff1e9f2e7b591a931a4ad224e7c07863` | 2025-12-16 |
| coinbase | `0x97acce27d5069544480bde0f04d9f47d7422a016` | 2025-12-16 |
| coinbase | `0xa32ccda98ba7529705a059bd2d213da8de10d101` | 2025-12-16 |
| virtuals | `0x80735b3f7808e2e229ace880dbe85e80115631ca` | 2025-11-05 |
| thirdweb | `0x80c08de1a05df2bd633cf520754e40fde3c794d3` | 2025-10-07 |
| thirdweb | `0xaaca1ba9d2627cbc0739ba69890c30f95de046e4` | 2025-11-20 |
| thirdweb | `0xa1822b21202a24669eaf9277723d180cd6dae874` | 2025-11-20 |
| thirdweb | `0xec10243b54df1a71254f58873b389b7ecece89c2` | 2025-11-20 |
| thirdweb | `0x052aaae3cad5c095850246f8ffb228354c56752a` | 2025-11-20 |
| thirdweb | `0x91ddea05f741b34b63a7548338c90fc152c8631f` | 2025-11-20 |
| thirdweb | `0xea52f2c6f6287f554f9b54c5417e1e431fe5710e` | 2025-11-20 |
| thirdweb | `0x3a5ca1c6aa6576ae9c1c0e7fa2b4883346bc5aa0` | 2025-11-20 |
| thirdweb | `0x7e20b62bf36554b704774afb0fcc0ae8f899213b` | 2025-11-20 |
| thirdweb | `0xd88a9a58806b895ff06744082c6a20b9d7184b0f` | 2025-11-20 |

> **Note:** This list is sourced from [x402scan/packages/external/facilitators](https://github.com/Merit-Systems/x402scan) and should be updated as new facilitators register.
