# USDX Protocol - Deployment Scripts Summary

## Overview

This document summarizes the deployment scripts created for deploying USDX Protocol on Ethereum Sepolia (Hub) and Base Sepolia (Spoke) testnets, including cross-chain minting and bridging demonstrations.

## Files Created

### 1. `script/DeployAndDemo.s.sol`
**Purpose:** Comprehensive deployment script for both hub and spoke chains

**Key Functions:**
- `runHub()` - Deploys all hub chain contracts on Ethereum Sepolia
- `runSpoke(address,address,address)` - Deploys spoke chain contracts on Base Sepolia
- `configureCrossChain()` - Configures LayerZero trusted remotes between chains
- `runDemo()` - Runs basic demo on hub chain

**Deploys:**
- Hub Chain: MockUSDC, MockYearnVault, USDXToken, USDXVault, USDXYearnVaultWrapper, USDXShareOFTAdapter, USDXVaultComposerSync
- Spoke Chain: USDXToken, USDXShareOFT, USDXSpokeMinter

### 2. `script/DemoCrossChain.s.sol`
**Purpose:** Comprehensive demo script showing cross-chain functionality

**Key Functions:**
- `runHubDemo()` - Demonstrates deposit, lock shares, and bridge to spoke chain
- `runSpokeDemo()` - Demonstrates receiving shares, minting USDX, transferring, and burning
- `simulateLayerZeroDelivery()` - Helper function to simulate LayerZero message delivery for testing

### 3. `scripts/deploy-and-demo.sh`
**Purpose:** Interactive shell script to orchestrate deployment and demo

**Features:**
- Interactive menu for selecting deployment steps
- Environment variable validation
- Deployment address management
- Full deployment flow automation

### 4. `DEPLOYMENT-SEPOLIA-BASE.md`
**Purpose:** Complete deployment guide with step-by-step instructions

## Deployment Flow

```
1. Deploy Hub Chain (Ethereum Sepolia)
   ├── Deploy MockUSDC
   ├── Deploy MockYearnVault
   ├── Deploy USDXToken
   ├── Deploy OVault Components
   │   ├── USDXYearnVaultWrapper
   │   ├── USDXShareOFTAdapter
   │   └── USDXVaultComposerSync
   ├── Deploy USDXVault
   ├── Grant Roles
   └── Configure LayerZero

2. Deploy Spoke Chain (Base Sepolia)
   ├── Deploy USDXToken
   ├── Deploy USDXShareOFT
   ├── Deploy USDXSpokeMinter
   ├── Grant Roles
   └── Configure LayerZero

3. Configure Cross-Chain Connections
   ├── Set trusted remotes on Hub USDXToken
   ├── Set trusted remotes on Hub ShareAdapter
   ├── Set trusted remotes on Spoke USDXToken
   └── Set trusted remotes on Spoke ShareOFT

4. Run Demo
   ├── Deposit USDC on Hub
   ├── Lock shares and bridge to Spoke
   ├── Mint USDX on Spoke
   ├── Transfer USDX
   └── Burn USDX
```

## LayerZero Configuration

### Endpoint Addresses
- **Ethereum Sepolia:** `0x6EDCE65403992e310A62460808c4b910D972f10f` (EID: 30101)
- **Base Sepolia:** `0x6EDCE65403992e310A62460808c4b910D972f10f` (EID: 30110)

### Chain IDs
- **Ethereum Sepolia:** 11155111
- **Base Sepolia:** 84532

## Environment Variables Required

```bash
# Alchemy API Key (optional - will use public RPC if not set)
ALCHEMY_API_KEY=your_alchemy_api_key

# Private Key
PRIVATE_KEY=0x...

# Hub Chain Addresses (after deployment)
HUB_USDC=0x...
HUB_YEARN_VAULT=0x...
HUB_USDX=0x...
HUB_VAULT=0x...
HUB_VAULT_WRAPPER=0x...
HUB_SHARE_ADAPTER=0x...
HUB_COMPOSER=0x...

# Spoke Chain Addresses (after deployment)
SPOKE_USDX=0x...
SPOKE_SHARE_OFT=0x...
SPOKE_MINTER=0x...
```

## Quick Start Commands

