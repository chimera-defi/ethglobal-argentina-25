# USDX Protocol - Deployment Guide

Complete guide for deploying USDX contracts to testnet and mainnet.

---

## 📋 Prerequisites

### 1. Environment Setup

Create a `.env` file in the `contracts/` directory:

```bash
# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
MUMBAI_RPC_URL=https://polygon-mumbai.g.alchemy.com/v2/YOUR_API_KEY
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/YOUR_API_KEY

# Deployment wallet private key (NEVER commit this!)
PRIVATE_KEY=0x0000000000000000000000000000000000000000000000000000000000000000

# Etherscan API keys (for verification)
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_API_KEY
```

### 2. Get Testnet Funds

**Sepolia ETH:**
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

**Mumbai MATIC:**
- https://faucet.polygon.technology/
- https://mumbaifaucet.com/

---

## 🧪 Testnet Deployment

### Step 1: Deploy Mock Contracts (Sepolia Only)

First, deploy mock USDC and Yearn vault on Sepolia:

```bash
cd contracts

# Deploy mocks
forge script script/DeployMocks.s.sol:DeployMocks \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Expected Output:**
```
MockUSDC: 0x...
MockYearnVault: 0x...
```

**Save these addresses!** You'll need them for the next step.

---

### Step 2: Deploy Hub Chain Contracts (Sepolia)

Update `script/DeployHub.s.sol` with your mock USDC and Yearn addresses if needed, then:

```bash
# Deploy hub contracts
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Expected Output:**
```
USDXToken: 0x...
USDXVault: 0x...
```

**Save these addresses!**

---

### Step 3: Deploy Spoke Chain Contracts (Mumbai)

```bash
# Deploy spoke contracts
forge script script/DeploySpoke.s.sol:DeploySpoke \
  --rpc-url $MUMBAI_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Expected Output:**
```
USDXToken: 0x...
USDXSpokeMinter: 0x...
Position Oracle: 0x...
```

---

### Step 4: Verify Deployments

Check contracts on block explorers:

**Sepolia (Ethereum):**
- https://sepolia.etherscan.io/address/YOUR_ADDRESS

**Mumbai (Polygon):**
- https://mumbai.polygonscan.com/address/YOUR_ADDRESS

---

## 🚀 Mainnet Deployment

⚠️ **CRITICAL: DO NOT deploy to mainnet without:**
1. ✅ Complete security audit
2. ✅ Extensive testnet testing
3. ✅ Multi-sig setup for admin
4. ✅ Proper treasury address configured
5. ✅ Real Yearn vault address verified

### Mainnet Checklist

- [ ] Security audit completed
- [ ] All testnet tests passed
- [ ] Multi-sig wallet deployed
- [ ] Treasury address confirmed
- [ ] Real USDC addresses verified (not test tokens!)
- [ ] Real Yearn vault addresses verified
- [ ] Gas price checked (deploy at low gas times)
- [ ] Team coordination confirmed

### Mainnet Deployment Steps

**1. Deploy to Ethereum Mainnet:**

```bash
# Make sure you have MAINNET_RPC_URL and real addresses in script/DeployHub.s.sol
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify \
  --slow \
  -vvvv
```

**2. Deploy to Polygon Mainnet:**

```bash
forge script script/DeploySpoke.s.sol:DeploySpoke \
  --rpc-url $POLYGON_RPC_URL \
  --broadcast \
  --verify \
  --slow \
  -vvvv
```

---

## 🔐 Post-Deployment Security

### 1. Transfer Admin to Multi-Sig

**DO THIS IMMEDIATELY after deployment!**

```solidity
// On Hub Chain
usdxToken.grantRole(DEFAULT_ADMIN_ROLE, MULTISIG_ADDRESS);
usdxToken.revokeRole(DEFAULT_ADMIN_ROLE, DEPLOYER_ADDRESS);

vault.grantRole(DEFAULT_ADMIN_ROLE, MULTISIG_ADDRESS);
vault.revokeRole(DEFAULT_ADMIN_ROLE, DEPLOYER_ADDRESS);

// On Spoke Chain
spokeUSDX.grantRole(DEFAULT_ADMIN_ROLE, MULTISIG_ADDRESS);
spokeUSDX.revokeRole(DEFAULT_ADMIN_ROLE, DEPLOYER_ADDRESS);

spokeMinter.grantRole(DEFAULT_ADMIN_ROLE, MULTISIG_ADDRESS);
spokeMinter.revokeRole(DEFAULT_ADMIN_ROLE, DEPLOYER_ADDRESS);
```

### 2. Verify All Permissions

```bash
# Check roles on USDXToken (hub)
cast call HUB_USDX_ADDRESS "hasRole(bytes32,address)(bool)" \
  "MINTER_ROLE" "VAULT_ADDRESS" \
  --rpc-url $RPC_URL

# Check roles on USDXSpokeMinter
cast call SPOKE_MINTER_ADDRESS "hasRole(bytes32,address)(bool)" \
  "POSITION_UPDATER_ROLE" "ORACLE_ADDRESS" \
  --rpc-url $RPC_URL
```

### 3. Test Basic Operations

```bash
# Deposit on hub
cast send VAULT_ADDRESS "deposit(uint256)" "1000000" \
  --rpc-url $RPC_URL \
  --private-key $TEST_PRIVATE_KEY

# Mint on spoke (after position sync)
cast send SPOKE_MINTER_ADDRESS "mint(uint256)" "500000" \
  --rpc-url $RPC_URL \
  --private-key $TEST_PRIVATE_KEY
