# USDX Cross-Chain Stablecoin Protocol

## Overview

USDX is a cross-chain stablecoin protocol that enables users to mint USDX tokens by depositing USDC collateral into vaults on any supported chain. The protocol uses a **hub-and-spoke architecture** where all USDC collateral and yield generation is centralized on Ethereum (hub), while users can mint and use USDX on multiple spoke chains.

## Key Features

- **Cross-Chain Stablecoin**: Mint USDX on any chain, use it on any other supported chain
- **USDC Collateral**: 1:1 backing with USDC
- **Yield Generation**: USDC collateral earns yield while locked (via Yearn USDC vault)
- **Fast Transfers**: Leverage LayerZero and Hyperlane for near-instant cross-chain transfers
- **Secure**: Built on battle-tested protocols (Bridge Kit/CCTP, LayerZero, Hyperlane)

## Architecture Highlights

### Hub-and-Spoke Model

- **Hub Chain (Ethereum)**: Single source of USDC collateral and yield generation
- **Spoke Chains**: Polygon, Arbitrum, Optimism, Base, etc. (where users mint and use USDX)

### Core Components

**Hub Chain**:
- `USDXVault.sol` - Manages USDC deposits via OVault/Yield Routes
- `OVault/Yield Routes` - Cross-chain yield vaults wrapping Yearn USDC vault
- `Yearn USDC Vault` - Single source of yield for all USDC collateral

**Spoke Chains**:
- `USDXSpokeMinter.sol` - Allows minting USDX using hub positions
- `USDXToken.sol` - ERC20 token deployed on all chains
- `CrossChainBridge.sol` - Handles USDX transfers between spokes

**Infrastructure**:
- **Bridge Kit SDK** - For USDC transfers between spokes and hub (no API key, SDK-only)
- **LayerZero** - Primary cross-chain messaging for USDX transfers + OVault
- **Hyperlane** - Secondary cross-chain messaging for USDX transfers + Yield Routes

## Documentation Structure

### 🚀 Start Here

1. **[HANDOFF-GUIDE.md](./HANDOFF-GUIDE.md)** - **Essential reading for all developers** - Quick start guide and handoff information
2. **[01-overview.md](./01-overview.md)** - High-level overview and core concepts
3. **[02-architecture.md](./02-architecture.md)** - Complete system architecture and component design

### Core Documentation

4. **[03-flow-diagrams.md](./03-flow-diagrams.md)** - Visual flow diagrams for key processes
5. **[04-concept-exploration.md](./04-concept-exploration.md)** - Design decisions and concept exploration
6. **[05-technical-specification.md](./05-technical-specification.md)** - Detailed technical specifications and contract interfaces
7. **[06-implementation-plan.md](./06-implementation-plan.md)** - Implementation roadmap and phases

### Research & Integration Guides

8. **[RESEARCH-bridge-kit.md](./RESEARCH-bridge-kit.md)** - **Complete Bridge Kit guide** - Consolidated research, verified findings, integration patterns
9. **[RESEARCH-hyperlane.md](./RESEARCH-hyperlane.md)** - **Complete Hyperlane guide** - Consolidated research, ISM selection, Yield Routes integration
10. **[08-layerzero-research.md](./08-layerzero-research.md)** - LayerZero integration research
11. **[13-layerzero-ovault-research.md](./13-layerzero-ovault-research.md)** - LayerZero OVault specific research

### Reference & Questions

12. **[10-open-questions.md](./10-open-questions.md)** - Open questions and clarifications needed (many answered)
13. **[07-circle-cctp-research.md](./07-circle-cctp-research.md)** - Circle CCTP research (reference - Bridge Kit recommended)

### Legacy/Archive Documents

*Note: The following documents have been consolidated into RESEARCH-*.md files but are kept for reference:*
- `11-circle-bridge-kit-research.md` → Consolidated into `RESEARCH-bridge-kit.md`
- `12-bridge-kit-integration-summary.md` → Consolidated into `RESEARCH-bridge-kit.md`
- `17-bridge-kit-documentation-research.md` → Consolidated into `RESEARCH-bridge-kit.md`
- `18-bridge-kit-verified-findings.md` → Consolidated into `RESEARCH-bridge-kit.md`
- `09-hyperlane-research.md` → Consolidated into `RESEARCH-hyperlane.md`
- `14-hyperlane-yield-routes-research.md` → Consolidated into `RESEARCH-hyperlane.md`
- `19-hyperlane-deep-research.md` → Consolidated into `RESEARCH-hyperlane.md`
- `15-architecture-simplification-summary.md` → Information merged into `02-architecture.md`
- `16-hub-spoke-architecture.md` → Information merged into `02-architecture.md`

## User Flow (High Level)

1. **Deposit**: User bridges USDC from Spoke Chain → Hub Chain (Ethereum) via Bridge Kit
2. **Vault**: User deposits USDC into USDXVault on Hub Chain
3. **Yield**: USDXVault → OVault/Yield Routes → Yearn USDC Vault (yield accrues automatically)
4. **Mint**: User mints USDX on any Spoke Chain using hub position
5. **Transfer**: User transfers USDX between Spoke Chains via LayerZero/Hyperlane
6. **Withdraw**: User withdraws USDC from Hub → bridges back to Spoke Chain

## Supported Chains (Planned)

### Hub Chain
- **Ethereum** - Single source of USDC collateral and yield

### Spoke Chains (Initial)
- Polygon
- Arbitrum
- Optimism
- Base
- Avalanche
- (More chains can be added as spokes)

## Status

**Current Phase**: Design and Planning ✅ Complete
- ✅ Architecture design complete
- ✅ Flow diagrams created
- ✅ Technical specifications drafted
- ✅ Research consolidated
- ✅ Implementation planning complete
- ⏳ Ready for code development

## Next Steps

1. Review **[HANDOFF-GUIDE.md](./HANDOFF-GUIDE.md)** for implementation priorities
2. Set up development environment
3. Begin smart contract development (Phase 2 in implementation plan)
4. Create test infrastructure
5. Security audit planning

## Key Design Decisions

1. **Bridge Kit for USDC**: Use Circle Bridge Kit SDK (not direct CCTP)
   - ✅ No API key required
   - ✅ SDK-only (custom UI required)
   - ✅ Works directly with smart contracts

2. **OVault + Yield Routes**: Dual yield strategy
   - Primary: LayerZero OVault
   - Secondary: Hyperlane Yield Routes
   - Both wrap Yearn USDC vault

3. **LayerZero + Hyperlane**: Dual cross-chain messaging
   - Primary: LayerZero
   - Secondary: Hyperlane
   - Provides redundancy

4. **Yearn USDC Vault**: Single source of yield
   - All collateral in one vault
   - ERC-4626 compatible
   - Well-audited and battle-tested

## Resources

- [Circle Bridge Kit Documentation](https://developers.circle.com/bridge-kit) (Recommended)
- [Circle CCTP Documentation](https://developers.circle.com/stablecoin/docs/cctp-overview) (Reference)
- [LayerZero Documentation](https://layerzero.gitbook.io/docs/)
- [Hyperlane Documentation](https://docs.hyperlane.xyz/)
- [Yearn Finance Documentation](https://docs.yearn.fi/)

## License

TBD
