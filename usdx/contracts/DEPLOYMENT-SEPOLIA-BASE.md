# USDX Protocol - Deployment Guide for Ethereum Sepolia & Base Sepolia

Complete guide for deploying USDX Protocol contracts on Ethereum Sepolia (Hub) and Base Sepolia (Spoke) testnets, including cross-chain minting and bridging demo.

## 📋 Prerequisites

### 1. Environment Setup

Create a `.env` file in the `contracts/` directory:

```bash
# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Deployment wallet private key (NEVER commit this!)
PRIVATE_KEY=0x0000000000000000000000000000000000000000000000000000000000000000

# Optional: Contract addresses (if redeploying)
HUB_USDX=0x...
HUB_VAULT=0x...
HUB_SHARE_ADAPTER=0x...
HUB_COMPOSER=0x...
SPOKE_USDX=0x...
SPOKE_SHARE_OFT=0x...
SPOKE_MINTER=0x...
```

### 2. Get Testnet Funds

**Sepolia ETH:**
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

**Base Sepolia ETH:**
- https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
- https://faucet.quicknode.com/base/sepolia

### 3. Install Dependencies

```bash
cd contracts
forge install
```

---

## 🚀 Quick Start

### Option 1: Interactive Script (Recommended)

```bash
cd contracts
./scripts/deploy-and-demo.sh
```

This will guide you through:
1. Deploying Hub Chain (Ethereum Sepolia)
2. Deploying Spoke Chain (Base Sepolia)
3. Configuring Cross-Chain Connections
4. Running Demo

### Option 2: Manual Deployment

#### Step 1: Deploy Hub Chain (Ethereum Sepolia)

```bash
cd contracts
forge script script/DeployAndDemo.s.sol:DeployAndDemo \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --sig "runHub()" \
  -vvv
```

**Expected Output:**
```
=== Hub Chain Deployment Complete ===
Contracts:
  MockUSDC: 0x...
  MockYearnVault: 0x...
  USDXToken: 0x...
  USDXVault: 0x...
  USDXYearnVaultWrapper: 0x...
  USDXShareOFTAdapter: 0x...
  USDXVaultComposerSync: 0x...
```

**Save these addresses!** Export them as environment variables:

```bash
export HUB_USDC=0x...
export HUB_YEARN_VAULT=0x...
export HUB_USDX=0x...
export HUB_VAULT=0x...
export HUB_VAULT_WRAPPER=0x...
export HUB_SHARE_ADAPTER=0x...
export HUB_COMPOSER=0x...
```

#### Step 2: Deploy Spoke Chain (Base Sepolia)

```bash
forge script script/DeployAndDemo.s.sol:DeployAndDemo \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --sig "runSpoke(address,address,address)" \
  $HUB_USDX $HUB_SHARE_ADAPTER $HUB_COMPOSER \
  -vvv
```

**Expected Output:**
```
=== Spoke Chain Deployment Complete ===
Contracts:
  USDXToken: 0x...
  USDXShareOFT: 0x...
  USDXSpokeMinter: 0x...
```

**Save these addresses:**

```bash
export SPOKE_USDX=0x...
export SPOKE_SHARE_OFT=0x...
export SPOKE_MINTER=0x...
```

#### Step 3: Configure Cross-Chain Connections

```bash
# Configure trusted remotes on hub chain
forge script script/DeployAndDemo.s.sol:DeployAndDemo \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --sig "configureCrossChain()" \
  -vvv
```

#### Step 4: Run Demo

**Hub Chain Demo (Deposit & Bridge):**

```bash
forge script script/DemoCrossChain.s.sol:DemoCrossChain \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --sig "runHubDemo()" \
  -vvv
```

**Spoke Chain Demo (Mint & Use USDX):**

```bash
forge script script/DemoCrossChain.s.sol:DemoCrossChain \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --sig "runSpokeDemo()" \
  -vvv
```

---

## 🔍 Verification

### Check Contracts on Block Explorers

**Ethereum Sepolia:**
- https://sepolia.etherscan.io/address/YOUR_ADDRESS

**Base Sepolia:**
- https://sepolia.basescan.org/address/YOUR_ADDRESS

### Verify Contract Code

```bash
# Verify on Etherscan
forge verify-contract \
  --chain-id 11155111 \
  --compiler-version v0.8.23 \
  --optimizer-runs 200 \
  CONTRACT_ADDRESS \
  contracts/USDXToken.sol:USDXToken \
  --constructor-args $(cast abi-encode "constructor(address)" "ADMIN_ADDRESS") \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Verify on Basescan
forge verify-contract \
  --chain-id 84532 \
  --compiler-version v0.8.23 \
  --optimizer-runs 200 \
  CONTRACT_ADDRESS \
  contracts/USDXToken.sol:USDXToken \
  --constructor-args $(cast abi-encode "constructor(address)" "ADMIN_ADDRESS") \
  --etherscan-api-key $BASESCAN_API_KEY
```

---

## 🧪 Testing Cross-Chain Functionality

### Complete Flow Test

1. **Deposit USDC on Hub Chain**
   ```bash
   cast send $HUB_VAULT "deposit(uint256)" "1000000000" \
     --rpc-url $SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY
   ```

