# Hub-and-Spoke Architecture

## Overview

USDX uses a **hub-and-spoke architecture** where all USDC collateral and yield generation is centralized on a single hub chain, while USDX can be minted and used on multiple spoke chains.

## Architecture Model

```
                    ┌─────────────┐
                    │  Hub Chain  │
                    │  (Ethereum) │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Spoke Chain │    │ Spoke Chain │    │ Spoke Chain │
│   Polygon   │    │  Arbitrum   │    │  Optimism   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Hub Chain (Ethereum)

### Responsibilities
- **USDC Collateral Storage**: All USDC collateral held here
- **Yield Generation**: Single Yearn USDC vault for all yield
- **Position Tracking**: OVault/Yield Routes track all user positions
- **Primary Minting**: USDX can be minted directly on hub
- **Withdrawal Processing**: All withdrawals processed here

### Contracts Deployed
- `USDXVault.sol` - Main vault contract
- `USDXToken.sol` - USDX token contract
- `OVault` - Cross-chain yield vault (wraps Yearn)
- `Yield Routes` - Alternative yield vault (wraps Yearn)
- `Yearn USDC Vault` - Single source of yield

### USDC Flow
- **Inbound**: Receives USDC from spoke chains via Bridge Kit
- **Outbound**: Sends USDC to spoke chains via Bridge Kit (for withdrawals)

## Spoke Chains (Polygon, Arbitrum, Optimism, etc.)

### Responsibilities
- **USDX Minting**: Users can mint USDX using hub positions
- **USDX Usage**: Users can use USDX on spoke chains
- **Cross-Chain Transfers**: USDX can transfer between spokes

### Contracts Deployed
- `USDXToken.sol` - USDX token contract
- `USDXSpokeMinter.sol` - Allows minting USDX using hub positions
- `CrossChainBridge.sol` - Handles USDX transfers between spokes

### USDC Flow
- **Outbound**: Users bridge USDC to hub via Bridge Kit
- **Inbound**: Users receive USDC from hub via Bridge Kit (for withdrawals)

## Key Flows

### 1. Deposit Flow (Spoke → Hub)

```
Spoke Chain:
1. User has USDC
2. User initiates Bridge Kit transfer to Hub Chain
3. USDC bridged via CCTP

Hub Chain:
4. USDC arrives on Hub Chain
5. User deposits into USDXVault
6. USDXVault → OVault/Yield Routes → Yearn vault
7. User receives OVault/Yield Routes position
```

### 2. Mint Flow (Hub → Spoke)

```
Hub Chain:
1. User has OVault/Yield Routes position

Spoke Chain:
2. User calls USDXSpokeMinter.mintUSDXFromOVault()
3. Spoke minter verifies position on Hub Chain
4. USDXToken.mint() on Spoke Chain
5. User receives USDX on Spoke Chain
```

### 3. Transfer Flow (Spoke → Spoke)

```
Spoke Chain A:
1. User has USDX
2. User calls transferCrossChain(amount, Spoke Chain B)
3. USDXToken.burn() on Spoke Chain A
4. CrossChainBridge sends message via LayerZero/Hyperlane

Spoke Chain B:
5. Message arrives
6. CrossChainBridge verifies message
7. USDXToken.mint() on Spoke Chain B
8. User receives USDX on Spoke Chain B
```

### 4. Withdrawal Flow (Spoke → Hub → Spoke)

```
Spoke Chain:
1. User burns USDX

Hub Chain:
2. User calls withdrawUSDCFromOVault(amount)
3. OVault/Yield Routes withdraws from Yearn vault
4. USDC returned to user
5. User bridges USDC back to Spoke Chain via Bridge Kit

