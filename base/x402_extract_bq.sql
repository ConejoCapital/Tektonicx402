-- =============================================================================
-- x402 Payment Extraction: Base Network
-- Google Cloud BigQuery Analytics Hub Linked Dataset
--
-- HOW x402 WORKS ON BASE (EVM):
--   1. Client signs an EIP-712 authorization off-chain.
--   2. A Facilitator wallet submits the on-chain USDC transferFrom call.
--   3. The USDC contract emits a standard ERC-20 Transfer(from, to, value) event.
--   4. The x402 fingerprint is: Transfer event on USDC contract WHERE
--      transaction_from = a known facilitator address.
--
-- DATA SOURCE:
--   This query targets the Base Blockchain Community Public Dataset via Analytics Hub.
--   You must create a "Linked Dataset" in your GCP project first:
--     BigQuery Console > Add Data > Analytics Hub > Search "Base" community dataset.
--
--   Replace YOUR_PROJECT.YOUR_LINKED_DATASET in the FROM clause with your
--   actual GCP project and linked dataset name.
--
-- USDC on Base: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
-- =============================================================================

DECLARE start_ts TIMESTAMP DEFAULT TIMESTAMP('2026-03-26 00:00:00');
DECLARE end_ts   TIMESTAMP DEFAULT TIMESTAMP('2026-03-27 00:00:00');

-- ---------------------------------------------------------------------------
-- STEP 1: Define all known x402 facilitator wallets on Base.
--         Sourced from: github.com/Merit-Systems/x402scan/packages/external/facilitators
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE x402_facilitators (
  address       STRING,
  facilitator   STRING
);

