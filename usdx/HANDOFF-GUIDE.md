# USDX Protocol - Handoff Guide for Development Teams

## Purpose

This guide provides essential information for different development teams/agents taking over the USDX protocol implementation. It consolidates key decisions, architecture details, and implementation priorities.

## Quick Start

### For Smart Contract Developers
1. Read **[02-architecture.md](./02-architecture.md)** - Complete architecture
2. Read **[05-technical-specification.md](./05-technical-specification.md)** - Contract interfaces
3. Review **[RESEARCH-bridge-kit.md](./RESEARCH-bridge-kit.md)** - Bridge Kit integration
4. Review **[RESEARCH-hyperlane.md](./RESEARCH-hyperlane.md)** - Hyperlane integration
5. Start with Phase 2 in **[06-implementation-plan.md](./06-implementation-plan.md)**

### For Frontend Developers
1. Read **[01-overview.md](./01-overview.md)** - High-level overview
2. Read **[03-flow-diagrams.md](./03-flow-diagrams.md)** - User flows
3. Review **[RESEARCH-bridge-kit.md](./RESEARCH-bridge-kit.md)** - Bridge Kit SDK usage
4. Start with Phase 4 in **[06-implementation-plan.md](./06-implementation-plan.md)**

### For Backend/Infrastructure Developers
1. Read **[02-architecture.md](./02-architecture.md)** - System architecture
2. Review **[RESEARCH-bridge-kit.md](./RESEARCH-bridge-kit.md)** - Bridge Kit backend integration
3. Review **[10-open-questions.md](./10-open-questions.md)** - Open questions
4. Start with Phase 4 infrastructure tasks

## Architecture Summary

### Hub-and-Spoke Model

**Hub Chain (Ethereum)**:
- All USDC collateral storage
- All yield generation (Yearn USDC vault)
- USDXVault contract
- OVault/Yield Routes integration

**Spoke Chains (Polygon, Arbitrum, Optimism, etc.)**:
- USDXToken contract
- USDXSpokeMinter contract
- CrossChainBridge contract
- No USDC collateral (all on hub)

### Key Design Decisions

1. **Bridge Kit for USDC**: Use Circle Bridge Kit SDK (not direct CCTP)
   - No API key required
   - SDK-only (custom UI required)
   - Works directly with smart contracts

2. **OVault + Yield Routes for Yield**: Dual strategy
   - Primary: LayerZero OVault
   - Secondary: Hyperlane Yield Routes
   - Both wrap Yearn USDC vault

3. **LayerZero + Hyperlane for USDX**: Dual protocol
   - Primary: LayerZero
   - Secondary: Hyperlane
   - Provides redundancy

4. **Yearn USDC Vault**: Single source of yield
   - All collateral in one vault
   - ERC-4626 compatible
   - Well-audited and battle-tested

## Critical Implementation Details

### Smart Contracts

**Core Contracts**:
- `USDXVault.sol` - Hub chain only, manages USDC deposits
- `USDXToken.sol` - All chains, ERC20 token
- `USDXSpokeMinter.sol` - Spoke chains only, allows minting USDX
- `CrossChainBridge.sol` - All chains, handles USDX transfers

**Key Interfaces**: See **[05-technical-specification.md](./05-technical-specification.md)**

### Bridge Kit Integration

**Package**: `@circle-fin/bridge-kit` + `@circle-fin/adapter-viem-v2`

**Key Points**:
- No API key required
- SDK-only (build custom UI)
- Automatic attestation polling
- Status tracking via callbacks

**Usage Pattern**:
```typescript
const kit = new BridgeKit({
  adapter: createViemAdapter({ /* config */ })
});

const transfer = await kit.transfer({
  amount: '1000000',
  recipient: vaultAddress,
  onStatusUpdate: (status) => { /* update UI */ }
});
```

### OVault/Yield Routes Integration

**OVault (LayerZero)**:
- Primary yield solution
- Wraps Yearn USDC vault
- Cross-chain position access

**Yield Routes (Hyperlane)**:
- Secondary yield solution
- Wraps Yearn USDC vault
- Redundancy/fallback

**Integration**: Both integrated into USDXVault contract

### Cross-Chain Messaging

**LayerZero**:
- Primary protocol for USDX transfers
- OApp standard recommended
- Oracle + Relayer network

**Hyperlane**:
- Secondary protocol for USDX transfers
- Multisig ISM (5-of-9 validators) recommended
- Validator network

## User Flows

### Deposit Flow
1. User bridges USDC from Spoke → Hub via Bridge Kit
2. USDC arrives on Hub Chain
3. User deposits into USDXVault
4. USDXVault → OVault/Yield Routes → Yearn vault
5. User receives position

### Mint Flow
1. User has OVault/Yield Routes position on Hub
2. User calls USDXSpokeMinter on Spoke Chain
3. Spoke minter verifies position on Hub
4. USDXToken.mint() on Spoke Chain
5. User receives USDX

### Transfer Flow
1. User burns USDX on Spoke Chain A
2. CrossChainBridge sends message via LayerZero/Hyperlane
3. Message arrives on Spoke Chain B
4. CrossChainBridge verifies message
5. USDXToken.mint() on Spoke Chain B

