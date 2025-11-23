# USDX Smart Contracts

## For Smart Contracts Agent

**📖 Start Here**: **[../docs/21-smart-contract-development-setup.md](../docs/21-smart-contract-development-setup.md)**

## Quick Setup

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Install Hardhat3

```bash
npm install
```

**Note**: This project uses Hardhat3 (v3.0.15) alongside Foundry. See [Hardhat3 Integration Guide](../docs/hardhat3-integration-guide.md) for details.

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

### 5. Local Testnet Setup

**Quick Setup** (recommended):
```bash
npm run setup:local
```

This single command will:
- Deploy all mock contracts (USDC, Yearn Vault, LayerZero)
- Deploy USDX contracts (Token and Vault)
- Set up all permissions
- Fund a user account with ETH, USDC, and USDX
- Report all addresses and balances

See [Hardhat Ignition Deployment Guide](../docs/hardhat-ignition-deployment-guide.md) for details.

### 6. Test Setup

```bash
# Test Foundry
npm run test:foundry
# or
forge test

# Test Hardhat3
npm run test
# or
npx hardhat test

# Test both
npm run test:all

# Test mainnet forking
forge test --fork-url $MAINNET_RPC_URL
# or
npm run test:fork
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
│   ├── forge/              # Foundry tests (*.t.sol)
│   └── hardhat/            # Hardhat3 tests (*.test.sol)
├── script/                 # Foundry deployment scripts (*.s.sol)
├── scripts/                # Hardhat scripts (*.ts)
│   └── setup-local-testnet.ts  # Local testnet setup
├── ignition/
│   └── modules/           # Hardhat Ignition modules (*.ts)
│       ├── DeployMocks.ts
│       ├── DeployHub.ts
│       └── LocalTestnetSetup.ts
├── foundry.toml            # Foundry configuration
├── hardhat.config.ts      # Hardhat3 configuration
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

# Hardhat3
npm run compile                # Compile contracts
npm run test                   # Run Hardhat3 tests
npm run test:fork              # Fork tests
npm run verify                 # Verify contracts

# Hardhat Ignition (deployment)
npm run setup:local           # Complete local testnet setup
npm run deploy:mocks sepolia  # Deploy mocks only
npm run deploy:hub sepolia    # Deploy hub contracts
npm run deploy:local          # Deploy complete local setup

# Foundry
npm run compile:foundry       # Compile contracts
npm run test:foundry          # Run Foundry tests
forge script script/DeployHub.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
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
- **[Hardhat Ignition Deployment Guide](../docs/hardhat-ignition-deployment-guide.md)** - Deployment with Ignition
- **[Hardhat3 Integration Guide](../docs/hardhat3-integration-guide.md)** - Using Hardhat3
- **[Task Breakdown](../docs/22-detailed-task-breakdown.md)** - Phase 2 detailed tasks
- **[Technical Spec](../docs/05-technical-specification.md)** - Contract interfaces
- **[Architecture](../docs/02-architecture.md)** - System architecture

## Next Steps

1. ✅ Read setup guide
2. ✅ Set up Foundry + Hardhat
3. ✅ Configure mainnet forking
4. ⏳ Start with USDXToken.sol
