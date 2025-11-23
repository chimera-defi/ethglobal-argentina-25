# USDX Smart Contracts

## 🎯 Quick Demo (For Investors & Presentations)

**Want to see the protocol in action?**

```bash
./run-demo.sh
```

This runs a complete end-to-end test showing:
- ✅ Deposit USDC on Ethereum
- ✅ Cross-chain bridge via LayerZero
- ✅ Mint USDX on Polygon
- ✅ Use USDX (transfers, DeFi)
- ✅ Burn and redeem with yield

**Demo Duration**: ~10 seconds | **Output**: Beautiful verbose logging  
**Documentation**: See [DEMO-QUICK-START.md](../docs/DEMO-QUICK-START.md) or [Integration Test Demo Guide](../docs/integration-test-demo.md)

---

## For Smart Contracts Agent

**📖 Start Here**: **[../docs/21-smart-contract-development-setup.md](../docs/21-smart-contract-development-setup.md)**

## Quick Setup

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Install Hardhat

```bash
npm install
```

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env with your RPC URLs and private keys
```

### 4. Install Dependencies

```bash
# Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install LayerZero-Labs/layerzero-contracts
forge install hyperlane-xyz/hyperlane-monorepo

# Update remappings
forge remappings > remappings.txt
```

### 5. Test Setup

```bash
# Test Foundry
forge test

# Test Hardhat
npx hardhat test

# Test mainnet forking
forge test --fork-url $MAINNET_RPC_URL
```

## Project Structure

```
contracts/
├── contracts/
│   ├── core/
│   │   ├── USDXToken.sol
│   │   ├── USDXVault.sol
│   │   ├── USDXSpokeMinter.sol
│   │   └── CrossChainBridge.sol
│   ├── adapters/
│   │   ├── LayerZeroAdapter.sol
│   │   └── HyperlaneAdapter.sol
│   └── interfaces/
├── test/
│   ├── forge/              # Foundry tests
│   └── hardhat/            # Hardhat tests
├── script/
│   ├── deploy/             # Deployment scripts
│   └── fork/               # Fork test scripts
├── foundry.toml
├── hardhat.config.ts
└── package.json
```

## Development Workflow

### Week 2: Core Contracts

1. **USDXToken.sol**
   - ERC20 implementation
   - Mint/burn functions
   - Access control
   - Pause mechanism

2. **USDXVault.sol**
   - Deposit/withdrawal logic
   - OVault/Yield Routes integration
   - Collateral tracking

### Week 3: Integration Contracts

1. **OVault Integration**
   - Research OVault contracts
   - Integrate into USDXVault
   - Test with Yearn vault

2. **Yield Routes Integration**
   - Research Yield Routes contracts
   - Integrate into USDXVault
   - Test with Yearn vault

### Week 4-5: Cross-Chain

1. **LayerZeroAdapter.sol**
   - OApp implementation
   - Message handling

2. **HyperlaneAdapter.sol**
   - Mailbox integration
   - ISM configuration

3. **CrossChainBridge.sol**
   - Bridge orchestration
   - Message routing

### Week 6-7: Testing & Security

- Unit tests (90%+ coverage)
- Fork tests (mainnet)
- Fuzz tests
- Invariant tests
- Gas optimization
- Security review

## Key Commands

```bash
# Foundry
forge build                    # Compile contracts
forge test                     # Run tests
forge test --fork-url $RPC    # Fork tests
forge test --gas-report        # Gas report
forge coverage                 # Coverage report
forge script script/Deploy.s.sol --rpc-url $RPC --broadcast

# Hardhat
npx hardhat compile            # Compile contracts
npx hardhat test               # Run tests
npx hardhat test --network hardhat  # Fork tests
npx hardhat run script/deploy.ts --network sepolia
```

## Testing Strategy

1. **Unit Tests** (Foundry)
   - Test individual functions
   - Test access control
   - Test edge cases

2. **Fork Tests** (Foundry)
   - Test with real contracts
   - Test with real data
   - Test integrations

3. **Integration Tests** (Hardhat)
   - Test cross-contract interactions
   - Test end-to-end flows

4. **Fuzz Tests** (Foundry)
   - Fuzz all public functions
   - Catch edge cases

5. **Invariant Tests** (Foundry)
   - Test protocol invariants
   - Test state consistency

## Mainnet Forking

### Foundry

```bash
# Fork mainnet
forge test --fork-url $MAINNET_RPC_URL

# Fork at specific block
forge test --fork-url $MAINNET_RPC_URL --fork-block-number 18000000
```

### Hardhat

Configure in `hardhat.config.ts`:
```typescript
hardhat: {
  forking: {
    url: process.env.MAINNET_RPC_URL || "",
    enabled: true,
  },
}
```

## Resources

- **[Setup Guide](../docs/21-smart-contract-development-setup.md)** - Complete setup instructions
- **[Task Breakdown](../docs/22-detailed-task-breakdown.md)** - Phase 2 detailed tasks
- **[Technical Spec](../docs/05-technical-specification.md)** - Contract interfaces
- **[Architecture](../docs/02-architecture.md)** - System architecture

## Next Steps

1. ✅ Read setup guide
2. ✅ Set up Foundry + Hardhat
3. ✅ Configure mainnet forking
4. ⏳ Start with USDXToken.sol