**Note:** The shell script (`scripts/deploy-and-demo.sh`) automatically builds RPC URLs from `ALCHEMY_API_KEY` or uses defaults. For manual commands, use the defaults below or set `ALCHEMY_API_KEY` and build URLs yourself.

### Deploy Hub Chain
```bash
# Option 1: Use shell script (recommended - handles RPC URLs automatically)
./scripts/deploy-and-demo.sh

# Option 2: Manual deployment
export ALCHEMY_API_KEY=your_key  # Optional
forge script script/DeployAndDemo.s.sol:DeployAndDemo \
  --rpc-url ${SEPOLIA_RPC_URL:-https://rpc.sepolia.org} \
  --broadcast \
  --sig "runHub()" \
  -vvv
```

### Deploy Spoke Chain
```bash
# Option 1: Use shell script (recommended)
./scripts/deploy-and-demo.sh

# Option 2: Manual deployment
export ALCHEMY_API_KEY=your_key  # Optional
forge script script/DeployAndDemo.s.sol:DeployAndDemo \
  --rpc-url ${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org} \
  --broadcast \
  --sig "runSpoke(address,address,address)" \
  $HUB_USDX $HUB_SHARE_ADAPTER $HUB_COMPOSER \
  -vvv
```

### Configure Cross-Chain
```bash
# Option 1: Use shell script (recommended)
./scripts/deploy-and-demo.sh

# Option 2: Manual configuration
export ALCHEMY_API_KEY=your_key  # Optional
forge script script/DeployAndDemo.s.sol:DeployAndDemo \
  --rpc-url ${SEPOLIA_RPC_URL:-https://rpc.sepolia.org} \
  --broadcast \
  --sig "configureCrossChain()" \
  -vvv
```

### Run Hub Demo
```bash
# Option 1: Use shell script (recommended)
./scripts/deploy-and-demo.sh

# Option 2: Manual demo
export ALCHEMY_API_KEY=your_key  # Optional
forge script script/DemoCrossChain.s.sol:DemoCrossChain \
  --rpc-url ${SEPOLIA_RPC_URL:-https://rpc.sepolia.org} \
  --broadcast \
  --sig "runHubDemo()" \
  -vvv
```

### Run Spoke Demo
```bash
# Option 1: Use shell script (recommended)
./scripts/deploy-and-demo.sh

# Option 2: Manual demo
export ALCHEMY_API_KEY=your_key  # Optional
forge script script/DemoCrossChain.s.sol:DemoCrossChain \
  --rpc-url ${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org} \
  --broadcast \
  --sig "runSpokeDemo()" \
  -vvv
```

## Testing Checklist

- [ ] Hub chain contracts deployed successfully
- [ ] Spoke chain contracts deployed successfully
- [ ] Cross-chain connections configured
- [ ] Can deposit USDC on hub chain
- [ ] Can lock shares in adapter
- [ ] Can bridge shares to spoke chain
- [ ] Can receive shares on spoke chain
- [ ] Can mint USDX using shares
- [ ] Can transfer USDX
- [ ] Can burn USDX
- [ ] Contracts verified on block explorers

## Notes

1. **LayerZero Messages:** In testnet, LayerZero messages may take a few minutes to deliver. For testing, you can use `simulateLayerZeroDelivery()` function.

2. **Mock Contracts:** The deployment uses MockUSDC and MockYearnVault for testing. Replace with real addresses for mainnet.

3. **Gas Costs:** Ensure you have sufficient testnet ETH on both chains for deployment and transactions.

4. **Trusted Remotes:** After deployment, trusted remotes must be configured on both chains for cross-chain communication to work.

5. **Demo Limitations:** The demo scripts simulate some LayerZero functionality. In production, LayerZero handles message delivery automatically.

## Next Steps

1. Deploy contracts using the scripts
2. Verify contracts on block explorers
3. Test cross-chain functionality
4. Update frontend with deployed addresses
5. Document any issues or improvements needed

## Support

For issues or questions:
1. Check `DEPLOYMENT-SEPOLIA-BASE.md` for detailed troubleshooting
2. Review deployment logs with `-vvv` flag
3. Verify environment variables are set correctly
4. Ensure sufficient testnet funds on both chains
