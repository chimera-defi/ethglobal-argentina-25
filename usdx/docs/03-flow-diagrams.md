# USDX Flow Diagrams

## Downloadable Diagram Assets

High-resolution SVG exports for every diagram in this document (plus the main USDX architecture view from the README) now live in `docs/assets/diagrams/`:

- [LayerZero Architecture](./assets/diagrams/layerzero-architecture.svg)
- [Hub-and-Spoke Deposit Flow](./assets/diagrams/deposit-flow-spoke-to-hub.svg)
- [Hub-to-Spoke Mint Flow](./assets/diagrams/mint-flow-hub-to-spoke.svg)
- [Cross-Chain Transfer (LayerZero)](./assets/diagrams/cross-chain-transfer-layerzero.svg)
- [Cross-Chain Transfer (Hyperlane)](./assets/diagrams/cross-chain-transfer-hyperlane.svg)
- [Bridge Kit Flow – Frontend](./assets/diagrams/bridge-kit-frontend.svg)
- [Bridge Kit Flow – Backend](./assets/diagrams/bridge-kit-backend.svg)
- [Complete Yield Flow](./assets/diagrams/yield-flow-complete.svg)
- [Cross-Chain Mint Flow](./assets/diagrams/cross-chain-mint.svg)
- [Dual Bridge Strategy](./assets/diagrams/dual-bridge-strategy.svg)
- [End-to-End User Journey](./assets/diagrams/user-journey.svg)

## 1. Hub-and-Spoke Deposit Flow

### Spoke Chain → Hub Chain (USDC Deposit)

```
┌─────────────────┐
│  Spoke Chain    │
│  (e.g., Polygon)│
└────┬────────────┘
     │
     │ User has USDC
     │
     ▼
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. Bridge Kit SDK
     │    transfer(USDC → Hub)
     │
     ▼
┌─────────────────┐
│  Bridge Kit SDK │
│  - Bridges USDC │
│    to Hub Chain │
└────┬────────────┘
     │
     │ 2. USDC bridged via CCTP
     │
     └──────────────────────────────┐
                                    │
                                    │ 3. USDC arrives on Hub
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  Hub Chain      │
                           │  (Ethereum)     │
                           └────┬────────────┘
                                │
                                │ 4. depositUSDC(amount)
                                │
                                ▼
                           ┌─────────────────┐
                           │  USDXVault      │
                           │  (Hub Only)     │
                           │  - Receives USDC│
                           └────┬────────────┘
                                │
                                │ 5. Deposit into OVault/Yield Routes
                                │
                                ▼
                           ┌─────────────────┐
                           │  OVault /       │
                           │  Yield Routes   │
                           │  (Hub Only)     │
                           └────┬────────────┘
                                │
                                │ 6. Deposit into Yearn
                                │
                                ▼
                           ┌─────────────────┐
                           │  Yearn USDC     │
                           │  Vault          │
                           │  - Yield accrues│
                           │    automatically│
                           └─────────────────┘
```

### Hub Chain → Spoke Chain (USDX Mint)

```
┌─────────────────┐
│  Hub Chain      │
│  (Ethereum)     │
└────┬────────────┘
     │
     │ User has OVault/Yield Routes position
     │
     ▼
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. User wants USDX on Spoke Chain
     │
     ▼
┌─────────────────┐
│  Spoke Chain    │
│  (e.g., Polygon)│
└────┬────────────┘
     │
     │ 2. mintUSDXFromOVault(shares, hubChainId)
     │
     ▼
┌─────────────────┐
│USDXSpokeMinter  │
│  - Verifies     │
│    position on  │
│    Hub Chain    │
└────┬────────────┘
     │
     │ 3. Position verified via OVault/Yield Routes
     │
     ▼
┌─────────────────┐
│  USDXToken      │
│  (Spoke Chain)  │
│  - Mints USDX   │
│  - Transfers to │
│    user         │
└────┬────────────┘
     │
     │ 4. USDX transferred to user
     │
     ▼
┌─────────┐
│  User   │
│  (USDX) │
└─────────┘
```

