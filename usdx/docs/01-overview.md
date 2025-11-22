# USDX Cross-Chain Stablecoin - Overview

## Executive Summary

USDX is a cross-chain stablecoin protocol that uses a **hub-and-spoke architecture** where all USDC collateral and yield generation is centralized on a single hub chain (Ethereum), while users can mint and use USDX on multiple spoke chains. The protocol leverages Circle's Bridge Kit (built on CCTP) for secure USDC transfers between spokes and hub, and LayerZero/Hyperlane for cross-chain USDX transfers between spokes.

## Core Concept

- **Hub-and-Spoke Model**: Single hub chain (Ethereum) for all USDC collateral and yield
- **Collateral**: USDC (bridged from spoke chains to hub chain)
- **Stablecoin**: USDX (minted 1:1 against USDC deposits, mintable on any spoke chain)
- **Yield Generation**: All USDC collateral in single Yearn vault on hub chain (via OVault/Yield Routes)
- **Cross-Chain**: Users bridge USDC to hub, mint USDX on spokes, transfer USDX between spokes

## Key Components

### Hub Chain (Ethereum)
1. **USDXVault**: Main vault contract that stores USDC collateral (hub only)
2. **OVault/Yield Routes**: Cross-chain yield vaults wrapping Yearn USDC vault
3. **Yearn USDC Vault**: Single source of yield for all USDC collateral

### Spoke Chains (Polygon, Arbitrum, Optimism, etc.)
4. **USDXSpokeMinter**: Allows users to mint USDX using hub chain positions
5. **USDXToken**: ERC20 token deployed on all chains
6. **CrossChainBridge**: Handles USDX transfers between spoke chains

### Infrastructure
7. **Bridge Kit**: SDK for USDC transfers between spokes and hub (Spoke ↔ Hub)
8. **LayerZero/Hyperlane**: Cross-chain messaging for USDX transfers (Spoke ↔ Spoke)
9. **UI/UX**: Frontend for user interactions across chains

## Supported Chains

### Hub Chain
- **Ethereum**: Single source of USDC collateral and yield generation

### Spoke Chains (Initial)
- Polygon
- Arbitrum
- Optimism
- Base
- Avalanche
- (More chains can be added as spokes)

## User Flow (High Level - Hub-and-Spoke)

1. **Deposit**: User bridges USDC from Spoke Chain → Hub Chain (Ethereum) via Bridge Kit
2. **Vault**: User deposits USDC into USDXVault on Hub Chain
3. **Yield**: USDXVault → OVault/Yield Routes → Yearn USDC Vault (yield accrues automatically)
4. **Mint**: User mints USDX on any Spoke Chain using hub position
5. **Transfer**: User transfers USDX between Spoke Chains via LayerZero/Hyperlane
6. **Withdraw**: User withdraws USDC from Hub → bridges back to Spoke Chain

## Key Design Principles

- **Over-collateralization**: 1:1 ratio with USDC (can be adjusted)
- **Yield accrual**: Yield earned on USDC benefits the protocol (revenue model)
- **Non-custodial**: Users maintain control of their collateral
- **Cross-chain composability**: USDX works seamlessly across chains
- **Security**: Leverage battle-tested protocols (Bridge Kit/CCTP, LayerZero, Hyperlane)
