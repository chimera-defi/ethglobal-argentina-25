# Ethereum Sepolia + Base Sepolia Deployment Guide

## Quick Start

This guide will help you deploy the USDX protocol to Ethereum Sepolia (hub) and Base Sepolia (spoke), then test cross-chain USDC deposits and USDX minting.

**Total Time:** ~30 minutes  
**Cost:** ~$5-10 in Sepolia ETH and Base Sepolia ETH (get from faucets)

---

## Prerequisites

### 1. Get Testnet ETH

**Ethereum Sepolia:**
- Alchemy Faucet: https://sepoliafaucet.com/
- Infura Faucet: https://www.infura.io/faucet/sepolia
- Need: ~0.5 ETH for deployment + testing

**Base Sepolia:**
- Alchemy Base Faucet: https://www.alchemy.com/faucets/base-sepolia
- Coinbase Faucet: https://portal.cdp.coinbase.com/products/faucet
- Bridge from Sepolia: https://bridge.base.org/
- Need: ~0.2 ETH for deployment + testing

### 2. Get RPC URLs

**Free Options:**
- Alchemy: https://www.alchemy.com/ (recommended)
- Infura: https://www.infura.io/
- Public RPCs (rate-limited):
  - Sepolia: `https://ethereum-sepolia.publicnode.com`
  - Base Sepolia: `https://sepolia.base.org`

### 3. Get API Keys for Contract Verification

- Etherscan: https://etherscan.io/apis
- Basescan: https://basescan.org/apis

---

## Step-by-Step Deployment

### Step 1: Setup Environment Variables

```bash
cd /workspace/usdx/contracts

# Set your private key (NEVER commit this!)
export PRIVATE_KEY="0x..."  # Your testnet wallet private key

# Set RPC URLs
export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
export BASE_SEPOLIA_RPC_URL="https://base-sepolia.g.alchemy.com/v2/YOUR_KEY"

# Set API keys for verification
export ETHERSCAN_API_KEY="YOUR_ETHERSCAN_KEY"
export BASESCAN_API_KEY="YOUR_BASESCAN_KEY"
```

### Step 2: Deploy Hub Contracts (Ethereum Sepolia)

```bash
forge script script/DeploySepoliaBaseSepolia.s.sol:DeploySepoliaBaseSepolia \
  --sig "deployHub()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Save the output! You'll need these addresses:
# HUB_ADAPTER=0x...
# HUB_COMPOSER=0x...
# HUB_VAULT=0x...
```

**What this deploys on Sepolia:**
1. MockUSDC - Test USDC token (you get 1M USDC)
2. MockYearnVault - Mock yield vault
3. USDXYearnVaultWrapper - ERC-4626 wrapper
4. USDXShareOFTAdapter - Locks shares on hub
5. USDXVaultComposerSync - Orchestrates cross-chain deposits
6. USDXToken - USDX stablecoin
7. USDXVault - Main vault logic

**Expected Output:**
```
========================================
  HUB DEPLOYMENT COMPLETE!
========================================

COPY THESE ADDRESSES FOR SPOKE DEPLOYMENT:

HUB_ADAPTER= 0x1234...
HUB_COMPOSER= 0x5678...
HUB_VAULT= 0x9abc...
```

### Step 3: Deploy Spoke Contracts (Base Sepolia)

```bash
# Use the addresses from Step 2
export HUB_ADAPTER=0x...  # From Step 2 output
export HUB_COMPOSER=0x... # From Step 2 output

forge script script/DeploySepoliaBaseSepolia.s.sol:DeploySepoliaBaseSepolia \
  --sig "deploySpoke(address,address)" $HUB_ADAPTER $HUB_COMPOSER \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Save the output! You'll need these addresses:
# SPOKE_SHARE_OFT=0x...
# SPOKE_MINTER=0x...
# SPOKE_USDX=0x...
```

**What this deploys on Base Sepolia:**
1. USDXToken - USDX stablecoin on Base
2. USDXShareOFT - Receives vault shares from hub
3. USDXSpokeMinter - Mints USDX against shares

**Expected Output:**
```
========================================
  SPOKE DEPLOYMENT COMPLETE!
========================================

COPY THESE ADDRESSES FOR CONFIGURATION:

SPOKE_SHARE_OFT= 0xdef0...
SPOKE_MINTER= 0x1111...
SPOKE_USDX= 0x2222...
```

### Step 4: Configure Trusted Remotes (Hub)

```bash
# Use addresses from Step 2 and Step 3
export HUB_ADAPTER=0x...
export HUB_COMPOSER=0x...
export SPOKE_SHARE_OFT=0x...

forge script script/DeploySepoliaBaseSepolia.s.sol:DeploySepoliaBaseSepolia \
  --sig "configureTrustedRemotesHub(address,address,address)" \
    $HUB_ADAPTER $HUB_COMPOSER $SPOKE_SHARE_OFT \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

**What this does:**
- Tells hub adapter where to send shares (spoke)
- Tells hub composer where to route cross-chain requests

### Step 5: Configure Trusted Remotes (Spoke)

```bash
# Use addresses from Step 2 and Step 3
export SPOKE_SHARE_OFT=0x...
export SPOKE_MINTER=0x...
export HUB_ADAPTER=0x...

forge script script/DeploySepoliaBaseSepolia.s.sol:DeploySepoliaBaseSepolia \
  --sig "configureTrustedRemotesSpoke(address,address,address)" \
    $SPOKE_SHARE_OFT $SPOKE_MINTER $HUB_ADAPTER \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast
