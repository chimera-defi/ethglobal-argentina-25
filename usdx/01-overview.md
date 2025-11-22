# USDX Cross-Chain Stablecoin - Overview

## Executive Summary

USDX is a cross-chain stablecoin protocol that enables users to mint USDX tokens by depositing USDC collateral into vaults on any supported chain. The protocol leverages Circle's Bridge Kit (built on CCTP) for secure USDC cross-chain transfers, and LayerZero/Hyperlane for cross-chain messaging to maintain USDX balance consistency across chains.

## Core Concept

- **Collateral**: USDC (native to each chain)
- **Stablecoin**: USDX (minted 1:1 against USDC deposits)
- **Yield Generation**: USDC collateral at rest earns yield (similar to Katana Vault Bridge)
- **Cross-Chain**: Users can mint USDX on any chain and transfer it to any other supported chain

## Key Components

1. **Vault Contracts**: Store USDC collateral and mint USDX
2. **Cross-Chain Messaging**: LayerZero/Hyperlane for USDX balance synchronization
3. **Bridge Kit Integration**: Circle's Bridge Kit SDK for USDC cross-chain transfers (simplified CCTP integration)
4. **Yield Strategy**: DeFi protocols for earning yield on idle USDC
5. **UI/UX**: Frontend for user interactions across chains (includes Bridge Kit UI components)

## Supported Chains (Initial)

- Ethereum
- Polygon
- Avalanche
- Arbitrum
- Optimism
- Base
- (More chains can be added)

## User Flow (High Level)

1. User deposits USDC into vault on Chain A
2. Vault mints USDX on Chain A
3. User requests cross-chain transfer to Chain B
4. USDX is burned on Chain A
5. Message sent via LayerZero/Hyperlane to Chain B
6. USDX is minted on Chain B
7. USDC collateral remains on Chain A (earning yield)

## Key Design Principles

- **Over-collateralization**: 1:1 ratio with USDC (can be adjusted)
- **Yield accrual**: Yield earned on USDC benefits the protocol (revenue model)
- **Non-custodial**: Users maintain control of their collateral
- **Cross-chain composability**: USDX works seamlessly across chains
- **Security**: Leverage battle-tested protocols (Bridge Kit/CCTP, LayerZero, Hyperlane)
