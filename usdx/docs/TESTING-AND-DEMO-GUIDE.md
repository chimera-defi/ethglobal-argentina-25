# USDX Protocol Testing and Demo Guide

## Overview

This document provides a comprehensive guide for testing and demonstrating the USDX Protocol with LayerZero OVault integration. The protocol enables cross-chain stablecoin minting with yield generation on USDC collateral.

## Architecture Summary

### Hub Chain (Ethereum)
- **USDXVault**: Main vault managing USDC collateral and USDX minting
- **USDXYearnVaultWrapper**: ERC-4626 wrapper for Yearn USDC vault
- **USDXShareOFTAdapter**: OFT adapter for cross-chain vault shares
- **USDXVaultComposerSync**: Orchestrates cross-chain deposit/redemption flows
- **USDXToken**: ERC-20 stablecoin with LayerZero OFT support

### Spoke Chain (Polygon/Other)
- **USDXToken**: Spoke chain USDX token
- **USDXShareOFT**: Represents vault shares on spoke chain
- **USDXSpokeMinter**: Mints USDX based on locked shares

## Testing Strategy

### 1. Unit Tests

Run all unit tests:
```bash
cd contracts
forge test
```

**Key Test Files:**
- `USDXVault.t.sol`: Vault deposit/withdraw, OVault integration
- `USDXToken.t.sol`: Token minting/burning, cross-chain transfers
- `USDXSpokeMinter.t.sol`: Spoke chain minting logic
- `USDXYearnVaultWrapper.t.sol`: ERC-4626 wrapper functionality
- `USDXShareOFTAdapter.t.sol`: Share locking/unlocking
- `USDXVaultComposerSync.t.sol`: Cross-chain composer operations

### 2. Integration Tests

**OVault Integration (`IntegrationOVault.t.sol`):**
- `testFullFlow_DepositAndMintUSDX`: Complete flow from deposit to mint
- `testFullFlow_DepositViaOVault`: Deposit via OVault composer
- `testCrossChainUSDXTransfer`: Cross-chain USDX transfers

**End-to-End (`IntegrationE2E_OVault.t.sol`):**
- `testCompleteE2EFlow`: Full user journey:
  1. Deposit USDC on hub
  2. Lock shares and send cross-chain
  3. Mint USDX on spoke
  4. Use USDX (transfer)
  5. Burn USDX and unlock shares
  6. Redeem shares for USDC

### 3. Test Coverage

Current test status: **87/108 tests passing** (80.6%)

**Remaining Issues:**
- Some tests require additional approval setup
- Cross-chain message simulation needs refinement
- Yield distribution tests need mock updates

## Demo Scenarios

### Scenario 1: Basic Deposit and Mint

**Setup:**
1. Deploy contracts on hub (Ethereum) and spoke (Polygon)
2. Configure LayerZero endpoints and trusted remotes
3. User has USDC on hub chain

**Steps:**
1. User deposits 1000 USDC into `USDXVault` on hub
2. Vault deposits into `USDXYearnVaultWrapper`
3. User receives USDX 1:1 (1000 USDX)
4. User receives vault wrapper shares (representing yield-bearing position)

**Expected Result:**
- User has 1000 USDX on hub chain
- User has vault shares representing 1000 USDC + yield
- Vault has 1000 USDC deposited in Yearn vault

### Scenario 2: Cross-Chain Deposit via OVault

**Steps:**
1. User calls `vault.depositViaOVault(1000 USDC, Polygon EID, receiver)`
2. Vault transfers USDC to `USDXVaultComposerSync`
3. Composer deposits into vault wrapper
4. Composer locks shares in `USDXShareOFTAdapter`
5. Shares sent cross-chain via LayerZero
6. `USDXShareOFT` minted on Polygon for receiver

**Expected Result:**
- Receiver has `USDXShareOFT` tokens on Polygon
- Shares represent yield-bearing position
- Can mint USDX using shares

### Scenario 3: Mint USDX on Spoke Chain

**Steps:**
1. User has `USDXShareOFT` tokens on Polygon (from Scenario 2)
2. User calls `spokeMinter.mintUSDXFromOVault(shares)`
3. Minter burns shares and mints USDX 1:1

**Expected Result:**
- User has USDX on Polygon
- Shares are burned
- User can use USDX on Polygon

### Scenario 4: Cross-Chain USDX Transfer

**Steps:**
1. User has USDX on hub chain
2. User calls `usdxHub.sendCrossChain(Polygon EID, receiver, amount)`
3. USDX burned on hub
4. LayerZero message sent
5. USDX minted on Polygon for receiver

**Expected Result:**
- USDX transferred from hub to spoke
- Total supply maintained across chains
- Receiver has USDX on Polygon

### Scenario 5: Complete Redemption Flow

**Steps:**
1. User has USDX on spoke chain
2. User burns USDX via `spokeMinter.burn(amount)`
3. Shares unlocked (if needed)
4. User sends shares back to hub via LayerZero
5. Shares unlocked on hub
6. User redeems shares from vault wrapper
7. User receives USDC + yield

