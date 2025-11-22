# USDX Cross-Chain Stablecoin Protocol

## Overview

USDX is a cross-chain stablecoin protocol that enables users to mint USDX tokens by depositing USDC collateral into vaults on any supported chain. The protocol leverages Circle's Bridge Kit (built on CCTP) for secure USDC cross-chain transfers, and LayerZero/Hyperlane for cross-chain messaging to maintain USDX balance consistency across chains.

## Documentation Structure

1. **[01-overview.md](./01-overview.md)** - High-level overview and core concepts
2. **[02-architecture.md](./02-architecture.md)** - System architecture and component design
3. **[03-flow-diagrams.md](./03-flow-diagrams.md)** - Visual flow diagrams for key processes
4. **[04-concept-exploration.md](./04-concept-exploration.md)** - Design decisions and concept exploration
5. **[05-technical-specification.md](./05-technical-specification.md)** - Detailed technical specifications
6. **[06-implementation-plan.md](./06-implementation-plan.md)** - Implementation roadmap and phases
7. **[07-circle-cctp-research.md](./07-circle-cctp-research.md)** - Circle CCTP integration research (reference)
8. **[08-layerzero-research.md](./08-layerzero-research.md)** - LayerZero integration research
9. **[09-hyperlane-research.md](./09-hyperlane-research.md)** - Hyperlane integration research
10. **[10-open-questions.md](./10-open-questions.md)** - Open questions and clarifications needed
11. **[11-circle-bridge-kit-research.md](./11-circle-bridge-kit-research.md)** - Circle Bridge Kit integration research (recommended)
12. **[12-bridge-kit-integration-summary.md](./12-bridge-kit-integration-summary.md)** - Bridge Kit integration summary and decision rationale
13. **[13-layerzero-ovault-research.md](./13-layerzero-ovault-research.md)** - LayerZero OVault research
14. **[14-hyperlane-yield-routes-research.md](./14-hyperlane-yield-routes-research.md)** - Hyperlane Yield Routes research
15. **[15-architecture-simplification-summary.md](./15-architecture-simplification-summary.md)** - Architecture simplification summary with OVault/Yield Routes
16. **[16-hub-spoke-architecture.md](./16-hub-spoke-architecture.md)** - Hub-and-spoke architecture details
17. **[17-bridge-kit-documentation-research.md](./17-bridge-kit-documentation-research.md)** - Bridge Kit documentation research and review guide
18. **[18-bridge-kit-verified-findings.md](./18-bridge-kit-verified-findings.md)** - Bridge Kit verified findings (no API key, no UI components)
19. **[19-hyperlane-deep-research.md](./19-hyperlane-deep-research.md)** - Deep Hyperlane research from Hackathon Success Guide and documentation (answers outstanding questions)

## Key Features

- **Cross-Chain Stablecoin**: Mint USDX on any chain, use it on any other supported chain
- **USDC Collateral**: 1:1 backing with USDC
- **Yield Generation**: USDC collateral earns yield while locked
- **Fast Transfers**: Leverage LayerZero and Hyperlane for near-instant cross-chain transfers
- **Secure**: Built on battle-tested protocols (Bridge Kit/CCTP, LayerZero, Hyperlane)

## Architecture Highlights

### Core Components
- **Hub Chain (Ethereum)**:
  - **USDXVault**: Manages USDC deposits via OVault/Yield Routes (hub only)
  - **OVault/Yield Routes**: Cross-chain yield vaults wrapping Yearn USDC vault
  - **Yearn USDC Vault**: Single source of yield for all USDC collateral
- **Spoke Chains**:
  - **USDXSpokeMinter**: Allows minting USDX using hub positions
  - **USDXToken**: ERC20 token deployed on all chains
  - **CrossChainBridge**: Handles USDX transfers between spokes
- **Infrastructure**:
  - **Bridge Kit Service**: Backend service using Bridge Kit SDK for USDC transfers (Spoke ↔ Hub)

### Cross-Chain Infrastructure
- **LayerZero**: Primary cross-chain messaging protocol for USDX transfers + OVault for yield
- **Hyperlane**: Secondary cross-chain messaging protocol for USDX transfers + Yield Routes for yield (redundancy)
- **Circle Bridge Kit**: SDK and UI components for USDC cross-chain transfers (built on CCTP)
- **Yearn Finance**: Yearn USDC vault as single source of yield (accessed via OVault/Yield Routes)

## Hub-and-Spoke Architecture

USDX uses a **hub-and-spoke model**:
- **Hub Chain**: Ethereum (single source of USDC collateral and yield)
- **Spoke Chains**: Polygon, Arbitrum, Optimism, etc. (where users mint and use USDX)

## User Flow

1. **Deposit**: User bridges USDC from Spoke Chain → Hub Chain (Ethereum) via Bridge Kit
2. **Vault Deposit**: User deposits USDC into USDXVault on Hub Chain
3. **Yield Setup**: USDXVault → OVault/Yield Routes → Yearn USDC Vault
4. **Position**: User receives OVault/Yield Routes position on Hub Chain
5. **Mint USDX**: User mints USDX on any Spoke Chain using hub position
6. **Yield**: Yield accrues automatically in Yearn vault on Hub Chain
7. **Transfer**: User can transfer USDX between Spoke Chains via LayerZero/Hyperlane
8. **Withdraw**: User withdraws USDC from Hub → bridges back to Spoke Chain

## Supported Chains (Planned)

- Ethereum
- Polygon
- Avalanche
- Arbitrum
- Optimism
- Base
- (More chains can be added)

## Status

**Current Phase**: Design and Planning
- ✅ Architecture design complete
- ✅ Flow diagrams created
- ✅ Technical specifications drafted
- ⏳ Implementation planning in progress
- ⏳ Code development not started

## Next Steps

1. Finalize technical specifications
2. Begin smart contract development
3. Set up development environment
4. Create test infrastructure
5. Security audit planning

## Resources

- [Circle Bridge Kit Documentation](https://developers.circle.com/bridge-kit) (Recommended)
- [Circle CCTP Documentation](https://developers.circle.com/stablecoin/docs/cctp-overview) (Reference)
- [LayerZero Documentation](https://layerzero.gitbook.io/docs/)
- [Hyperlane Documentation](https://docs.hyperlane.xyz/)

## License

TBD
