# USDX Architecture Design

## Hub-and-Spoke Model

USDX uses a **hub-and-spoke architecture** where:
- **Hub Chain**: Single source chain (Ethereum) where all USDC collateral is held and yield is generated
- **Spoke Chains**: Other supported chains where users can mint USDX using their hub chain positions

### Key Principles
1. **Single Hub**: All USDC collateral and yield generation happens on one chain (Ethereum)
2. **USDC Flow**: Spoke → Hub (via Bridge Kit) for deposits, Hub → Spoke (via Bridge Kit) for withdrawals
3. **USDX Minting**: Users mint USDX on spoke chains using their hub chain OVault/Yield Routes positions
4. **Cross-Chain USDX**: USDX can transfer between spokes via LayerZero/Hyperlane

## System Architecture

### Layer 1: Smart Contracts

#### Core Contracts

1. **USDXVault.sol** (Hub Chain Only)
   - **Location**: Hub chain (Ethereum) only
   - Manages USDC deposits via OVault/Yield Routes
   - Mints/burns USDX tokens (on hub chain)
   - Tracks user collateral balances (OVault/Yield Routes positions)
   - Integrates with OVault (LayerZero) and Yield Routes (Hyperlane)
   - Handles cross-chain position tracking
   - Receives USDC from spoke chains via Bridge Kit

2. **USDXToken.sol** (All Chains)
   - ERC20 token implementation
   - Deployed on hub and all spoke chains
   - Cross-chain aware (can be paused on specific chains)
   - Mint/burn authorization (only vault can mint/burn on hub, spoke contracts can mint on spokes)

3. **CrossChainBridge.sol** (All Chains)
   - Handles cross-chain USDX transfers between spokes
   - Integrates with LayerZero and Hyperlane
   - Manages message passing and verification
   - Coordinates burn on source chain and mint on destination chain
   - Also handles USDX minting on spokes from hub positions

4. **USDXSpokeMinter.sol** (Spoke Chains Only)
   - Allows users to mint USDX on spoke chains
   - Verifies user's OVault/Yield Routes position on hub chain
   - Calls USDXToken.mint() on spoke chain
   - Tracks minted USDX per user

5. **OVault Integration** (LayerZero) - Hub Chain
   - **Location**: Hub chain (Ethereum) only
   - Wraps Yearn USDC vault
   - Provides cross-chain access to yield positions
   - Tracks positions across chains
   - Yield accrues automatically in Yearn vault
   - Allows spoke chains to verify positions

6. **Yield Routes Integration** (Hyperlane) - Hub Chain
   - **Location**: Hub chain (Ethereum) only
   - Wraps Yearn USDC vault
   - Provides cross-chain access to yield positions
   - Tracks positions across chains
   - Yield accrues automatically in Yearn vault
   - Used as secondary/redundant option to OVault

### Layer 2: Cross-Chain Infrastructure

#### LayerZero Integration
- **Endpoint**: LayerZero endpoint contract
- **OApp**: USDX OApp implementation for USDX transfers
- **OVault**: Cross-chain yield vault (wraps Yearn USDC vault)
- **Message Types**: 
  - Mint request
  - Burn confirmation
  - Balance sync
  - OVault position sync

#### Hyperlane Integration
- **Mailbox**: Hyperlane mailbox contract
- **Interchain Security Module (ISM)**: Custom ISM for USDX
- **Yield Routes**: Cross-chain yield vault (wraps Yearn USDC vault)
- **Message Types**: Same as LayerZero (redundancy/fallback)

### Layer 3: Frontend/UI

#### Components
- Multi-chain wallet connection (WalletConnect, MetaMask)
- Chain selector
- Deposit interface
- Mint interface
- Cross-chain transfer interface
- Balance display (cross-chain aggregated)
- Transaction history

#### Bridge Kit Integration
- **Bridge Kit SDK**: For cross-chain USDC transfers (SDK only, no UI components)
- **Custom UI Required**: We build our own UI using Bridge Kit SDK
- **No API Key**: Bridge Kit works directly with smart contracts
- **Adapter**: Uses `@circle-fin/adapter-viem-v2` for viem integration

### Layer 4: Infrastructure Services

#### Off-Chain Services
- **Bridge Kit Service**: Backend service using Bridge Kit SDK for USDC transfers
- **Webhook Handler**: Process Bridge Kit webhooks for transfer completion
- Indexer: Track cross-chain transactions
- API: Provide aggregated balance data
- Monitoring: Track vault health, yield rates
- Analytics: Protocol metrics dashboard

#### Bridge Kit Architecture
- **Frontend**: Custom UI built using Bridge Kit SDK
- **Backend Service**: Optional - can use Bridge Kit SDK for automated transfers
- **No Webhooks**: Bridge Kit is SDK-only, no webhook support
- **Status Tracking**: Built into SDK via callbacks/events
- **Smart Contracts**: Called directly by SDK (no backend required)

## Contract Interaction Flow

### Hub-and-Spoke Flow