## 2. Cross-Chain Transfer Flow (LayerZero)

```
Chain A (Source)                    Chain B (Destination)
┌──────────────┐                    ┌──────────────┐
│    User      │                    │             │
└──────┬───────┘                    │             │
       │                            │             │
       │ 1. transferCrossChain(    │             │
       │    amount, chainB)         │             │
       │                            │             │
       ▼                            │             │
┌─────────────────┐                 │             │
│  USDXToken      │                 │             │
│  - Burns USDX   │                 │             │
└──────┬──────────┘                 │             │
       │                            │             │
       │ 2. emit Burn event        │             │
       │                            │             │
       ▼                            │             │
┌─────────────────┐                 │             │
│CrossChainBridge │                 │             │
│  - Creates msg  │                 │             │
│  - Calls LZ      │                 │             │
│    endpoint     │                 │             │
└──────┬──────────┘                 │             │
       │                            │             │
       │ 3. send() via LayerZero    │             │
       │                            │             │
       └────────────────────────────┼─────────────┘
                                    │
                                    │ 4. Message arrives
                                    │
                                    ▼
                           ┌─────────────────┐
                           │CrossChainBridge │
                           │  - Verifies msg │
                           │  - Validates    │
                           └────────┬────────┘
                                    │
                                    │ 5. mintUSDX(amount, user)
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  USDXToken      │
                           │  - Mints USDX   │
                           │  - Transfers to │
                           │    user         │
                           └────────┬────────┘
                                    │
                                    │ 6. USDX transferred
                                    │
                                    ▼
                           ┌──────────────┐
                           │    User      │
                           │   (USDX)     │
                           └──────────────┘
```

## 3. Cross-Chain Transfer Flow (Hyperlane)

```
Chain A (Source)                    Chain B (Destination)
┌──────────────┐                    ┌──────────────┐
│    User      │                    │             │
└──────┬───────┘                    │             │
       │                            │             │
       │ 1. transferCrossChain(    │             │
       │    amount, chainB)         │             │
       │                            │             │
       ▼                            │             │
┌─────────────────┐                 │             │
│  USDXToken      │                 │             │
│  - Burns USDX   │                 │             │
└──────┬──────────┘                 │             │
       │                            │             │
       │ 2. emit Burn event        │             │
       │                            │             │
       ▼                            │             │
┌─────────────────┐                 │             │
│CrossChainBridge │                 │             │
│  - Creates msg  │                 │             │
│  - Calls Hyperlane│               │             │
│    mailbox      │                 │             │
└──────┬──────────┘                 │             │
       │                            │             │
       │ 3. dispatch() via Hyperlane│            │
       │                            │             │
       └────────────────────────────┼─────────────┘
                                    │
                                    │ 4. Validators verify
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  ISM (Custom)   │
                           │  - Verifies msg │
                           └────────┬────────┘
                                    │
                                    │ 5. handle() callback
                                    │
                                    ▼
                           ┌─────────────────┐
                           │CrossChainBridge │
                           │  - Processes msg│
                           └────────┬────────┘
                                    │
                                    │ 6. mintUSDX(amount, user)
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  USDXToken      │
                           │  - Mints USDX   │
                           └────────┬────────┘
                                    │
                                    │ 7. USDX transferred
                                    │
                                    ▼
                           ┌──────────────┐
                           │    User      │
                           │   (USDX)     │
                           └──────────────┘
```

## 4. Bridge Kit Integration Flow (USDC Cross-Chain)

### Option A: Frontend Integration (User-Initiated)