```

**What this does:**
- Tells spoke where to accept shares from (hub)
- Enables cross-chain message verification

---

## Testing Cross-Chain Flow

### Test 1: Deposit USDC on Sepolia → Receive Shares on Base Sepolia

**On Ethereum Sepolia (using cast or Etherscan):**

```bash
# 1. Approve USDC to Hub Vault
cast send $USDC_ADDRESS \
  "approve(address,uint256)" $HUB_VAULT 1000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# 2. Deposit via OVault (cross-chain to Base Sepolia)
# depositViaOVault(uint256 assets, uint32 dstEid, bytes32 receiver, bytes options)
# Base Sepolia EID = 40245
# Your address as bytes32 = 0x000000000000000000000000YOUR_ADDRESS

cast send $HUB_VAULT \
  "depositViaOVault(uint256,uint32,bytes32,bytes)" \
    1000000000 \
    40245 \
    0x000000000000000000000000YOUR_ADDRESS \
    0x \
  --value 0.001ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Wait ~2-5 minutes for LayerZero to deliver the message
```

**Check Balance on Base Sepolia:**

```bash
# Check your share OFT balance on Base Sepolia
cast call $SPOKE_SHARE_OFT \
  "balanceOf(address)" YOUR_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# Should show: 1000000000 (1000 USDC worth of shares, 6 decimals)
```

### Test 2: Mint USDX on Base Sepolia

```bash
# Approve shares to spoke minter
cast send $SPOKE_SHARE_OFT \
  "approve(address,uint256)" $SPOKE_MINTER 1000000000 \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Mint USDX from shares
cast send $SPOKE_MINTER \
  "mintUSDXFromOVault(uint256)" 1000000000 \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Check USDX balance
cast call $SPOKE_USDX \
  "balanceOf(address)" YOUR_ADDRESS \
  --rpc-url $BASE_SEPOLIA_RPC_URL

# Should show: 1000000000 (1000 USDX)
```

### Test 3: Send USDX Back to Sepolia

```bash
# Send USDX from Base Sepolia back to Ethereum Sepolia
# (This tests cross-chain USDX transfers)

cast send $SPOKE_USDX \
  "sendFrom(address,uint32,bytes32,uint256,bytes)" \
    YOUR_ADDRESS \
    40161 \
    0x000000000000000000000000YOUR_ADDRESS \
    500000000 \
    0x \
  --value 0.001ether \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Wait ~2-5 minutes, then check balance on Sepolia
cast call $HUB_USDX \
  "balanceOf(address)" YOUR_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```

---

## Troubleshooting

### "Insufficient funds for gas"
- Get more testnet ETH from faucets
- Reduce gas price or wait for lower gas

### "Transaction reverted" on deposit
- Check USDC approval: `cast call $USDC "allowance(address,address)" YOUR_ADDRESS $HUB_VAULT --rpc-url $SEPOLIA_RPC_URL`
- Check USDC balance: `cast call $USDC "balanceOf(address)" YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL`

### LayerZero message not delivered
- Wait 5-10 minutes (testnets can be slow)
- Check LayerZero Scan: https://testnet.layerzeroscan.com/
- Search for your transaction hash
- Verify trusted remotes are set correctly

### Shares not appearing on Base Sepolia
- Verify trusted remotes (Step 4 & 5 completed)
- Check LayerZero Scan for message status
- Ensure you sent enough ETH for LayerZero fees (0.001 ETH)

---

## Contract Addresses (Save These!)

### Ethereum Sepolia (Hub)
```
USDC:               0x...
Yearn Vault:        0x...
Vault Wrapper:      0x...
Share OFT Adapter:  0x...  # HUB_ADAPTER
Vault Composer:     0x...  # HUB_COMPOSER
USDX Token:         0x...
USDX Vault:         0x...  # HUB_VAULT
```

### Base Sepolia (Spoke)
```
USDX Token:         0x...  # SPOKE_USDX
Share OFT:          0x...  # SPOKE_SHARE_OFT
Spoke Minter:       0x...  # SPOKE_MINTER
```

### LayerZero Endpoints (Pre-deployed)
```
Sepolia:            0x6EDCE65403992e310A62460808c4b910D972f10f
Base Sepolia:       0x6EDCE65403992e310A62460808c4b910D972f10f
```

---

## Next Steps

After successful testnet deployment:

1. **Audit Preparation**
   - Document all contract interactions
   - Create comprehensive test suite
   - Prepare for security audit

2. **UI Development**
   - Build frontend for deposit/withdraw
   - Integrate LayerZero gas estimation
   - Add transaction monitoring

3. **Mainnet Preparation**
   - Replace mock USDC with real USDC
   - Replace mock Yearn with real Yearn Vault
   - Configure production parameters
   - Security audit before mainnet!

---

## Resources

- **LayerZero Testnet Scan:** https://testnet.layerzeroscan.com/
- **Sepolia Explorer:** https://sepolia.etherscan.io/
- **Base Sepolia Explorer:** https://sepolia.basescan.org/
- **LayerZero Docs:** https://docs.layerzero.network/v2
- **Cast Documentation:** https://book.getfoundry.sh/reference/cast/

---

## Success Criteria

✅ Hub contracts deployed on Ethereum Sepolia  
✅ Spoke contracts deployed on Base Sepolia  
✅ Trusted remotes configured on both chains  
✅ USDC deposited on Sepolia  
✅ Shares received on Base Sepolia  
✅ USDX minted on Base Sepolia  
✅ USDX transferred back to Sepolia  

**Congratulations! Your cross-chain USDX protocol is live on testnets!** 🎉
