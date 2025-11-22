# USDX Architecture Design

## System Architecture

### Layer 1: Smart Contracts

#### Core Contracts

1. **USDXVault.sol**
   - Manages USDC deposits
   - Mints/burns USDX tokens
   - Tracks user collateral balances
   - Integrates with yield strategies
   - Handles CCTP for USDC transfers

2. **USDXToken.sol**
   - ERC20 token implementation
   - Cross-chain aware (can be paused on specific chains)
   - Mint/burn authorization (only vault can mint/burn)

3. **CrossChainBridge.sol**
   - Handles cross-chain USDX transfers
   - Integrates with LayerZero and Hyperlane
   - Manages message passing and verification
   - Coordinates burn on source chain and mint on destination chain

4. **YieldStrategy.sol**
   - Manages yield generation on idle USDC
   - Integrates with DeFi protocols (Aave, Compound, etc.)
   - Tracks yield accrual
   - Handles yield distribution (protocol revenue)

5. **CCTPAdapter.sol**
   - Wrapper around Circle CCTP contracts
   - Handles USDC cross-chain transfers
   - Manages attestation and verification

### Layer 2: Cross-Chain Infrastructure

#### LayerZero Integration
- **Endpoint**: LayerZero endpoint contract
- **OApp**: USDX OApp implementation
- **Message Types**: 
  - Mint request
  - Burn confirmation
  - Balance sync

#### Hyperlane Integration
- **Mailbox**: Hyperlane mailbox contract
- **Interchain Security Module (ISM)**: Custom ISM for USDX
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

### Layer 4: Infrastructure Services

#### Off-Chain Services (Optional)
- Indexer: Track cross-chain transactions
- API: Provide aggregated balance data
- Monitoring: Track vault health, yield rates
- Analytics: Protocol metrics dashboard

## Contract Interaction Flow

```
User → USDXVault → USDXToken (mint)
                ↓
         YieldStrategy (deposit USDC)
                ↓
         CCTPAdapter (if cross-chain USDC needed)
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

## Yield Strategy Architecture

### Strategy Options
1. **Aave**: Lend USDC for aUSDC tokens
2. **Compound**: Lend USDC for cUSDC tokens
3. **Yearn**: Deposit into USDC vault
4. **Custom**: Direct lending protocols

### Yield Distribution
- **Option A**: Yield accrues to protocol treasury
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
