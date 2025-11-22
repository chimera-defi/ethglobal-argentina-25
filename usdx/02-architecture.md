# USDX Architecture Design

## System Architecture

### Layer 1: Smart Contracts

#### Core Contracts

1. **USDXVault.sol**
   - Manages USDC deposits via OVault/Yield Routes
   - Mints/burns USDX tokens
   - Tracks user collateral balances (OVault/Yield Routes positions)
   - Integrates with OVault (LayerZero) and Yield Routes (Hyperlane)
   - Handles cross-chain position tracking

2. **USDXToken.sol**
   - ERC20 token implementation
   - Cross-chain aware (can be paused on specific chains)
   - Mint/burn authorization (only vault can mint/burn)

3. **CrossChainBridge.sol**
   - Handles cross-chain USDX transfers
   - Integrates with LayerZero and Hyperlane
   - Manages message passing and verification
   - Coordinates burn on source chain and mint on destination chain

4. **OVault Integration** (LayerZero)
   - Wraps Yearn USDC vault
   - Provides cross-chain access to yield positions
   - Tracks positions across chains
   - Yield accrues automatically in Yearn vault

5. **Yield Routes Integration** (Hyperlane)
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
- **Bridge Kit SDK**: For cross-chain USDC transfers
- **Bridge Kit UI Components**: Pre-built React components for bridge functionality
- **Bridge Kit API**: Backend API for transfer status tracking (optional)
- **Webhook Support**: For transfer completion notifications

### Layer 4: Infrastructure Services

#### Off-Chain Services
- **Bridge Kit Service**: Backend service using Bridge Kit SDK for USDC transfers
- **Webhook Handler**: Process Bridge Kit webhooks for transfer completion
- Indexer: Track cross-chain transactions
- API: Provide aggregated balance data
- Monitoring: Track vault health, yield rates
- Analytics: Protocol metrics dashboard

#### Bridge Kit Architecture
- **Frontend**: Uses Bridge Kit React components and SDK
- **Backend Service**: Uses Bridge Kit SDK for automated transfers
- **Webhooks**: Bridge Kit sends webhooks on transfer status changes
- **Smart Contracts**: Called by backend service after Bridge Kit transfers complete

## Contract Interaction Flow

### Simplified Flow with OVault/Yield Routes

```
User → Bridge Kit SDK → USDC bridged to source chain
                ↓
         USDXVault → OVault/Yield Routes → Yearn USDC Vault
                ↓
         USDXToken (mint on any chain)
                ↓
         Yield accrues automatically in Yearn vault
```

### Detailed Flow

```
1. User bridges USDC (Chain A → Chain B) via Bridge Kit
2. USDC arrives on Chain B (source chain, e.g., Ethereum)
3. User deposits USDC into USDXVault on Chain B
4. USDXVault deposits into OVault/Yield Routes
5. OVault/Yield Routes deposits into Yearn USDC vault
6. User receives OVault/Yield Routes position
7. User can mint USDX on any chain using OVault/Yield Routes position
8. Yield accrues automatically in Yearn vault on Chain B
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