```
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. User initiates deposit from Chain A
     │    to Chain B vault via UI
     │
     ▼
┌─────────────────┐
│  Frontend UI    │
│  (Bridge Kit    │
│   Components)   │
└────┬────────────┘
     │
     │ 2. Bridge Kit SDK transfer()
     │
     ▼
┌─────────────────┐
│  Bridge Kit SDK │
│  - Burns USDC   │
│    on Chain A   │
│  - Polls for    │
│    attestation  │
└────┬────────────┘
     │
     │ 3. CCTP Attestation
     │    (Circle's network)
     │
     └──────────────────────────────┐
                                    │
                                    │ 4. Attestation received
                                    │    USDC minted on Chain B
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  USDXVault      │
                           │  (Chain B)      │
                           │  - Receives USDC│
                           │  - Credits user │
                           └────────┬────────┘
                                    │
                                    │ 5. Bridge Kit callback
                                    │    or webhook triggers
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  Frontend/Backend│
                           │  - Calls vault   │
                           │    mintUSDX()   │
                           └────────┬────────┘
                                    │
                                    │ 6. USDX minted to user
                                    │
                                    ▼
                           ┌──────────────┐
                           │    User      │
                           │   (USDX)     │
                           └──────────────┘
```

### Option B: Backend Service Integration (Automated)

```
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. User requests cross-chain deposit
     │
     ▼
┌─────────────────┐
│  Frontend UI    │
│  - User selects │
│    chains/amount│
└────┬────────────┘
     │
     │ 2. API call to backend
     │
     ▼
┌─────────────────┐
│  Backend Service│
│  (Bridge Kit SDK│
│   Integration)  │
└────┬────────────┘
     │
     │ 3. Bridge Kit SDK transfer()
     │
     ▼
┌─────────────────┐
│  Bridge Kit SDK │
│  - Burns USDC   │
│    on Chain A   │
│  - Polls for    │
│    attestation  │
└────┬────────────┘
     │
     │ 4. CCTP Attestation
     │
     └──────────────────────────────┐
                                    │
                                    │ 5. Webhook received
                                    │    Transfer completed
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  Backend Service│
                           │  - Processes     │
                           │    webhook       │
                           └────────┬────────┘
                                    │
                                    │ 6. Calls vault contract
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  USDXVault      │
                           │  (Chain B)      │
                           │  - Receives USDC│
                           │  - Mints USDX   │
                           └────────┬────────┘
                                    │
                                    │ 7. USDX transferred to user
                                    │
                                    ▼
                           ┌──────────────┐
                           │    User      │
                           │   (USDX)     │
                           └──────────────┘
```

## 5. Hub-and-Spoke Yield Flow

### Complete Flow: Spoke → Hub → Spoke

```
┌─────────────────┐
│  Spoke Chain A  │
│  (User starts) │
└────┬────────────┘
     │
     │ 1. User bridges USDC to Hub
     │    (via Bridge Kit)
     │
     └──────────────────────────────┐
                                    │
                                    │ 2. USDC arrives on Hub
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  Hub Chain      │
                           │  (Ethereum)     │
                           └────┬────────────┘
                                │
                                │ 3. depositUSDC(amount)
                                │
                                ▼
                           ┌─────────────────┐
                           │  USDXVault      │
                           │  (Hub Only)     │
                           └────┬────────────┘
                                │
                                │ 4. Deposit into OVault/Yield Routes
                                │
                                ▼
                           ┌─────────────────┐
                           │  OVault /       │
                           │  Yield Routes   │
                           │  (Hub Only)     │
                           └────┬────────────┘
                                │
                                │ 5. Deposit into Yearn
                                │
                                ▼
                           ┌─────────────────┐
                           │  Yearn USDC     │
                           │  Vault          │
                           │  - Yield accrues│
                           │    continuously │
                           └─────────────────┘
                                │
                                │ 6. User receives position
                                │
                                └──────────────────────────────┐
                                                               │
                                                               │ 7. User mints USDX on Spoke
                                                               │
                                                               ▼
                                                      ┌─────────────────┐
                                                      │  Spoke Chain B  │
                                                      │  (User mints)   │
                                                      └────┬────────────┘
                                                           │
                                                           │ 8. USDXSpokeMinter verifies hub position
                                                           │
                                                           ▼
                                                      ┌─────────────────┐
                                                      │  USDXToken      │
                                                      │  (Spoke Chain)  │
                                                      │  - Mints USDX   │
                                                      └─────────────────┘
```