**Expected Result:**
- User receives USDC back
- Yield is included in redemption
- All positions cleared

## Deployment Guide

### Prerequisites

1. **Environment Variables:**
   ```bash
   export PRIVATE_KEY=<your-private-key>
   export SEPOLIA_RPC_URL=<sepolia-rpc-url>
   export MUMBAI_RPC_URL=<mumbai-rpc-url>
   ```

2. **LayerZero Endpoint Addresses:**
   - Ethereum Sepolia: `0x...` (update in scripts)
   - Polygon Mumbai: `0x...` (update in scripts)

### Hub Chain Deployment

```bash
# Deploy hub contracts
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# Or deploy hub only (for testing)
forge script script/DeployHubOnly.s.sol:DeployHubOnly \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

**Deployment Order:**
1. USDXToken
2. USDXYearnVaultWrapper
3. USDXShareOFTAdapter
4. USDXVaultComposerSync
5. USDXVault (with OVault components)

### Spoke Chain Deployment

```bash
# Deploy spoke contracts
forge script script/DeploySpoke.s.sol:DeploySpoke \
  --rpc-url $MUMBAI_RPC_URL \
  --broadcast \
  --verify
```

**Deployment Order:**
1. USDXToken
2. USDXShareOFT
3. USDXSpokeMinter

### Post-Deployment Configuration

1. **Set LayerZero Endpoints:**
   ```solidity
   usdxHub.setLayerZeroEndpoint(lzEndpoint, eid);
   usdxSpoke.setLayerZeroEndpoint(lzEndpoint, eid);
   ```

2. **Set Trusted Remotes:**
   ```solidity
   usdxHub.setTrustedRemote(spokeEid, spokeAddress);
   usdxSpoke.setTrustedRemote(hubEid, hubAddress);
   ```

3. **Configure OVault Components:**
   ```solidity
   vault.setOVaultComposer(composerAddress);
   vault.setShareOFTAdapter(adapterAddress);
   vault.setVaultWrapper(wrapperAddress);
   ```

## Frontend Integration

### Key Functions

**Deposit:**
```typescript
// Direct deposit
await vault.deposit(amount);

// Cross-chain deposit via OVault
await vault.depositViaOVault(amount, dstEid, receiver, options, { value: lzFee });
```

**Mint USDX on Spoke:**
```typescript
await spokeMinter.mintUSDXFromOVault(shares);
```

**Cross-Chain Transfer:**
```typescript
await usdx.sendCrossChain(dstEid, receiver, amount, options, { value: lzFee });
```

**Redeem:**
```typescript
await vault.redeem(shares, receiver, owner);
```

### Event Listening

**Deposit Events:**
- `DepositedViaOVault(address indexed user, uint256 amount, uint256 shares)`
- `DepositInitiated(bytes32 indexed operationId, address indexed user, uint256 assets, uint32 dstEid, bytes32 receiver)`

**Cross-Chain Events:**
- `CrossChainSent(uint32 indexed dstEid, bytes32 indexed receiver, uint256 amount)`
- `CrossChainReceived(uint32 indexed srcEid, address indexed user, uint256 amount)`

## Security Considerations

1. **LayerZero Security:**
   - Always verify trusted remotes
   - Use proper EID validation
   - Implement replay protection

2. **Access Control:**
   - Admin functions protected by `Ownable`
   - Role-based access for minting/burning
   - Pausable for emergency stops

3. **Reentrancy Protection:**
   - All external calls use `nonReentrant`
   - Checks-effects-interactions pattern

4. **Input Validation:**
   - Zero address checks
   - Zero amount checks
   - Remote validation

## Troubleshooting

### Common Issues

1. **"Insufficient Allowance"**
   - Ensure user has approved contract to spend tokens
   - Check approval amounts match transfer amounts

2. **"Invalid Remote"**
   - Verify trusted remotes are set correctly
   - Check EID matches chain configuration

3. **"OutOfFunds"**
   - Ensure user has ETH for LayerZero fees
   - Check `msg.value` matches required fee

4. **Cross-Chain Messages Not Delivered**
   - Verify LayerZero endpoint configuration
   - Check trusted remotes match
   - Ensure `lzReceive` is called (in tests, manually simulate)

## Next Steps

1. **Complete Test Coverage:**
   - Fix remaining test failures
   - Add edge case tests
   - Add fuzz testing

2. **Gas Optimization:**
   - Review gas usage
   - Optimize storage operations
   - Batch operations where possible

3. **Security Audit:**
   - External security review
   - LayerZero integration audit
   - Access control review

4. **Documentation:**
   - API documentation
   - Integration examples
   - Architecture diagrams

## Resources

- [LayerZero Documentation](https://docs.layerzero.network/)
- [OVault Standard](https://docs.layerzero.network/v2/developers/evm/ovault)
- [Foundry Testing](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