INSERT INTO x402_facilitators VALUES
  ('0x73b2b8df52fbe7c40fe78db52e3dffdd5db5ad07', '402104'),
  ('0x179761d9eed0f0d1599330cc94b0926e68ae87f1', 'anyspend'),
  ('0x222c4367a2950f3b53af260e111fc3060b0983ff', 'aurracloud'),
  ('0xb70c4fe126de09bd292fe3d1e40c6d264ca6a52a', 'aurracloud'),
  ('0xd348e724e0ef36291a28dfeccf692399b0e179f8', 'aurracloud'),
  ('0x15e2e2da7539ef1f652aa3c1d6142a535aa3d7ea', 'bitrefill'),
  ('0x2bb201f1bb056eb738718bd7a3ad1bef24b883bb', 'cascade'),
  ('0x8d8fa42584a727488eeb0e29405ad794a105bb9b', 'codenut'),
  ('0x87af99356d774312b73018b3b6562e1ae0e018c9', 'codenut'),
  ('0x65058cf664d0d07f68b663b0d4b4f12a5e331a38', 'codenut'),
  ('0x88e13d4c764a6c840ce722a0a3765f55a85b327e', 'codenut'),
  ('0xdbdf3d8ed80f84c35d01c6c9f9271761bad90ba6', 'coinbase'),
  ('0x9aae2b0d1b9dc55ac9bab9556f9a26cb64995fb9', 'coinbase'),
  ('0x3a70788150c7645a21b95b7062ab1784d3cc2104', 'coinbase'),
  ('0x708e57b6650a9a741ab39cae1969ea1d2d10eca1', 'coinbase'),
  ('0xce82eeec8e98e443ec34fda3c3e999cbe4cb6ac2', 'coinbase'),
  ('0x7f6d822467df2a85f792d4508c5722ade96be056', 'coinbase'),
  ('0x001ddabba5782ee48842318bd9ff4008647c8d9c', 'coinbase'),
  ('0x9c09faa49c4235a09677159ff14f17498ac48738', 'coinbase'),
  ('0xcbb10c30a9a72fae9232f41cbbd566a097b4e03a', 'coinbase'),
  ('0x9fb2714af0a84816f5c6322884f2907e33946b88', 'coinbase'),
  ('0x47d8b3c9717e976f31025089384f23900750a5f4', 'coinbase'),
  ('0x94701e1df9ae06642bf6027589b8e05dc7004813', 'coinbase'),
  ('0x552300992857834c0ad41c8e1a6934a5e4a2e4ca', 'coinbase'),
  ('0xd7469bf02d221968ab9f0c8b9351f55f8668ac4f', 'coinbase'),
  ('0x88800e08e20b45c9b1f0480cf759b5bf2f05180c', 'coinbase'),
  ('0x6831508455a716f987782a1ab41e204856055cc2', 'coinbase'),
  ('0xdc8fbad54bf5151405de488f45acd555517e0958', 'coinbase'),
  ('0x91d313853ad458addda56b35a7686e2f38ff3952', 'coinbase'),
  ('0xadd5585c776b9b0ea77e9309c1299a40442d820f', 'coinbase'),
  ('0x4ffeffa616a1460570d1eb0390e264d45a199e91', 'coinbase'),
  ('0x8f5cb67b49555e614892b7233cfddebfb746e531', 'coinbase'),
  ('0x67b9ce703d9ce658d7c4ac3c289cea112fe662af', 'coinbase'),
  ('0x68a96f41ff1e9f2e7b591a931a4ad224e7c07863', 'coinbase'),
  ('0x97acce27d5069544480bde0f04d9f47d7422a016', 'coinbase'),
  ('0xa32ccda98ba7529705a059bd2d213da8de10d101', 'coinbase'),
  ('0x06f0bfd2c8f36674df5cde852c1eed8025c268c9', 'corbits'),
  ('0x279e08f711182c79ba6d09669127a426228a4653', 'daydreams'),
  ('0x1363c7ff51ccce10258a7f7bddd63baab6aaf678', 'daydreams'),
  ('0x40272e2eac848ea70db07fd657d799bd309329c4', 'dexter'),
  ('0xb578b7db22581507d62bdbeb85e06acd1be09e11', 'heurist'),
  ('0x021cc47adeca6673def958e324ca38023b80a5be', 'heurist'),
  ('0x3f61093f61817b29d9556d3b092e67746af8cdfd', 'heurist'),
  ('0x290d8b8edcafb25042725cb9e78bcac36b8865f8', 'heurist'),
  ('0x612d72dc8402bba997c61aa82ce718ea23b2df5d', 'heurist'),
  ('0x1fc230ee3c13d0d520d49360a967dbd1555c8326', 'heurist'),
  ('0x48ab4b0af4ddc2f666a3fcc43666c793889787a3', 'heurist'),
  ('0xd97c12726dcf994797c981d31cfb243d231189fb', 'heurist'),
  ('0x90d5e567017f6c696f1916f4365dd79985fce50f', 'heurist'),
  ('0x8e7769d440b3460b92159dd9c6d17302b036e2d6', 'meridian'),
  ('0x3210d7b21bfe1083c9dddbe17e8f947c9029a584', 'meridian'),
  ('0xfe0920a0a7f0f8a1ec689146c30c3bbef439bf8a', 'mogami'),
  ('0x7c766f5fd9ab3dc09acad5ecfacc99c4781efe29', 'openfacilitator'),
  ('0x97316fa4730bc7d3b295234f8e4d04a0a4c093e8', 'openx402'),
  ('0x97db9b5291a218fc77198c285cefdc943ef74917', 'openx402'),
  ('0x16e47d275198ed65916a560bab4af6330c36ae09', 'openmid'),
  ('0xc6699d2aada6c36dfea5c248dd70f9cb0235cb63', 'payai'),
  ('0xb2bd29925cbbcea7628279c91945ca5b98bf371b', 'payai'),
  ('0x25659315106580ce2a787ceec5efb2d347b539c9', 'payai'),
  ('0xb8f41cb13b1f213da1e94e1b742ec1323235c48f', 'payai'),
  ('0xe575fa51af90957d66fab6d63355f1ed021b887b', 'payai'),
  ('0x03a3f7ce8e21e6f8d9fa14c67d8876b2470dc2f1', 'payai'),
  ('0x675707bc7d03089f820c1b7d49f7480083e8f4df', 'payai'),
  ('0xf46833d4ac4f0f1405cc05c30edfd86770f721c9', 'payai'),
  ('0x2daaef6f941de214bf7d6daf322bc6bc7406accb', 'payai'),
  ('0x2fae4026a31f19183947f0a6048ef975ebfa9ca8', 'payai'),
  ('0xe299c486066739c4a31609e1268d93229632dd47', 'payai'),
  ('0x6ccf245c883f9f3c6caee0687aa61daf7bc96e32', 'payai'),
  ('0xaf990eef9846b63d896056050fdc0b28bca9c24b', 'payai'),
  ('0x489c40fc3c2a19ad8cb275b7dd6aa194e9219c4f', 'payai'),
  ('0x9df61a719ddae27c20a63a417271cc2c704654bd', 'payai'),
  ('0x66c40946b0dffd04be467e18309857307ecd37cb', 'polymer'),
  ('0x37dfb4033d5dd98fd335f24d0d42e8fe68d587d6', 'primer'),
  ('0x724efafb051f17ae824afcdf3c0368ae312da264', 'questflow'),
  ('0xa9a54ef09fc8b86bc747cec6ef8d6e81c38c6180', 'questflow'),
  ('0x4638bc811c93bf5e60deed32325e93505f681576', 'questflow'),
  ('0xd7d91a42dfadd906c5b9ccde7226d28251e4cd0f', 'questflow'),
  ('0x4544b535938b67d2a410a98a7e3b0f8f68921ca7', 'questflow'),
  ('0x59e8014a3b884392fbb679fe461da07b18c1ff81', 'questflow'),
  ('0xe6123e6b389751c5f7e9349f3d626b105c1fe618', 'questflow'),
  ('0xf70e7cb30b132fab2a0a5e80d41861aa133ea21b', 'questflow'),
  ('0x90da501fdbec74bb0549100967eb221fed79c99b', 'questflow'),
  ('0xce7819f0b0b871733c933d1f486533bab95ec47b', 'questflow'),
  ('0x1892f72fdb3a966b2ad8595aa5f7741ef72d6085', 'relai'),
  ('0x80c08de1a05df2bd633cf520754e40fde3c794d3', 'thirdweb'),
  ('0xaaca1ba9d2627cbc0739ba69890c30f95de046e4', 'thirdweb'),
  ('0xa1822b21202a24669eaf9277723d180cd6dae874', 'thirdweb'),
  ('0xec10243b54df1a71254f58873b389b7ecece89c2', 'thirdweb'),
  ('0x052aaae3cad5c095850246f8ffb228354c56752a', 'thirdweb'),
  ('0x91ddea05f741b34b63a7548338c90fc152c8631f', 'thirdweb'),
  ('0xea52f2c6f6287f554f9b54c5417e1e431fe5710e', 'thirdweb'),
  ('0x3a5ca1c6aa6576ae9c1c0e7fa2b4883346bc5aa0', 'thirdweb'),
  ('0x7e20b62bf36554b704774afb0fcc0ae8f899213b', 'thirdweb'),
  ('0xd88a9a58806b895ff06744082c6a20b9d7184b0f', 'thirdweb'),
  ('0xe07e9cbf9a55d02e3ac356ed4706353d98c5a618', 'treasure'),
  ('0x103040545ac5031a11e8c03dd11324c7333a13c7', 'ultravioletadao'),
  ('0x80735b3f7808e2e229ace880dbe85e80115631ca', 'virtuals'),
  ('0xd8dfc729cbd05381647eb5540d756f4f8ad63eec', 'x402rs'),
  ('0x76eee8f0acabd6b49f1cc4e9656a0c8892f3332e', 'x402rs'),
  ('0x97d38aa5de015245dcca76305b53abe6da25f6a5', 'x402rs'),
  ('0x0168f80e035ea68b191faf9bfc12778c87d92008', 'x402rs'),
  ('0x5e437bee4321db862ac57085ea5eb97199c0ccc5', 'x402rs'),
  ('0xc19829b32324f116ee7f80d193f99e445968499a', 'x402rs'),
  ('0x51fec16843e49b99aaf9814e525aee1756e66a62', 'x402jobs'),
  ('0x3be45f576696a2fd5a93c1330cd19f1607ab311d', 'xecho');

