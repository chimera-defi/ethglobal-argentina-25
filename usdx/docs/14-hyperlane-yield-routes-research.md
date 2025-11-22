# Hyperlane Yield Routes Research

## Overview

Hyperlane Yield Routes is Hyperlane's solution for cross-chain yield-bearing positions. Similar to LayerZero's OVault, it allows users to deposit assets into a yield vault on one chain and access the position across all supported chains.

## Key Concepts

### How Yield Routes Work

1. **Source Chain Vault**: Assets deposited into yield vault on source chain
2. **Cross-Chain Representation**: Yield Routes mints representative tokens on destination chains
3. **Yield Accrual**: Yield accrues on source chain vault
4. **Cross-Chain Access**: Users can interact with position on any chain

### Architecture

```
Source Chain (Ethereum)
├── USDC deposited into Yearn Vault
├── Yield Routes tracks deposits
└── Yield accrues here

Destination Chain (Polygon)
├── Yield Routes mints representative tokens
├── Users can mint/burn USDX using these tokens
└── No actual USDC on this chain
```

## Integration with USDX

### Proposed Architecture

1. **USDC Bridge**: User bridges USDC from Chain A to Chain B using Bridge Kit
2. **Yield Routes Deposit**: USDC deposited into Yield Routes vault on Chain B (wraps Yearn USDC vault)
3. **Cross-Chain Mint**: User can mint USDX on any chain using their Yield Routes position
4. **Yield Accrual**: Yield accrues on source chain (Chain B) in Yearn vault

### Benefits for USDX

1. **Simplified Yield Management**: No need to manage yield strategies per chain
2. **Single Source of Yield**: All USDC collateral in one Yearn vault
3. **Cross-Chain Access**: Users can mint USDX on any chain
4. **Automatic Yield**: Yield accrues automatically via Yearn
5. **Reduced Complexity**: No need for YieldStrategy contract per chain
6. **Hyperlane Security**: Leverages Hyperlane's validator network

## How It Would Work

### User Flow

```
1. User bridges USDC from Chain A → Chain B using Bridge Kit
2. USDC arrives on Chain B
3. User deposits USDC into USDX Yield Routes vault on Chain B
   - Yield Routes deposits into Yearn USDC vault
   - Yield Routes tracks user's position
4. User can now mint USDX on any chain:
   - Chain A: Yield Routes mints representative token
   - Chain B: Direct access to Yield Routes position
   - Chain C: Yield Routes mints representative token
5. User mints USDX using Yield Routes position
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
├── Deposited into Yield Routes vault
│   └── Yield Routes deposits into Yearn USDC vault
├── Yield Routes tracks user position
└── Yield accrues here

Chain A (User's Chain)
├── Yield Routes mints representative token via Hyperlane
├── User calls USDXVault.mintUSDX()
│   └── Uses Yield Routes position as collateral
└── USDX minted to user
```

## Yield Routes Integration Points

### 1. USDXVault Contract

```solidity
interface IUSDXVault {
    // Deposit USDC into Yield Routes and mint USDX
    function depositUSDCAndMint(
        uint256 usdcAmount,
        address yieldRoutesPosition
    ) external returns (uint256 usdxAmount);
    
    // Mint USDX using Yield Routes position from another chain
    function mintUSDXFromYieldRoutes(
        uint256 yieldRoutesShares,
        uint32 sourceDomain
    ) external returns (uint256 usdxAmount);
    
    // Withdraw USDC from Yield Routes
    function withdrawUSDCFromYieldRoutes(
        uint256 usdxAmount
    ) external returns (uint256 usdcAmount);
}
```

### 2. Yield Routes Integration