2. **Lock Shares and Bridge to Base Sepolia**
   ```bash
   # Get wrapper shares balance
   cast call $HUB_VAULT_WRAPPER "balanceOf(address)(uint256)" $YOUR_ADDRESS \
     --rpc-url $SEPOLIA_RPC_URL
   
   # Lock shares
   cast send $HUB_SHARE_ADAPTER "lockShares(uint256)" "SHARES_AMOUNT" \
     --rpc-url $SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY
   
   # Bridge to Base Sepolia
   cast send $HUB_SHARE_ADAPTER "send(uint32,bytes32,uint256,bytes)" \
     30110 \
     $(cast --to-bytes32 $(cast --to-uint256 $YOUR_ADDRESS)) \
     "BRIDGE_AMOUNT" \
     "" \
     --rpc-url $SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY \
     --value 0.001ether
   ```

3. **Mint USDX on Base Sepolia**
   ```bash
   # Approve shares
   cast send $SPOKE_SHARE_OFT "approve(address,uint256)" $SPOKE_MINTER "AMOUNT" \
     --rpc-url $BASE_SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY
   
   # Mint USDX
   cast send $SPOKE_MINTER "mintUSDXFromOVault(uint256)" "AMOUNT" \
     --rpc-url $BASE_SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY
   ```

4. **Transfer USDX Cross-Chain**
   ```bash
   cast send $SPOKE_USDX "sendCrossChain(uint32,bytes32,uint256,bytes)" \
     30101 \
     $(cast --to-bytes32 $(cast --to-uint256 $YOUR_ADDRESS)) \
     "AMOUNT" \
     "" \
     --rpc-url $BASE_SEPOLIA_RPC_URL \
     --private-key $PRIVATE_KEY \
     --value 0.001ether
   ```

---

## 📊 LayerZero Configuration

### Endpoint Addresses

- **Ethereum Sepolia:** `0x6EDCE65403992e310A62460808c4b910D972f10f` (EID: 30101)
- **Base Sepolia:** `0x6EDCE65403992e310A62460808c4b910D972f10f` (EID: 30110)

### Trusted Remotes

After deployment, trusted remotes are automatically configured:
- Hub USDXToken ↔ Spoke USDXToken
- Hub ShareOFTAdapter ↔ Spoke ShareOFT

---

## 🐛 Troubleshooting

### Issue: "Insufficient funds for gas"
**Solution:** Get more testnet ETH from faucets

### Issue: "Contract not found"
**Solution:** Ensure you've deployed contracts and set environment variables

### Issue: "LayerZero message not delivered"
**Solution:** 
- In testnet, LayerZero messages may take a few minutes
- Check LayerZero explorer: https://layerzeroscan.com/
- For testing, you can manually trigger `lzReceive` on destination contract

### Issue: "Trusted remote not set"
**Solution:** Run `configureCrossChain()` script to set trusted remotes

### Issue: "Shares not received on spoke chain"
**Solution:** 
- Verify LayerZero message was sent (check LayerZero explorer)
- Ensure trusted remotes are configured correctly
- For demo, you can use `simulateLayerZeroDelivery()` function

---

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Environment variables set (.env file)
- [ ] Testnet funds available (both chains)
- [ ] Foundry installed and configured
- [ ] Dependencies installed (`forge install`)

### Hub Chain Deployment
- [ ] MockUSDC deployed
- [ ] MockYearnVault deployed
- [ ] USDXToken deployed
- [ ] USDXVault deployed
- [ ] OVault components deployed (Wrapper, Adapter, Composer)
- [ ] Roles granted (MINTER_ROLE, BURNER_ROLE)
- [ ] LayerZero endpoint configured
- [ ] Addresses saved

### Spoke Chain Deployment
- [ ] USDXToken deployed
- [ ] USDXShareOFT deployed
- [ ] USDXSpokeMinter deployed
- [ ] Roles granted
- [ ] LayerZero endpoint configured
- [ ] Trusted remotes set
- [ ] Addresses saved

### Post-Deployment
- [ ] Cross-chain connections configured
- [ ] Contracts verified on block explorers
- [ ] Demo tested successfully
- [ ] Documentation updated with addresses

---

## 🔐 Security Notes

⚠️ **IMPORTANT:** These are testnet deployments for demonstration purposes only.

**For mainnet deployment:**
1. Complete security audit
2. Use multi-sig wallets for admin roles
3. Verify all addresses manually
4. Test extensively on testnets
5. Use real USDC and Yearn vault addresses (not mocks)
6. Set proper treasury addresses
7. Review all permissions and roles

---

## 📚 Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [LayerZero Documentation](https://docs.layerzero.network/)
- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Ethereum Sepolia Explorer](https://sepolia.etherscan.io/)
- [LayerZero Explorer](https://layerzeroscan.com/)

---

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review contract deployment logs (`-vvv` flag)
3. Verify environment variables are set correctly
4. Ensure you have sufficient testnet funds
5. Check LayerZero message status on LayerZero explorer

---

**Last Updated:** 2025-01-27  
**Version:** 1.0.0
