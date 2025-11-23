# LayerZero OVault Composer - Implementation Summary

## Overview
This document summarizes the implementation and fixes for the USDX Protocol's LayerZero OVault Composer, enabling one-click cross-chain deposits across multiple chains.

## What Was Fixed

### 1. **USDXShareOFTAdapter - Added `sendTo()` Method**

**Problem**: The Composer needed to send shares to a user-specified address on the destination chain, but the existing `send()` method always sent to `msg.sender`.

**Solution**: Added a new `sendTo()` method that allows specifying a custom receiver:

```solidity
function sendTo(
    address from,
    uint32 dstEid,
    bytes32 to,
    uint256 shares,
    bytes calldata options
) external payable {
    // Only require allowance if sender is not the owner
    if (from != msg.sender) {
        _spendAllowance(from, msg.sender, shares);
    }
    _burn(from, shares);
    
    // Build payload with custom receiver
    address receiver = address(uint160(uint256(to)));
    bytes memory payload = abi.encode(receiver, shares);
    
    // Send via LayerZero...
}
```

**Key Feature**: Skips allowance check when `from == msg.sender`, allowing contracts to send their own tokens without self-approval.

### 2. **USDXVaultComposerSync - Fixed `deposit()` Method**

**Problem**: The Composer was trying to manually construct LayerZero messages with a custom payload format that the spoke-side ShareOFT contracts couldn't understand.

**Solution**: Updated the Composer to use the adapter's `sendTo()` method, which properly formats the payload:

```solidity
function deposit(DepositParams calldata _params, bytes calldata options) external payable {
    // 1. Pull USDC from vault (caller)
    assetOFT.transferFrom(msg.sender, address(this), _params.assets);
    
    // 2. Deposit into vaultWrapper to get yield-bearing shares
    uint256 shares = vault.deposit(_params.assets, address(this));
    
    // 3. Lock shares in OFT adapter (get OFT tokens)
    IERC20(address(vault)).approve(address(shareOFT), shares);
    shareOFT.lockSharesFrom(address(this), shares);
    
    // 4. Send OFT tokens cross-chain with custom receiver
    shareOFT.sendTo{value: msg.value}(
        address(this),      // from: composer has the OFT tokens
        _params.dstEid,     // destination chain
        _params.receiver,   // receiver on destination (user)
        shares,             // amount to send
        options             // LayerZero options
    );
}
```

**Flow**:
1. User calls `vault.depositViaOVault()`
2. Vault transfers USDC to itself and approves Composer
3. Vault calls `composer.deposit()`
4. Composer deposits USDC into vaultWrapper → gets shares
5. Composer locks shares in adapter → gets OFT tokens
6. Composer uses `sendTo()` to send OFT tokens to user on destination chain
7. LayerZero relays message
8. User receives yield-bearing shares on destination chain!

## Architecture

### Hub Chain (Ethereum)
- **USDXVault**: Entry point for deposits
- **USDXVaultComposerSync**: Orchestrates one-click deposits
- **USDXYearnVaultWrapper** (ERC-4626): Wraps Yearn vault tokens
- **USDXShareOFTAdapter**: OFT adapter for hub-side share management

### Spoke Chains (Polygon, Base, Arbitrum, etc.)
- **USDXShareOFT**: OFT contract that receives cross-chain shares
- **USDXSpokeMinter**: Mints USDX stablecoin using shares as collateral
- **USDXToken**: The USDX stablecoin itself

## Multi-Chain Test

The new `IntegrationE2E_MultiChain.t.sol` test demonstrates:

1. **1 Hub + 3 Spokes**: Ethereum → Polygon, Base, Arbitrum
2. **3 Users**: Alice, Bob, Charlie
3. **One-Click Deposits**: Each user deposits on Ethereum and receives shares on their chosen L2
4. **USDX Minting**: Users mint USDX on their respective L2s using cross-chain shares

### Test Output
```
PHASE 1: ALICE DEPOSITS VIA OVAULT TO POLYGON
  ✓ Deposit 10,000 USDC on Ethereum
  ✓ Receive 10,000 yield-bearing shares on Polygon

PHASE 2: BOB DEPOSITS VIA OVAULT TO BASE
  ✓ Deposit 10,000 USDC on Ethereum
  ✓ Receive 10,000 yield-bearing shares on Base

PHASE 3: CHARLIE DEPOSITS VIA OVAULT TO ARBITRUM
  ✓ Deposit 10,000 USDC on Ethereum
  ✓ Receive 10,000 yield-bearing shares on Arbitrum

PHASE 4: USERS MINT USDX ON THEIR RESPECTIVE CHAINS
  ✓ Alice mints 10,000 USDX on Polygon
  ✓ Bob mints 10,000 USDX on Base
  ✓ Charlie mints 10,000 USDX on Arbitrum

Total Collateral on Hub: 30,000 USDC
```

## Key LayerZero Features Demonstrated

### 1. **OVault Composer Pattern**
- One transaction from user initiates entire cross-chain flow
- Automatic vault deposit, share locking, and cross-chain relay
- User receives shares on destination without any manual bridging

### 2. **OFT (Omnichain Fungible Token)**
- Shares can exist on any chain
- Value preserved across chains
- Full interoperability

### 3. **Multi-Chain Support**
- Hub chain manages collateral
- Multiple spoke chains for USDX usage
- Seamless cross-chain communication

### 4. **Custom Receiver Pattern**
- `sendTo()` allows specifying receiver address
- Enables composer/contract-initiated transfers
- Maintains security through allowance checks

## Running the Test

```bash
# Single multi-chain test
forge test --match-test testMultiChainOVaultComposerFlow -vv

# All OVault tests
forge test --match-contract "Integration.*OVault" -vv
```

## Benefits

1. **User Experience**: One-click deposits from Ethereum to any L2
2. **Capital Efficiency**: Collateral stays on Ethereum, shares travel cross-chain
3. **Yield Generation**: Shares earn yield from Yearn vaults
4. **Multi-Chain**: USDX usable on any supported L2
5. **True OVault**: Proper implementation of LayerZero OVault pattern

## Technical Notes

- Shares use 6 decimals (matching USDC)
- Initial deposit ratio is 1:1 (USDC:shares)
- LayerZero endpoints handle cross-chain messaging
- Mock contracts used for testing (can be replaced with live deployments)

## Next Steps

1. ✅ Fix Composer implementation
2. ✅ Add `sendTo()` to adapter
3. ✅ Create multi-chain test
4. 🔄 Update documentation
5. 🔄 Update demo scripts
6. ⏳ Deploy to testnets
7. ⏳ Integration with live Yearn vaults