```
Spoke Chain (User's Chain)
├── User has USDC
├── Bridge Kit → USDC bridged to Hub
└── User wants to mint USDX

Hub Chain (Ethereum)
├── USDC arrives via Bridge Kit
├── USDXVault → OVault/Yield Routes → Yearn USDC Vault
├── User receives OVault/Yield Routes position
└── Yield accrues automatically

Spoke Chain (User's Chain)
├── USDXSpokeMinter verifies hub position
├── USDXToken.mint() on spoke chain
└── User receives USDX on spoke chain
```

### Detailed Flow

```
1. User on Spoke Chain A bridges USDC to Hub Chain (Ethereum) via Bridge Kit
2. USDC arrives on Hub Chain
3. User deposits USDC into USDXVault on Hub Chain
4. USDXVault deposits into OVault/Yield Routes
5. OVault/Yield Routes deposits into Yearn USDC vault
6. User receives OVault/Yield Routes position on Hub Chain
7. User can mint USDX on any Spoke Chain using hub position:
   - USDXSpokeMinter verifies position on Hub Chain
   - USDXToken.mint() on Spoke Chain
8. Yield accrues automatically in Yearn vault on Hub Chain
9. USDX can transfer between Spoke Chains via LayerZero/Hyperlane
```

## Cross-Chain Message Flow

```
Chain A: User requests transfer
  ↓
USDXToken.burn() on Chain A
  ↓
CrossChainBridge.sendMessage() via LayerZero/Hyperlane
  ↓
Message arrives on Chain B
  ↓
CrossChainBridge.receiveMessage() verifies message
  ↓
USDXToken.mint() on Chain B
```

## Security Considerations

> **Lessons from MIM**: MIM suffered from security vulnerabilities due to complex multi-protocol interactions, bridge dependencies, and insufficient access controls. USDX addresses these through simplified architecture, multiple bridge redundancy, and comprehensive security measures.

1. **Access Control**: Role-based access control (RBAC)
   - Admin: Protocol upgrades, parameter changes
   - Vault: Mint/burn USDX
   - Yield Manager: Manage yield strategies
   - Peg Manager: Manage peg stability mechanisms (new)
   - Emergency Pauser: Can pause specific functions (new)

2. **Rate Limiting**: Prevent rapid mint/burn cycles
   - Cooldown periods for large operations
   - Daily limits per user
   - Circuit breakers for unusual activity

3. **Pause Mechanism**: Emergency pause for all chains
   - Per-function pause capability
   - Time-locked unpause (24-48 hours)
   - Multi-sig required for pause/unpause

4. **Multi-sig**: Admin functions require multi-sig
   - Minimum 3-of-5 for critical operations
   - Minimum 4-of-7 for emergency operations
   - Timelock for non-emergency changes

5. **Audits**: Comprehensive security audits before mainnet
   - Multiple audit firms
   - Bug bounty program
   - Continuous security monitoring

6. **Cross-Chain Security**:
   - LayerZero: Relayer network + Oracle network
   - Hyperlane: Validator network + ISM
   - **Bridge Redundancy**: Both bridges active simultaneously
   - **Failover Mechanism**: Automatic switch if one bridge fails
   - **Message Verification**: Double verification for critical operations

7. **Simplified Architecture** (MIM Lesson):
   - Single collateral type (USDC) reduces attack surface
   - Single yield strategy (Yearn) reduces complexity
   - Hub-and-spoke model centralizes security-critical operations
   - Minimal external dependencies

8. **Reentrancy Protection**:
   - OpenZeppelin ReentrancyGuard on all state-changing functions
   - Checks-effects-interactions pattern enforced
   - Cross-chain callback locks

9. **Input Validation**:
   - All inputs validated and sanitized
   - Bounds checking on all amounts
   - Address validation (non-zero, not contract where not allowed)

10. **Time-locked Upgrades**:
    - All protocol changes require timelock (minimum 48 hours)
    - Community notification period
    - Emergency upgrades only with multi-sig approval

## Yield Strategy Architecture (Simplified with OVault/Yield Routes)

### Yield Source: Yearn USDC Vault
- **Single Source**: All USDC collateral deposited into Yearn USDC vault
- **Location**: Source chain (Ethereum)
- **Management**: Handled by OVault/Yield Routes
- **Cross-Chain Access**: Via OVault/Yield Routes representative tokens

### How It Works
1. **Deposit**: USDC → OVault/Yield Routes → Yearn USDC vault
2. **Yield Accrual**: Automatic via Yearn vault
3. **Cross-Chain Access**: OVault/Yield Routes mints representative tokens on other chains
4. **Withdrawal**: Reverse flow through OVault/Yield Routes

### Benefits
- **Simplified**: No need for YieldStrategy contract per chain
- **Single Source**: All yield from one Yearn vault
- **Automatic**: Yield accrues without manual intervention
- **Cross-Chain**: Access yield position from any chain
- **Reduced Gas**: No need to bridge yield tokens

### Yield Distribution
- **Option A**: Yield accrues to protocol treasury (recommended)
- **Option B**: Yield shared with USDX holders (rebasing)
- **Option C**: Yield used to buy back USDX (deflationary)

**Recommendation**: Option A for simplicity and protocol sustainability

