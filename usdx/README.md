# USDX Cross-Chain Stablecoin Protocol

## Overview

USDX is a cross-chain stablecoin protocol that enables users to mint USDX tokens by depositing USDC collateral into vaults on any supported chain. The protocol leverages Circle's Cross-Chain Transfer Protocol (CCTP) for secure USDC transfers, and LayerZero/Hyperlane for cross-chain messaging to maintain USDX balance consistency across chains.

## Documentation Structure

1. **[01-overview.md](./01-overview.md)** - High-level overview and core concepts
2. **[02-architecture.md](./02-architecture.md)** - System architecture and component design
3. **[03-flow-diagrams.md](./03-flow-diagrams.md)** - Visual flow diagrams for key processes
4. **[04-concept-exploration.md](./04-concept-exploration.md)** - Design decisions and concept exploration
5. **[05-technical-specification.md](./05-technical-specification.md)** - Detailed technical specifications
6. **[06-implementation-plan.md](./06-implementation-plan.md)** - Implementation roadmap and phases
7. **[07-circle-cctp-research.md](./07-circle-cctp-research.md)** - Circle CCTP integration research
8. **[08-layerzero-research.md](./08-layerzero-research.md)** - LayerZero integration research
9. **[09-hyperlane-research.md](./09-hyperlane-research.md)** - Hyperlane integration research
10. **[10-open-questions.md](./10-open-questions.md)** - Open questions and clarifications needed

## Key Features

- **Cross-Chain Stablecoin**: Mint USDX on any chain, use it on any other supported chain
- **USDC Collateral**: 1:1 backing with USDC
- **Yield Generation**: USDC collateral earns yield while locked
- **Fast Transfers**: Leverage LayerZero and Hyperlane for near-instant cross-chain transfers
- **Secure**: Built on battle-tested protocols (CCTP, LayerZero, Hyperlane)

## Architecture Highlights

### Core Components
- **USDXVault**: Manages USDC deposits and USDX minting
- **USDXToken**: ERC20 token with cross-chain capabilities
- **CrossChainBridge**: Handles cross-chain USDX transfers
- **CCTPAdapter**: Integrates with Circle CCTP for USDC transfers
- **YieldStrategy**: Manages yield generation on idle USDC

### Cross-Chain Infrastructure
- **LayerZero**: Primary cross-chain messaging protocol
- **Hyperlane**: Secondary cross-chain messaging protocol (redundancy)
- **Circle CCTP**: USDC cross-chain transfers

## User Flow

1. User deposits USDC into vault on Chain A
2. Vault mints USDX on Chain A (1:1 ratio)
3. User requests cross-chain transfer to Chain B
4. USDX is burned on Chain A
5. Message sent via LayerZero/Hyperlane to Chain B
6. USDX is minted on Chain B
7. USDC collateral remains on Chain A (earning yield)

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

- [Circle CCTP Documentation](https://developers.circle.com/stablecoin/docs/cctp-overview)
- [LayerZero Documentation](https://layerzero.gitbook.io/docs/)
- [Hyperlane Documentation](https://docs.hyperlane.xyz/)

## License

TBD