### Withdrawal Flow
1. User burns USDX
2. User withdraws from USDXVault on Hub
3. OVault/Yield Routes withdraws from Yearn vault
4. User receives USDC
5. User bridges USDC back to Spoke via Bridge Kit

## Open Questions & Decisions Needed

### High Priority

1. **Yield Distribution Model**
   - Option A: Protocol treasury (recommended)
   - Option B: Shared with users
   - Option C: Buyback and burn
   - **Action**: Finalize decision before implementation

2. **Fee Structure**
   - Who pays cross-chain transfer fees?
   - Protocol fee percentage?
   - **Action**: Define fee model

3. **Access Control**
   - Multi-sig configuration?
   - Number of signers?
   - **Action**: Set up multi-sig wallet

### Medium Priority

4. **Upgradeability**
   - UUPS pattern confirmed?
   - Which contracts upgradeable?
   - **Action**: Finalize upgrade strategy

5. **Pause Mechanism**
   - Per-chain or global pause?
   - Who can pause?
   - **Action**: Implement pause logic

### Low Priority

6. **Rate Limits**
   - Bridge Kit rate limits?
   - Message rate limits?
   - **Action**: Test and document

## Implementation Priorities

### Phase 1: Core Contracts (Weeks 1-2)
- [ ] USDXToken.sol
- [ ] USDXVault.sol (basic deposit/withdrawal)
- [ ] AccessControl setup

### Phase 2: Yield Integration (Week 3)
- [ ] OVault integration
- [ ] Yield Routes integration
- [ ] Yearn vault integration

### Phase 3: Cross-Chain (Weeks 4-5)
- [ ] LayerZero integration
- [ ] Hyperlane integration
- [ ] CrossChainBridge.sol
- [ ] USDXSpokeMinter.sol

### Phase 4: Testing & Security (Weeks 6-7)
- [ ] Unit tests (90%+ coverage)
- [ ] Integration tests
- [ ] Fork tests
- [ ] Security audit preparation

### Phase 5: Frontend (Weeks 8-11)
- [ ] Bridge Kit SDK integration
- [ ] Custom UI components
- [ ] Multi-chain wallet connection
- [ ] Transaction status tracking

## Testing Strategy

### Testnets
- **Ethereum**: Sepolia
- **Polygon**: Mumbai
- **Arbitrum**: Sepolia
- **Optimism**: Sepolia

### Testing Checklist
- [ ] Deposit flow (Spoke → Hub)
- [ ] Mint flow (Hub → Spoke)
- [ ] Transfer flow (Spoke → Spoke)
- [ ] Withdrawal flow (Hub → Spoke)
- [ ] Yield accrual
- [ ] Error handling
- [ ] Edge cases

## Security Considerations

### Critical
- Multi-sig for admin functions
- Comprehensive security audits
- Rate limiting
- Pause mechanism

### Important
- Access control
- Reentrancy protection
- Input validation
- Error handling

## Documentation Structure

### Core Documents
- `01-overview.md` - High-level overview
- `02-architecture.md` - Complete architecture
- `03-flow-diagrams.md` - User flows
- `05-technical-specification.md` - Contract specs
- `06-implementation-plan.md` - Implementation roadmap

### Research Documents
- `RESEARCH-bridge-kit.md` - Bridge Kit complete guide
- `RESEARCH-hyperlane.md` - Hyperlane complete guide
- `08-layerzero-research.md` - LayerZero research
- `13-layerzero-ovault-research.md` - OVault research

### Reference Documents
- `10-open-questions.md` - Open questions
- `04-concept-exploration.md` - Design decisions

## Key Resources

### External Documentation
- **Bridge Kit**: https://developers.circle.com/bridge-kit
- **LayerZero**: https://layerzero.gitbook.io/docs/
- **Hyperlane**: https://docs.hyperlane.xyz/
- **Yearn**: https://docs.yearn.fi/

### GitHub Repositories
- Bridge Kit: `@circle-fin/bridge-kit`
- LayerZero: `@layerzerolabs/lz-evm-protocol-v2`
- Hyperlane: `@hyperlane-xyz/core`

## Common Pitfalls to Avoid

1. **Don't assume Bridge Kit has UI components** - Build custom UI
2. **Don't forget Bridge Kit needs no API key** - Works directly with contracts
3. **Don't deploy yield contracts on spokes** - Only on hub chain
4. **Don't forget OVault/Yield Routes are ERC-4626** - Standard interface
5. **Don't skip position verification** - Always verify hub positions before minting

## Getting Help

### Questions?
- Review **[10-open-questions.md](./10-open-questions.md)** first
- Check research documents for protocol-specific questions
- Review architecture document for system design questions

### Issues?
- Check implementation plan for current phase
- Review technical specification for interface details
- Consult flow diagrams for user journey

## Next Steps

1. **Read this guide completely**
2. **Review architecture document**
3. **Set up development environment**
4. **Start with Phase 1 tasks**
5. **Ask questions early**

## Notes for Handoff

- All major architecture decisions are documented
- Research is consolidated in RESEARCH-*.md files
- Open questions are clearly marked in 10-open-questions.md
- Implementation plan is phased and prioritized
- Technical specifications are detailed

**Status**: Design phase complete, ready for implementation