## Peg Stability Mechanisms

> **Critical MIM Lesson**: MIM failed to maintain peg stability due to insufficient mechanisms. USDX implements multiple layers of peg protection.

### Primary Peg Mechanism: Direct USDC Backing

1. **1:1 USDC Collateralization**
   - Every USDX minted is backed by 1 USDC (or more)
   - Direct redemption to USDC at any time
   - Transparent on-chain verification

2. **Immediate Redemption**
   - Users can burn USDX and receive USDC instantly
   - No delays or queuing
   - Works across all chains (via Bridge Kit)

### Secondary Peg Mechanisms

3. **Protocol Reserve Fund**
   - Maintains USDC reserves for peg support
   - Used for arbitrage opportunities
   - Funded from protocol yield (percentage of yield)

4. **Arbitrage Incentives**
   - Direct redemption path creates natural arbitrage
   - If USDX < $1.00: Buy USDX, redeem for USDC, profit
   - If USDX > $1.00: Mint USDX, sell for USDC, profit
   - No fees on redemption to encourage arbitrage

5. **Liquidity Pool Management**
   - Maintain deep liquidity pools on major DEXs
   - Protocol can provide liquidity directly
   - Incentivize LP providers if needed

6. **Peg Monitoring and Alerts**
   - Real-time price monitoring
   - Automatic alerts if peg deviates >0.5%
   - Protocol can intervene if peg deviates >1%

7. **Circuit Breakers**
   - Pause minting if peg deviates significantly (>2%)
   - Allow redemption to continue (helps restore peg)
   - Automatic resume when peg stabilizes

### Peg Stability Architecture

```
Peg Stability System
├── Primary: Direct USDC Backing (1:1)
├── Secondary: Protocol Reserve Fund
├── Tertiary: Liquidity Pools
├── Monitoring: Real-time Price Tracking
└── Intervention: Circuit Breakers + Manual Actions
```

### Comparison with MIM

| Feature | MIM | USDX |
|---------|-----|------|
| **Backing** | Multiple yield-bearing assets | Single USDC (most liquid) |
| **Collateralization** | 80-90% (leveraged) | 100%+ (1:1, can adjust) |
| **Redemption** | Complex, sometimes delayed | Direct, instant |
| **Reserve Fund** | None | Yes (from yield) |
| **Arbitrage** | Limited mechanisms | Strong incentives |
| **Monitoring** | Limited | Comprehensive |

## Bridge Redundancy and Failover

> **Critical MIM Lesson**: MIM's over-reliance on Multichain bridge led to protocol failure when the bridge collapsed. USDX uses multiple bridges with automatic failover.

### Multi-Bridge Architecture

1. **Primary Bridge: Circle Bridge Kit (CCTP)**
   - Used for USDC transfers (Spoke ↔ Hub)
   - Most trusted and secure
   - Native Circle support

2. **Secondary Bridges: LayerZero + Hyperlane**
   - Used for USDX transfers (Spoke ↔ Spoke)
   - Both active simultaneously
   - Automatic failover if one fails

### Failover Mechanisms

3. **Bridge Health Monitoring**
   - Real-time monitoring of all bridges
   - Track success rates, delays, failures
   - Automatic routing based on bridge health

4. **Automatic Failover**
   - If LayerZero fails: Route to Hyperlane
   - If Hyperlane fails: Route to LayerZero
   - If both fail: Pause cross-chain transfers, allow redemption

5. **Manual Override**
   - Admin can manually switch bridges
   - Emergency pause for all bridges
   - Gradual rollout of new bridges

### Bridge Risk Mitigation

6. **No Single Point of Failure**
   - Multiple bridges for redundancy
   - Different security models (LayerZero vs Hyperlane)
   - Independent validator sets

7. **Bridge Limits**
   - Per-bridge TVL limits
   - Per-transaction limits
   - Gradual increase as confidence grows

## Liquidity Management

> **MIM Lesson**: MIM struggled with liquidity, leading to peg instability. USDX proactively manages liquidity.

### Liquidity Strategy

1. **Primary Liquidity Pools**
   - USDX/USDC pools on major DEXs (Uniswap, Curve, etc.)
   - Maintained on all spoke chains
   - Minimum liquidity thresholds

2. **Protocol-Owned Liquidity**
   - Protocol can provide liquidity directly
   - Funded from protocol treasury
   - Managed by yield managers

3. **Liquidity Incentives**
   - LP token rewards (if needed)
   - Fee sharing with LPs
   - Bootstrap liquidity on new chains

4. **Liquidity Monitoring**
   - Track pool depths across all chains
   - Alert if liquidity drops below thresholds
   - Automatic intervention if needed

## State Management

### Per-Chain State
- Total USDC deposited
- Total USDX minted
- Yield accrued
- User balances
- **Peg deviation tracking** (new)
- **Bridge health status** (new)
- **Liquidity pool addresses** (new)

### Cross-Chain State
- USDX supply per chain
- Cross-chain transfer queue
- Message nonces (prevent replay attacks)
- **Bridge routing preferences** (new)
- **Peg status per chain** (new)
