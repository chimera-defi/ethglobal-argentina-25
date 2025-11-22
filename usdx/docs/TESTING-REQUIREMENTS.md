# Testing Requirements

## Overview

This document outlines the comprehensive testing requirements for the LayerZero integration. Tests should achieve >90% code coverage before mainnet deployment.

## Test Structure

### Unit Tests (Foundry)

#### USDXYearnVaultWrapper
- ✅ Basic deposit functionality
- ✅ Basic redeem functionality  
- ✅ Zero amount/address validation
- ✅ Pause/unpause functionality
- ✅ Conversion functions
- ⚠️ **TODO**: Test with actual Yearn vault (fork test)
- ⚠️ **TODO**: Test yield accrual over time
- ⚠️ **TODO**: Test edge cases (very large amounts, rounding)

#### USDXShareOFTAdapter
- ⚠️ **TODO**: Test lockShares
- ⚠️ **TODO**: Test unlockShares
- ⚠️ **TODO**: Test lockSharesFrom
- ⚠️ **TODO**: Test unlockSharesFor
- ⚠️ **TODO**: Test cross-chain send
- ⚠️ **TODO**: Test lzReceive (mock LayerZero endpoint)
- ⚠️ **TODO**: Test trusted remote verification
- ⚠️ **TODO**: Test unauthorized access attempts

#### USDXVaultComposerSync
- ⚠️ **TODO**: Test deposit flow end-to-end
- ⚠️ **TODO**: Test redeem flow end-to-end
- ⚠️ **TODO**: Test operation ID collision prevention
- ⚠️ **TODO**: Test invalid trusted remote
- ⚠️ **TODO**: Test reentrancy protection
- ⚠️ **TODO**: Test with insufficient balances
- ⚠️ **TODO**: Test lzReceive handling

#### USDXToken
- ⚠️ **TODO**: Test sendCrossChain
- ⚠️ **TODO**: Test lzReceive with valid message
- ⚠️ **TODO**: Test lzReceive with invalid sender
- ⚠️ **TODO**: Test lzReceive with zero address user
- ⚠️ **TODO**: Test trusted remote updates
- ⚠️ **TODO**: Test LayerZero endpoint updates

#### USDXShareOFT
- ⚠️ **TODO**: Test mint (with minter role)
- ⚠️ **TODO**: Test burn
- ⚠️ **TODO**: Test send cross-chain
- ⚠️ **TODO**: Test lzReceive
- ⚠️ **TODO**: Test minter updates

#### USDXSpokeMinter
- ⚠️ **TODO**: Test mintUSDXFromOVault
- ⚠️ **TODO**: Test mint with insufficient shares
- ⚠️ **TODO**: Test burn
- ⚠️ **TODO**: Test getAvailableMintAmount
- ⚠️ **TODO**: Test getUserOVaultShares

#### USDXVault
- ⚠️ **TODO**: Test deposit with OVault wrapper
- ⚠️ **TODO**: Test depositViaOVault
- ⚠️ **TODO**: Test withdrawal
- ⚠️ **TODO**: Test OVault integration
- ⚠️ **TODO**: Test fallback to direct Yearn

### Integration Tests

#### Cross-Chain Flow Tests
- ⚠️ **TODO**: Full deposit flow: User → Hub → OVault → Spoke
- ⚠️ **TODO**: Full mint flow: Spoke → USDX mint
- ⚠️ **TODO**: Full redeem flow: Spoke → Hub → USDC
- ⚠️ **TODO**: Cross-chain USDX transfer: Chain A → Chain B
- ⚠️ **TODO**: Multiple users, multiple chains
- ⚠️ **TODO**: Concurrent operations

#### LayerZero Integration Tests
- ⚠️ **TODO**: Test with mock LayerZero endpoint
- ⚠️ **TODO**: Test message delivery
- ⚠️ **TODO**: Test message failure handling
- ⚠️ **TODO**: Test trusted remote configuration
- ⚠️ **TODO**: Test endpoint updates

### Fork Tests

- ⚠️ **TODO**: Test with real Yearn vault on mainnet fork
- ⚠️ **TODO**: Test with real LayerZero endpoints (testnet)
- ⚠️ **TODO**: Test gas costs
- ⚠️ **TODO**: Test with various amounts

### Security Tests

- ⚠️ **TODO**: Reentrancy attack tests
- ⚠️ **TODO**: Access control tests
- ⚠️ **TODO**: Input validation tests
- ⚠️ **TODO**: Overflow/underflow tests
- ⚠️ **TODO**: Front-running tests
- ⚠️ **TODO**: DoS attack tests

## Test Coverage Goals

- **Unit Tests**: >90% coverage
- **Integration Tests**: All major flows covered
- **Security Tests**: All critical paths tested
- **Fork Tests**: Real-world scenarios validated

## Test Execution

### Foundry Tests
```bash
forge test --coverage
forge test --gas-report
```

### Hardhat Tests (when dependencies installed)
```bash
npm test
npm run coverage
```

## Mock Contracts Needed

1. ✅ MockUSDC - Already exists
2. ✅ MockYearnVault - Already exists
3. ⚠️ **TODO**: MockLayerZeroEndpoint
4. ⚠️ **TODO**: MockLayerZeroExecutor

## Test Data

- Small amounts: 1e6 (1 USDC)
- Medium amounts: 1000e6 (1,000 USDC)
- Large amounts: 1000000e6 (1,000,000 USDC)
- Edge cases: type(uint256).max, 0, 1

## Notes

- Tests should be deterministic
- Use foundry's `vm` cheatcodes for time manipulation
- Mock external dependencies
- Test both success and failure paths
- Test edge cases and boundary conditions
