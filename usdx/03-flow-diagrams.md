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

## 5. Yield Generation Flow

```
┌─────────────────┐
│  USDXVault      │
│  - Holds USDC   │
└────┬────────────┘
     │
     │ 1. Idle USDC detected
     │
     ▼
┌─────────────────┐
│ YieldStrategy   │
│  Manager        │
└────┬────────────┘
     │
     │ 2. Select optimal strategy
     │    (Aave, Compound, etc.)
     │
     ▼
┌─────────────────┐
│  Aave/Compound  │
│  - Deposit USDC │
│  - Receive aUSDC│
│    / cUSDC      │
└────┬────────────┘
     │
     │ 3. Yield accrues over time
     │
     ▼
┌─────────────────┐
│ YieldStrategy   │
│  - Tracks yield │
│  - Compounds    │
└────┬────────────┘
     │
     │ 4. User withdraws
     │
     ▼
┌─────────────────┐
│ YieldStrategy   │
│  - Redeems      │
│  - Returns USDC │
│    + yield      │
└────┬────────────┘
     │
     │ 5. USDC returned to vault
     │
     ▼
┌─────────────────┐
│  USDXVault      │
│  - Processes    │
│    withdrawal   │
└─────────────────┘
```

## 6. Complete User Journey

```
User Journey: Deposit USDC on Chain A, Mint USDX, Transfer to Chain B

Step 1: Deposit
  User → approve USDC → USDXVault (Chain A)
  USDXVault → receive USDC → mint USDX → transfer to user

Step 2: Cross-Chain Transfer
  User → transferCrossChain(amount, Chain B)
  USDXToken → burn USDX (Chain A)
  CrossChainBridge → send message via LayerZero/Hyperlane

Step 3: Receive on Destination
  Message arrives on Chain B
  CrossChainBridge → verify → mint USDX → transfer to user

Step 4: Use USDX on Chain B
  User can now use USDX on Chain B
  USDC collateral remains on Chain A (earning yield)

Step 5: Redeem (Optional)
  User → burn USDX (Chain B)
  CrossChainBridge → send message to Chain A
  USDXVault → release USDC collateral → transfer to user
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
