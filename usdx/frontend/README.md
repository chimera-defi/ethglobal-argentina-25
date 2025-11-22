# USDX Frontend

## For Frontend Agent

**📖 Start Here**: **[../docs/20-frontend-architecture.md](../docs/20-frontend-architecture.md)**

## Quick Setup

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Configure Environment

```bash
cp .env.example .env.local
# Edit .env.local with contract addresses and RPC URLs
```

### 3. Start Development Server

```bash
pnpm dev
```

Visit http://localhost:3000

## Project Structure

```
frontend/
├── app/                      # Next.js App Router
│   ├── (dashboard)/
│   │   ├── page.tsx         # Dashboard
│   │   ├── deposit/
│   │   ├── mint/
│   │   ├── transfer/
│   │   ├── withdraw/
│   │   └── history/
│   └── api/                  # API routes
├── components/
│   ├── wallet/              # Wallet connection
│   ├── bridge/              # Bridge Kit components
│   ├── transactions/        # Transaction components
│   └── ui/                  # shadcn/ui components
├── hooks/
│   ├── useBridgeKit.ts     # Bridge Kit hook
│   ├── useBalances.ts       # Balance hooks
│   └── useContracts.ts      # Contract hooks
├── lib/
│   ├── wagmi.ts            # wagmi config
│   └── utils.ts            # Utilities
├── stores/                  # Zustand stores
└── types/                   # TypeScript types
```

## Technology Stack

- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS + shadcn/ui
- **Wallet**: wagmi v2 + viem
- **Wallet UI**: RainbowKit
- **State**: Zustand + TanStack Query
- **Bridge Kit**: @circle-fin/bridge-kit + @circle-fin/adapter-viem-v2

## MVP Features

### Core Features (Must Have)

1. ✅ **Wallet Connection & Chain Management**
   - Multi-wallet support
   - Chain selector
   - Network detection

2. ✅ **Dashboard / Balance Display**
   - Cross-chain balance aggregation
   - Per-chain balances
   - USDC balance
   - OVault/Yield Routes position

3. ✅ **Deposit Flow**
   - Select source chain
   - Enter USDC amount
   - Bridge USDC to hub (Bridge Kit)
   - Deposit into USDXVault
   - Receive position

4. ✅ **Mint USDX Flow**
   - Select destination chain
   - Verify hub position
   - Enter USDX amount
   - Mint USDX on spoke chain

5. ✅ **Cross-Chain Transfer Flow**
   - Select source/destination chains
   - Enter USDX amount
   - Burn on source chain
   - Transfer via LayerZero/Hyperlane
   - Mint on destination chain

6. ✅ **Withdrawal Flow**
   - Select withdrawal chain
   - Enter USDX amount
   - Withdraw from USDXVault
   - Bridge USDC back (Bridge Kit)

7. ✅ **Transaction History**
   - List all transactions
   - Filter by type/chain
   - Transaction status
   - Transaction details

## Development Workflow

### Week 8: Setup & Wallet

1. Set up Next.js project
2. Configure wagmi + RainbowKit
3. Build wallet connection components
4. Build chain selector

### Week 9: Bridge Kit & Contracts

1. Integrate Bridge Kit SDK
2. Build Bridge Kit UI components
3. Generate contract types
4. Create contract hooks

### Week 10-12: Core Features

1. Dashboard (balance display)
2. Deposit flow
3. Mint flow
4. Transfer flow
5. Withdrawal flow

### Week 12-13: Polish

1. Transaction history
2. UI/UX improvements
3. Mobile responsiveness
4. Error handling

### Week 14: Testing

1. Component tests
2. Integration tests
3. User testing
4. Bug fixes

## Key Commands

```bash
pnpm dev              # Start dev server
pnpm build            # Build for production
pnpm start            # Start production server
pnpm lint             # Run ESLint
pnpm type-check       # TypeScript type check
pnpm test             # Run tests
```

## Environment Variables

```env
# Contract Addresses
NEXT_PUBLIC_USDX_TOKEN_ADDRESS_ETHEREUM=0x...
NEXT_PUBLIC_USDX_TOKEN_ADDRESS_POLYGON=0x...
NEXT_PUBLIC_USDX_VAULT_ADDRESS_ETHEREUM=0x...

# RPC URLs
NEXT_PUBLIC_RPC_URL_ETHEREUM=https://...
NEXT_PUBLIC_RPC_URL_POLYGON=https://...

# Chain IDs
NEXT_PUBLIC_CHAIN_ID_ETHEREUM=1
NEXT_PUBLIC_CHAIN_ID_POLYGON=137
```

## Resources

- **[Architecture Guide](../docs/20-frontend-architecture.md)** - Complete architecture & MVP
- **[Task Breakdown](../docs/22-detailed-task-breakdown.md)** - Phase 4 detailed tasks
- **[Flow Diagrams](../docs/03-flow-diagrams.md)** - User flows
- **[Bridge Kit Guide](../docs/RESEARCH-bridge-kit.md)** - Bridge Kit integration

## Next Steps

1. ✅ Read architecture guide
2. ✅ Set up Next.js project
3. ✅ Install dependencies
4. ⏳ Configure wagmi + RainbowKit
5. ⏳ Build wallet connection component