```

---

## 📝 Deployment Addresses Template

Create a `deployments.json` file:

```json
{
  "testnet": {
    "sepolia": {
      "chainId": 11155111,
      "mockUSDC": "0x...",
      "mockYearnVault": "0x...",
      "usdxToken": "0x...",
      "vault": "0x...",
      "deployer": "0x...",
      "treasury": "0x..."
    },
    "mumbai": {
      "chainId": 80001,
      "usdxToken": "0x...",
      "spokeMinter": "0x...",
      "positionOracle": "0x...",
      "deployer": "0x..."
    }
  },
  "mainnet": {
    "ethereum": {
      "chainId": 1,
      "usdc": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
      "yearnVault": "0xBe53A109B494E5c9f97b9Cd39Fe969BE68BF6204",
      "usdxToken": "0x...",
      "vault": "0x...",
      "deployer": "0x...",
      "treasury": "0x...",
      "multisig": "0x..."
    },
    "polygon": {
      "chainId": 137,
      "usdxToken": "0x...",
      "spokeMinter": "0x...",
      "positionOracle": "0x...",
      "deployer": "0x...",
      "multisig": "0x..."
    }
  }
}
```

---

## 🧰 Useful Commands

### Check Contract Code

```bash
# Get contract code
cast code ADDRESS --rpc-url $RPC_URL

# Check if contract is verified
# Visit Etherscan/Polygonscan and search for address
```

### Manual Verification

If auto-verification fails:

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
```

### Grant Roles

```bash
# Grant MINTER_ROLE
cast send TOKEN_ADDRESS "grantRole(bytes32,address)" \
  $(cast keccak "MINTER_ROLE") \
  MINTER_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Grant POSITION_UPDATER_ROLE
cast send MINTER_ADDRESS "grantRole(bytes32,address)" \
  $(cast keccak "POSITION_UPDATER_ROLE") \
  ORACLE_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### Check Balances

```bash
# Check USDX balance
cast call USDX_ADDRESS "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url $RPC_URL

# Check vault collateral
cast call VAULT_ADDRESS "totalCollateral()(uint256)" --rpc-url $RPC_URL

# Check spoke minted amount
cast call MINTER_ADDRESS "totalMinted()(uint256)" --rpc-url $RPC_URL
```

---

## 🚨 Emergency Procedures

### Pause Contracts

```bash
# Pause vault
cast send VAULT_ADDRESS "pause()" \
  --rpc-url $RPC_URL \
  --private-key $ADMIN_PRIVATE_KEY

# Pause spoke minter
cast send MINTER_ADDRESS "pause()" \
  --rpc-url $RPC_URL \
  --private-key $ADMIN_PRIVATE_KEY

# Pause USDX token
cast send USDX_ADDRESS "pause()" \
  --rpc-url $RPC_URL \
  --private-key $ADMIN_PRIVATE_KEY
```

### Unpause Contracts

```bash
# Unpause vault
cast send VAULT_ADDRESS "unpause()" \
  --rpc-url $RPC_URL \
  --private-key $ADMIN_PRIVATE_KEY
```

---

## 📊 Gas Cost Estimates

Based on test runs:

| Operation | Gas Cost | ETH (50 gwei) | USD ($3000 ETH) |
|-----------|----------|---------------|-----------------|
| Deploy USDXToken | ~2M | 0.10 ETH | $300 |
| Deploy USDXVault | ~3M | 0.15 ETH | $450 |
| Deploy SpokeMinter | ~2M | 0.10 ETH | $300 |
| Deposit | ~190k | 0.0095 ETH | $28.50 |
| Withdraw | ~230k | 0.0115 ETH | $34.50 |
| Mint (spoke) | ~155k | 0.00775 ETH | $23.25 |
| **Total Deployment** | **~7M** | **~0.35 ETH** | **~$1050** |

*Note: Prices are estimates and vary with gas prices and ETH price.*

---

## 🔍 Troubleshooting

### Issue: "Insufficient funds for gas"
**Solution:** Get more testnet ETH/MATIC from faucets

### Issue: "Nonce too low"
**Solution:** 
```bash
# Reset nonce
cast nonce YOUR_ADDRESS --rpc-url $RPC_URL
```

### Issue: "Contract verification failed"
**Solution:** Manually verify using the commands in the "Manual Verification" section

### Issue: "Transaction reverted"
**Solution:** Add `-vvvv` flag to see detailed error messages

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] All tests passing (53/53)
- [ ] Environment variables set
- [ ] Testnet funds available
- [ ] Addresses configured in scripts
- [ ] Treasury address confirmed

### During Deployment
- [ ] Deploy mocks (testnet only)
- [ ] Deploy hub contracts
- [ ] Deploy spoke contracts
- [ ] Save all addresses
- [ ] Verify all contracts

### Post-Deployment
- [ ] Test deposit operation
- [ ] Test withdrawal operation
- [ ] Test spoke minting
- [ ] Verify permissions
- [ ] Transfer to multi-sig (mainnet)
- [ ] Document all addresses
- [ ] Update frontend config

---

## 📚 Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Script Documentation](https://book.getfoundry.sh/tutorials/solidity-scripting)
- [Cast Reference](https://book.getfoundry.sh/reference/cast/)
- [Etherscan API](https://docs.etherscan.io/)
- [Alchemy API](https://docs.alchemy.com/)

---

**Last Updated**: 2025-11-22
**Version**: 1.0.0 (MVP)