Spoke Chain:
6. User receives USDC (with accrued yield)
```

## Benefits of Hub-and-Spoke Model

### 1. Centralized Yield Management
- **Single Source**: All yield from one Yearn vault
- **Simplified**: No need to manage yield per chain
- **Efficient**: Better capital efficiency

### 2. Reduced Complexity
- **Fewer Contracts**: No yield management on spokes
- **Simpler Logic**: Hub handles all collateral
- **Easier Auditing**: Single point of yield generation

### 3. Better Security
- **Single Point**: One vault to secure
- **Well-Audited**: Yearn vault is battle-tested
- **Reduced Attack Surface**: Less code on spokes

### 4. Cost Efficiency
- **Gas Savings**: No yield operations on spokes
- **Lower Fees**: Single yield source
- **Optimized**: Hub chain optimized for yield

### 5. Cross-Chain Flexibility
- **Any Spoke**: Users can mint on any spoke
- **Easy Transfers**: USDX transfers between spokes
- **Hub Access**: Users can also mint on hub

## Contract Deployment Matrix

| Contract | Hub Chain | Spoke Chains |
|----------|-----------|--------------|
| USDXVault | ✅ | ❌ |
| USDXToken | ✅ | ✅ |
| USDXSpokeMinter | ❌ | ✅ |
| CrossChainBridge | ✅ | ✅ |
| OVault | ✅ | ❌ |
| Yield Routes | ✅ | ❌ |
| Yearn Vault | ✅ | ❌ |

## USDC Flow Summary

### Deposit (Spoke → Hub)
- **Bridge**: Bridge Kit (CCTP)
- **Direction**: Spoke → Hub
- **Purpose**: Deposit USDC for collateral

### Withdrawal (Hub → Spoke)
- **Bridge**: Bridge Kit (CCTP)
- **Direction**: Hub → Spoke
- **Purpose**: Return USDC to user

## USDX Flow Summary

### Mint (Hub → Spoke)
- **Bridge**: OVault/Yield Routes
- **Direction**: Hub position → Spoke USDX
- **Purpose**: Mint USDX on spoke using hub position

### Transfer (Spoke → Spoke)
- **Bridge**: LayerZero/Hyperlane
- **Direction**: Spoke → Spoke
- **Purpose**: Transfer USDX between spokes

## Yield Flow

### Generation
- **Location**: Hub Chain only
- **Source**: Yearn USDC vault
- **Accrual**: Automatic, continuous

### Distribution
- **Option A**: Protocol treasury (recommended)
- **Option B**: Shared with users
- **Option C**: Buyback and burn

## Security Considerations

### Hub Chain Security
- **Critical**: All collateral on hub chain
- **Protection**: Multi-sig, audits, monitoring
- **Backup**: OVault + Yield Routes redundancy

### Spoke Chain Security
- **Limited Risk**: No collateral on spokes
- **Protection**: Position verification, rate limiting
- **Monitoring**: Track minted USDX vs hub collateral

### Bridge Security
- **Bridge Kit**: For USDC (CCTP)
- **LayerZero/Hyperlane**: For USDX
- **Redundancy**: Multiple bridges for critical flows

## Scalability

### Adding New Spokes
- **Easy**: Deploy USDXToken + USDXSpokeMinter
- **No Hub Changes**: Hub remains unchanged
- **Fast**: Can add spokes incrementally

### Hub Capacity
- **Single Vault**: Yearn vault handles all collateral
- **Scalable**: Yearn vault scales well
- **Monitoring**: Track vault capacity

## Monitoring

### Hub Chain Metrics
- Total USDC collateral
- Total USDX minted (hub + spokes)
- Yield accrual rate
- Vault utilization

### Spoke Chain Metrics
- USDX minted per spoke
- Cross-chain transfer volume
- Active users per spoke

## Resources

- **[02-architecture.md](./02-architecture.md)** - Detailed architecture
- **[03-flow-diagrams.md](./03-flow-diagrams.md)** - Flow diagrams
- **[15-architecture-simplification-summary.md](./15-architecture-simplification-summary.md)** - Architecture simplification
