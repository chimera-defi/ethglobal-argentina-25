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

1. **Access Control**: Role-based access control (RBAC)
   - Admin: Protocol upgrades, parameter changes
   - Vault: Mint/burn USDX
   - Yield Manager: Manage yield strategies

2. **Rate Limiting**: Prevent rapid mint/burn cycles
3. **Pause Mechanism**: Emergency pause for all chains
4. **Multi-sig**: Admin functions require multi-sig
5. **Audits**: Comprehensive security audits before mainnet

6. **Cross-Chain Security**:
   - LayerZero: Relayer network + Oracle network
   - Hyperlane: Validator network + ISM
   - Consider using both for redundancy

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

## State Management

### Per-Chain State
- Total USDC deposited
- Total USDX minted
- Yield accrued
- User balances

### Cross-Chain State
- USDX supply per chain
- Cross-chain transfer queue
- Message nonces (prevent replay attacks)
