# End-to-End Integration Tests

This document describes the comprehensive end-to-end integration test suite for the USDX protocol.

## Overview

The E2E tests verify the complete flow of the USDX protocol:
1. **Deposit Flow**: User deposits USDC → receives USDX
2. **Yield Accrual**: Yield accrues over time in MockYieldVault
3. **Withdrawal Flow**: User burns USDX → receives USDC (with yield)
4. **Spoke Minter Flow**: User mints USDX on spoke chain using hub position
5. **Cross-Chain Bridge Flow**: User transfers USDX cross-chain
6. **Complete E2E Flow**: All flows combined in sequence

## Test Suites

### Hardhat Integration Tests

**Location**: `test/hardhat/E2E.integration.test.ts`

**Features**:
- Uses Hardhat 3 with TypeScript
- Supports mainnet forking (optional)
- Comprehensive test coverage
- Uses ethers.js v6
- Includes helper utilities for deployment

**Run Tests**:
```bash
cd contracts
npm run test test/hardhat/E2E.integration.test.ts
```

**Run with Mainnet Fork** (requires `MAINNET_RPC_URL` in `.env`):
```bash
npm run test:fork test/hardhat/E2E.integration.test.ts
```

### Foundry Integration Tests

**Location**: `test/forge/E2E.integration.t.sol`

**Features**:
- Pure Solidity tests
- Fast execution
- Fuzzing support
- Gas reporting

**Run Tests**:
```bash
cd contracts
forge test --match-path "test/forge/E2E.integration.t.sol" -vv
```

## Test Coverage

### 1. Complete Deposit Flow
- ✅ User deposits USDC
- ✅ Receives USDX 1:1
- ✅ Vault tracks collateral correctly
- ✅ Events emitted correctly
- ✅ Collateral ratio maintained at 1:1

### 2. Yield Accrual
- ✅ Yield accrues over time
- ✅ Shares remain constant
- ✅ Assets increase with yield
- ✅ Yield calculation correct

### 3. Complete Withdrawal Flow
- ✅ User burns USDX
- ✅ Receives USDC (with yield)
- ✅ Vault collateral decreases
- ✅ Prevents insufficient collateral withdrawal

### 4. Cross-Chain Spoke Minter Flow
- ✅ Relayer mints USDX on spoke chain
- ✅ Uses hub chain position as collateral
- ✅ Prevents double minting (replay protection)
- ✅ Prevents minting if insufficient hub position

### 5. Cross-Chain Bridge Flow
- ✅ User initiates cross-chain transfer
- ✅ USDX burned on source chain
- ✅ Relayer completes transfer
- ✅ USDX minted on destination chain
- ✅ Prevents duplicate transfer completion

### 6. Complete End-to-End Flow
- ✅ Deposit → Yield → Spoke Mint → Bridge → Withdraw
- ✅ All flows work together correctly
- ✅ State maintained correctly throughout

### 7. Edge Cases and Security
- ✅ Reentrancy protection
- ✅ Total supply tracking
- ✅ Multiple users handled correctly

## Test Architecture

### Contract Deployment Order

1. **MockUSDC** - ERC20 token (6 decimals)
2. **USDXToken** - ERC20 token (18 decimals)
3. **MockYieldVault** - Simulates yield accrual
4. **USDXVault** - Main vault contract
5. **USDXSpokeMinter** - Spoke chain minter
6. **CrossChainBridge** - Cross-chain bridge

### Role Setup

- **Admin**: Grants roles, manages contracts
- **Relayer**: Completes cross-chain operations
- **Users**: Interact with protocol

### Helper Utilities

**Location**: `test/hardhat/helpers/deploy.ts`

- `deployUSDXContracts()` - Deploys all contracts
- `setupTestEnvironment()` - Sets up test users with funds

## Running Tests

### Hardhat Tests

```bash
# Run all Hardhat tests
npm run test

# Run only E2E tests
npm run test test/hardhat/E2E.integration.test.ts

# Run with mainnet fork
npm run test:fork test/hardhat/E2E.integration.test.ts

# Run with gas reporting
npm run gas
```

### Foundry Tests

```bash
# Run all Foundry tests
forge test

# Run only E2E tests
forge test --match-path "test/forge/E2E.integration.t.sol"

# Run with verbose output
forge test --match-path "test/forge/E2E.integration.t.sol" -vv

# Run with gas reporting
forge test --match-path "test/forge/E2E.integration.t.sol" --gas-report
```

## Mainnet Forking (Optional)

To test with real mainnet state:

1. Add to `.env`:
```env
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
```

2. Run tests:
```bash
npm run test:fork
```

**Note**: Forking requires an RPC provider (Alchemy, Infura, etc.)

## Test Data

### Constants

- **HUB_CHAIN_ID**: 1 (Ethereum)
- **SPOKE_CHAIN_ID**: 137 (Polygon)
- **INITIAL_USDC_AMOUNT**: 10,000 USDC per user
- **DEPOSIT_AMOUNT**: 1,000 USDC
- **WITHDRAW_AMOUNT**: 500 USDX

### Mock Contracts

- **MockUSDC**: Simulates USDC (6 decimals)
- **MockYieldVault**: Simulates yield accrual (5% APY)

## Expected Test Results

### Hardhat Tests
- ✅ ~15-20 test cases
- ✅ All should pass
- ✅ Gas reporting available

### Foundry Tests
- ✅ ~10-12 test cases
- ✅ All should pass
- ✅ Fast execution (< 5 seconds)

## Troubleshooting

### TypeScript Errors
```bash
npm install --legacy-peer-deps
npm run compile
```

### Missing Typechain Types
```bash
npm run compile  # Generates typechain types
```

### Foundry Errors
```bash
forge install OpenZeppelin/openzeppelin-contracts
forge build
```

## Future Enhancements

1. **Mainnet Fork Tests**: Test with real USDC and Yearn vault
2. **Gas Optimization Tests**: Compare gas costs
3. **Fuzzing**: Add Foundry fuzzing for edge cases
4. **Load Testing**: Test with many concurrent users
5. **Integration with Real Bridges**: Test LayerZero/Hyperlane when available

## Related Documentation

- [Architecture](./docs/02-architecture.md)
- [Technical Specification](./docs/05-technical-specification.md)
- [Unit Tests](./test/forge/README.md)
