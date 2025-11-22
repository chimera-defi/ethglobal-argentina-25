# USDX Flow Diagrams

## 1. Initial Deposit and Mint Flow

```
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. approve(USDC, USDXVault)
     │
     ▼
┌─────────────────┐
│  USDC Token     │
└─────────────────┘
     │
     │ 2. depositUSDC(amount)
     │
     ▼
┌─────────────────┐
│  USDXVault      │
│  - Receives USDC│
│  - Tracks balance│
└────┬────────────┘
     │
     │ 3. mintUSDX(amount, user)
     │
     ▼
┌─────────────────┐
│  USDXToken      │
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

     │
     │ 5. depositToYieldStrategy(USDC)
     │
     ▼
┌─────────────────┐
│ YieldStrategy   │
│  - Deposits USDC│
│    to Aave/Comp │
│  - Receives yield│
│    tokens       │
└─────────────────┘
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

## 5. OVault/Yield Routes Flow (Simplified Yield Generation)

### Deposit and Yield Accrual

```
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. User bridges USDC to source chain
     │    (via Bridge Kit)
     │
     ▼
┌─────────────────┐
│  USDXVault      │
│  (Source Chain) │
└────┬────────────┘
     │
     │ 2. depositUSDC(amount)
     │
     ▼
┌─────────────────┐
│  OVault /       │
│  Yield Routes   │
│  - Receives USDC│
│  - Tracks position│
└────┬────────────┘
     │
     │ 3. Deposits into Yearn
     │
     ▼
┌─────────────────┐
│  Yearn USDC     │
│  Vault          │
│  - Holds all USDC│
│  - Yield accrues│
│    automatically│
└────┬────────────┘
     │
     │ 4. Yield accrues continuously
     │
     ▼
┌─────────────────┐
│  OVault /       │
│  Yield Routes   │
│  - Position value│
│    increases    │
│  - Cross-chain  │
│    access ready │
└────┬────────────┘
     │
     │ 5. USDX minted to user
     │
     ▼
┌─────────────────┐
│  USDXToken      │
│  - Minted on    │
│    any chain    │
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

## 6. Complete User Journey (Updated with OVault/Yield Routes)

```
User Journey: Bridge USDC, Deposit into OVault/Yield Routes, Mint USDX on Any Chain

Step 1: Bridge USDC
  User → Bridge Kit SDK → USDC bridged (Chain A → Chain B)
  USDC arrives on Chain B (source chain, e.g., Ethereum)

Step 2: Deposit into OVault/Yield Routes
  User → depositUSDC(amount) → USDXVault (Chain B)
  USDXVault → OVault/Yield Routes → Yearn USDC Vault
  User receives OVault/Yield Routes position
  Yield starts accruing automatically in Yearn vault

Step 3: Mint USDX on Any Chain
  User → mintUSDXFromOVault(shares, Chain C) → USDXVault (Chain C)
  OVault/Yield Routes → verifies position → mints representative token
  USDXVault → mints USDX → transfers to user
  User now has USDX on Chain C

Step 4: Use USDX on Chain C
  User can use USDX on Chain C
  USDC collateral remains in Yearn vault on Chain B (earning yield)

Step 5: Cross-Chain USDX Transfer (Optional)
  User → transferCrossChain(amount, Chain D)
  USDXToken → burn USDX (Chain C)
  CrossChainBridge → send message via LayerZero/Hyperlane
  USDXToken → mint USDX (Chain D)

Step 6: Redeem (Optional)
  User → burn USDX (Chain D)
  User → withdrawUSDCFromOVault(amount) → USDXVault (Chain B)
  OVault/Yield Routes → withdraws from Yearn → returns USDC
  User receives USDC (with accrued yield)
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