-- ---------------------------------------------------------------------------
-- STEP 2: Extract x402 payments via the custom base_raw table
-- ---------------------------------------------------------------------------

SELECT
  t.transaction_hash                         AS tx_hash,
  t.block_timestamp                          AS block_timestamp,
  t.block_number                             AS block_number,
  
  -- x402 payment parties
  t.from_address                             AS sender,
  t.to_address                               AS recipient,
  
  -- The token_transfers table might not inherently store the transaction initiator 
  -- unless you explicitly flattened it. Assuming 'transaction_from' or 'initiator' exists.
  t.transaction_from                         AS facilitator_address,
  f.facilitator                              AS facilitator_name,

  -- Token details
  t.token_address                            AS token_address,
  'USDC'                                     AS token_symbol,
  SAFE_DIVIDE(CAST(t.value AS FLOAT64), 1e6) AS amount_usdc,
  
  -- Chain tag
  'base'                                     AS chain

-- Replace YOUR_PROJECT and YOUR_LINKED_DATASET with your GCP project and
-- Analytics Hub linked dataset name. To create a linked dataset, go to:
-- BigQuery > Add Data > Analytics Hub > Search for "Base" community dataset.
FROM `YOUR_PROJECT.YOUR_LINKED_DATASET.base_raw` t

-- Join facilitator registry to verify the transaction was sent by a known facilitator
JOIN x402_facilitators f 
  ON LOWER(t.transaction_from) = LOWER(f.address)

WHERE
  -- Scope date range
  t.block_timestamp >= start_ts 
  AND t.block_timestamp < end_ts

  -- USDC contract on Base mainnet
  AND LOWER(t.token_address) = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913'

ORDER BY t.block_timestamp DESC;
