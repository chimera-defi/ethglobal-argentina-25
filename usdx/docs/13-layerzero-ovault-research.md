# LayerZero OVault Research

## Overview

OVault is LayerZero's solution for making any vault accessible everywhere. It allows users to deposit assets into a vault on one chain and access the yield-bearing position across all supported chains without needing to bridge the underlying assets.

## Key Concepts

### How OVault Works

1. **Single Source of Truth**: Assets are deposited into a vault on one chain (source chain)
2. **Cross-Chain Representation**: OVault mints representative tokens on other chains
3. **Yield Accrual**: Yield accrues on the source chain vault
4. **Cross-Chain Access**: Users can interact with their position on any chain

### Architecture

```
Source Chain (Ethereum)
├── USDC deposited into Yearn Vault
├── OVault tracks deposits
└── Yield accrues here

Destination Chain (Polygon)
├── OVault mints representative tokens
├── Users can mint/burn USDX using these tokens
└── No actual USDC on this chain
```

## Integration with USDX

### Proposed Architecture

1. **USDC Bridge**: User bridges USDC from Chain A to Chain B using Bridge Kit
2. **OVault Deposit**: USDC deposited into OVault on Chain B (which wraps Yearn USDC vault)
3. **Cross-Chain Mint**: User can mint USDX on any chain using their OVault position
4. **Yield Accrual**: Yield accrues on source chain (Chain B) in Yearn vault

### Benefits for USDX

1. **Simplified Yield Management**: No need to manage yield strategies per chain
2. **Single Source of Yield**: All USDC collateral in one Yearn vault
3. **Cross-Chain Access**: Users can mint USDX on any chain
4. **Automatic Yield**: Yield accrues automatically via Yearn
5. **Reduced Complexity**: No need for YieldStrategy contract per chain

## How It Would Work

### User Flow

```
1. User bridges USDC from Chain A → Chain B using Bridge Kit
2. USDC arrives on Chain B
3. User deposits USDC into USDX OVault on Chain B
   - OVault deposits into Yearn USDC vault
   - OVault tracks user's position
4. User can now mint USDX on any chain:
   - Chain A: OVault mints representative token
   - Chain B: Direct access to OVault position
   - Chain C: OVault mints representative token
5. User mints USDX using OVault position
6. Yield accrues on Chain B in Yearn vault
```

### Technical Flow

```
Chain A (User's Chain)
├── User has USDC
├── Bridge Kit transfers USDC to Chain B
└── User wants to mint USDX

Chain B (Source Chain - Ethereum)
├── USDC arrives via Bridge Kit
├── Deposited into OVault
│   └── OVault deposits into Yearn USDC vault
├── OVault tracks user position
└── Yield accrues here

Chain A (User's Chain)
├── OVault mints representative token
├── User calls USDXVault.mintUSDX()
│   └── Uses OVault position as collateral
└── USDX minted to user
```

## OVault Integration Points

### 1. USDXVault Contract

```solidity
interface IUSDXVault {
    // Deposit USDC into OVault and mint USDX
    function depositUSDCAndMint(
        uint256 usdcAmount,
        address ovaultPosition
    ) external returns (uint256 usdxAmount);
    
    // Mint USDX using OVault position from another chain
    function mintUSDXFromOVault(
        uint256 ovaultShares,
        uint16 sourceChainId
    ) external returns (uint256 usdxAmount);
    
    // Withdraw USDC from OVault
    function withdrawUSDCFromOVault(
        uint256 usdxAmount
    ) external returns (uint256 usdcAmount);
}
```

### 2. OVault Integration

```solidity
import {IOVault} from "@layerzero/oapp-vault/contracts/interfaces/IOVault.sol";

contract USDXVault {
    IOVault public ovault;
    IYearnVault public yearnVault; // Yearn USDC vault
    
    function depositUSDC(uint256 amount) external {
        // Transfer USDC from user
        usdc.transferFrom(msg.sender, address(this), amount);
        
        // Deposit into OVault (which wraps Yearn)
        usdc.approve(address(ovault), amount);
        uint256 shares = ovault.deposit(amount, msg.sender);
        
        // Mint USDX 1:1 with USDC deposited
        usdxToken.mint(msg.sender, amount);
        
        // Track user's OVault position
        userOVaultShares[msg.sender] += shares;
    }
    
    function mintUSDXFromCrossChain(
        uint256 ovaultShares,
        uint16 sourceChainId
    ) external {
        // Verify OVault position exists on source chain
        require(ovault.isValidPosition(sourceChainId, ovaultShares), "Invalid position");
        
        // Calculate USDC value of shares
        uint256 usdcValue = ovault.sharesToAssets(ovaultShares);
        
        // Mint USDX
        usdxToken.mint(msg.sender, usdcValue);
        
        // Track cross-chain position
        crossChainPositions[msg.sender][sourceChainId] = ovaultShares;
    }
}
```

## Key Considerations

### Advantages

1. **Simplified Architecture**: No need for YieldStrategy contract per chain
2. **Single Yield Source**: All yield from one Yearn vault
3. **Cross-Chain Native**: Built for cross-chain use cases
4. **Automatic Yield**: Yield accrues automatically
5. **Reduced Gas**: No need to bridge yield tokens

### Considerations

1. **OVault Availability**: Need to verify OVault is available/mainnet ready
2. **Yearn Integration**: OVault needs to support Yearn vaults
3. **Position Tracking**: Need to track OVault positions across chains
4. **Withdrawal Flow**: Users need to withdraw from OVault to get USDC back

## Questions to Resolve

1. Is OVault mainnet ready?
2. Does OVault support Yearn vaults?
3. How do we handle withdrawals?
4. What are the gas costs?
5. How do we track positions across chains?

## Resources

- [LayerZero OVault Blog Post](https://layerzero.network/blog/introducing-ovault-any-vault-accessible-everywhere)
- LayerZero OVault Documentation (to be found)
- OVault GitHub Repository (to be found)