```solidity
import {IYieldRoutes} from "@hyperlane-xyz/yield-routes/contracts/interfaces/IYieldRoutes.sol";

contract USDXVault {
    IYieldRoutes public yieldRoutes;
    IYearnVault public yearnVault; // Yearn USDC vault
    
    function depositUSDC(uint256 amount) external {
        // Transfer USDC from user
        usdc.transferFrom(msg.sender, address(this), amount);
        
        // Deposit into Yield Routes (which wraps Yearn)
        usdc.approve(address(yieldRoutes), amount);
        uint256 shares = yieldRoutes.deposit(amount, msg.sender);
        
        // Mint USDX 1:1 with USDC deposited
        usdxToken.mint(msg.sender, amount);
        
        // Track user's Yield Routes position
        userYieldRoutesShares[msg.sender] += shares;
    }
    
    function mintUSDXFromCrossChain(
        uint256 yieldRoutesShares,
        uint32 sourceDomain
    ) external {
        // Verify Yield Routes position exists on source domain
        require(yieldRoutes.isValidPosition(sourceDomain, yieldRoutesShares), "Invalid position");
        
        // Calculate USDC value of shares
        uint256 usdcValue = yieldRoutes.sharesToAssets(yieldRoutesShares);
        
        // Mint USDX
        usdxToken.mint(msg.sender, usdcValue);
        
        // Track cross-chain position
        crossChainPositions[msg.sender][sourceDomain] = yieldRoutesShares;
    }
}
```

## Key Considerations

### Advantages

1. **Simplified Architecture**: No need for YieldStrategy contract per chain
2. **Single Yield Source**: All yield from one Yearn vault
3. **Cross-Chain Native**: Built for cross-chain use cases
4. **Automatic Yield**: Yield accrues automatically
5. **Hyperlane Security**: Leverages Hyperlane's validator network
6. **Reduced Gas**: No need to bridge yield tokens

### Considerations

1. **Yield Routes Availability**: Need to verify Yield Routes is available/mainnet ready
2. **Yearn Integration**: Yield Routes needs to support Yearn vaults
3. **Position Tracking**: Need to track Yield Routes positions across chains
4. **Withdrawal Flow**: Users need to withdraw from Yield Routes to get USDC back
5. **Hyperlane Dependency**: Relies on Hyperlane's validator network

## Comparison: OVault vs Yield Routes

| Feature | OVault (LayerZero) | Yield Routes (Hyperlane) |
|---------|-------------------|-------------------------|
| Cross-Chain Messaging | LayerZero | Hyperlane |
| Security Model | Oracle + Relayer | Validator Network |
| Yield Source | Any vault (Yearn) | Any vault (Yearn) |
| Position Tracking | OVault handles | Yield Routes handles |
| Gas Costs | LayerZero fees | Hyperlane fees |
| Mainnet Ready | TBD | TBD |

## Dual Strategy: OVault + Yield Routes

We could support both:
- **Primary**: OVault (LayerZero)
- **Secondary**: Yield Routes (Hyperlane)
- **Benefits**: Redundancy, user choice, risk mitigation

## Questions to Resolve ✅

✅ **All questions answered** - See **[19-hyperlane-deep-research.md](./19-hyperlane-deep-research.md)** for comprehensive answers.

1. ✅ **Is Yield Routes mainnet ready?**
   - **Answer**: Yes, launched March 2024 with multiple launch partners. Permissionless deployment available.

2. ✅ **Does Yield Routes support Yearn vaults?**
   - **Answer**: Yes, Yield Routes are ERC-4626 compatible, and Yearn vaults are ERC-4626 compatible, so full support.

3. ✅ **How do we handle withdrawals?**
   - **Answer**: When bridging back, collateral is automatically redeemed from vault. Yield allocation is configurable.

4. ✅ **What are the gas costs?**
   - **Answer**: Similar to standard Warp Routes with minimal overhead for vault interactions. Can be optimized by batching.

5. ✅ **How do we track positions across chains?**
   - **Answer**: Yield Routes handles this automatically via Hyperlane messaging. Representative tokens are minted on destination chains.

6. ✅ **Can we use both OVault and Yield Routes simultaneously?**
   - **Answer**: Yes, can support both for redundancy, user choice, and risk mitigation.

## Resources

- [Hyperlane Yield Routes Blog Post](https://www.hyperlane.xyz/post/introducing-yield-routes)
- [Hyperlane Documentation](https://docs.hyperlane.xyz)
- [Warp Routes Documentation](https://docs.hyperlane.xyz/docs/protocol/warp-routes)
- [ISM Guide](https://docs.hyperlane.xyz/docs/protocol/ISM/modular-security)
- [Hyperlane Monorepo](https://github.com/hyperlane-xyz/hyperlane-monorepo)
- [Deep Research Document](./19-hyperlane-deep-research.md)