### Cross-Chain Mint Flow

```
Chain A (User wants USDX)
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. User has OVault/Yield Routes position
     │    on source chain (Chain B)
     │
     ▼
┌─────────────────┐
│  USDXVault      │
│  (Chain A)      │
└────┬────────────┘
     │
     │ 2. mintUSDXFromOVault(shares, sourceChain)
     │
     ▼
┌─────────────────┐
│  OVault /       │
│  Yield Routes   │
│  - Verifies     │
│    position on  │
│    source chain │
│  - Mints        │
│    representative│
│    token        │
└────┬────────────┘
     │
     │ 3. Position verified
     │
     ▼
┌─────────────────┐
│  USDXToken      │
│  - Mints USDX   │
│  - Transfers to │
│    user         │
└─────────────────┘

Chain B (Source Chain - Ethereum)
┌─────────────────┐
│  Yearn USDC     │
│  Vault          │
│  - Yield        │
│    continues to │
│    accrue       │
└─────────────────┘
```

## 6. Complete Hub-and-Spoke User Journey

```
User Journey: Spoke → Hub → Spoke (Deposit, Mint, Transfer, Redeem)

Step 1: Bridge USDC (Spoke → Hub)
  User on Spoke Chain A → Bridge Kit SDK → USDC bridged to Hub Chain (Ethereum)
  USDC arrives on Hub Chain via CCTP

Step 2: Deposit into Vault (Hub Chain)
  User → depositUSDC(amount) → USDXVault (Hub Chain only)
  USDXVault → OVault/Yield Routes → Yearn USDC Vault
  User receives OVault/Yield Routes position on Hub Chain
  Yield starts accruing automatically in Yearn vault

Step 3: Mint USDX on Spoke Chain
  User → mintUSDXFromOVault(shares, hubChainId) → USDXSpokeMinter (Spoke Chain B)
  USDXSpokeMinter → verifies position on Hub Chain via OVault/Yield Routes
  USDXToken → mints USDX on Spoke Chain B
  User now has USDX on Spoke Chain B

Step 4: Use USDX on Spoke Chain
  User can use USDX on Spoke Chain B
  USDC collateral remains in Yearn vault on Hub Chain (earning yield)

Step 5: Cross-Chain USDX Transfer (Spoke → Spoke)
  User → transferCrossChain(amount, Spoke Chain C)
  USDXToken → burn USDX (Spoke Chain B)
  CrossChainBridge → send message via LayerZero/Hyperlane
  USDXToken → mint USDX (Spoke Chain C)

Step 6: Redeem (Spoke → Hub)
  User → burn USDX (Spoke Chain C)
  User → withdrawUSDCFromOVault(amount) → USDXVault (Hub Chain)
  OVault/Yield Routes → withdraws from Yearn → returns USDC
  User → Bridge Kit SDK → USDC bridged back to Spoke Chain A
  User receives USDC (with accrued yield) on Spoke Chain A
```

## 7. Dual Bridge Strategy (LayerZero + Hyperlane)

```
User Request
     │
     ▼
┌─────────────────┐
│ CrossChainBridge│
│  - Determines   │
│    bridge to use│
└────┬────────────┘
     │
     ├─────────────────┬─────────────────┐
     │                 │                 │
     ▼                 ▼                 ▼
┌──────────┐    ┌──────────┐    ┌──────────┐
│LayerZero │    │Hyperlane │    │  Fallback│
│  Primary │    │ Secondary│    │  Logic   │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     │               │               │
     └───────────────┼───────────────┘
                     │
                     │ First successful
                     │ message wins
                     │
                     ▼
            ┌─────────────────┐
            │  Destination    │
            │  Chain          │
            └─────────────────┘
```
