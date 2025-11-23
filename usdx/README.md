# USDX Cross-Chain Stablecoin Protocol

> A yield-bearing, cross-chain USDC stablecoin with hub-and-spoke architecture

## Quick Start

**New to the project?** 
1. **📄 Read [USDX-PROSPECTUS.md](./usdx/docs/USDX-PROSPECTUS.md)** - Executive prospectus for VCs and engineers (start here!)
2. Read **[SETUP.md](./usdx/SETUP.md)** - Development environment setup
3. Read **[docs/HANDOFF-GUIDE.md](./usdx/docs/HANDOFF-GUIDE.md)** - Complete handoff guide
4. Read **[docs/BRIDGE-KIT-GUIDE.md](./usdx/docs/BRIDGE-KIT-GUIDE.md)** - Circle Bridge Kit integration guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         USDX Protocol Architecture                          │
└─────────────────────────────────────────────────────────────────────────────┘

                                  HUB CHAIN
                              (Ethereum Mainnet)
                    ┌──────────────────────────────────┐
                    │                                  │
                    │         USDXVault                │
                    │    ┌──────────────────┐         │
                    │    │  USDC Deposits   │         │
                    │    │  (Native USDC)   │         │
                    │    └────────┬─────────┘         │
                    │             │                    │
                    │    ┌────────▼─────────┐         │
                    │    │  Hyperlane ISM   │         │
                    │    │  (Proof Verify)  │         │
                    │    └────────┬─────────┘         │
                    │             │                    │
                    │    ┌────────▼─────────┐         │
                    │    │  LayerZero DVN   │         │
                    │    │  (Cross Verify)  │         │
                    │    └────────┬─────────┘         │
                    │             │                    │
                    │    ┌────────▼─────────┐         │
                    │    │  Yield Strategy  │         │
                    │    │  (Morpho/Aave)   │         │
                    │    └──────────────────┘         │
                    │                                  │
                    └──────────┬──────────┬───────────┘
                               │          │
              ┌────────────────┘          └────────────────┐
              │                                            │
    ┌─────────▼─────────┐                    ┌───────────▼──────────┐
    │   SPOKE CHAIN 1   │                    │   SPOKE CHAIN 2      │
    │   (Base)          │                    │   (Arbitrum)         │
    ├───────────────────┤                    ├──────────────────────┤
    │                   │                    │                      │
    │ USDXSpokeMinter   │                    │  USDXSpokeMinter     │
    │  ┌─────────────┐  │                    │   ┌─────────────┐   │
    │  │  Mint USDX  │  │                    │   │  Mint USDX  │   │
    │  │  (Based on  │  │                    │   │  (Based on  │   │
    │  │   Hub PoS)  │  │                    │   │   Hub PoS)  │   │
    │  └──────┬──────┘  │                    │   └──────┬──────┘   │
    │         │         │                    │          │          │
    │  ┌──────▼──────┐  │                    │   ┌──────▼──────┐   │
    │  │   USDX      │  │                    │   │   USDX      │   │
    │  │   Token     │  │                    │   │   Token     │   │
    │  │  (ERC20)    │  │                    │   │  (ERC20)    │   │
    │  └─────────────┘  │                    │   └─────────────┘   │
    │                   │                    │                      │
    └───────────────────┘                    └──────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                           CROSS-CHAIN MESSAGING

    Hub ←→ Spokes:  Hyperlane (ISM) + LayerZero (DVN) - Dual Verification
    
    USDC Bridging:  Circle Bridge Kit (CCTP) - Native USDC transfers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                              USER FLOWS

  ┌──────────────────┐         ┌──────────────────┐
  │   DEPOSIT FLOW   │         │  WITHDRAW FLOW   │
  └──────────────────┘         └──────────────────┘
  
  1. User on Spoke          1. User burns USDX
  2. Bridge USDC → Hub      2. Hub validates burn
  3. Deposit to Vault       3. Withdraw from Vault
  4. Mint USDX on Spoke     4. Bridge USDC → Spoke

  ┌──────────────────┐         ┌──────────────────┐
  │  TRANSFER FLOW   │         │   YIELD FLOW     │
  └──────────────────┘         └──────────────────┘
  
  1. Burn on Source         1. Vault deposits USDC
  2. Message to Hub         2. Yield accrues
  3. Verify via Hyper+LZ    3. Position updates
  4. Mint on Destination    4. Pro-rata distribution
```

## Key Features

- ✅ **Yield-Bearing:** USDC deposits generate yield through Morpho/Aave
- ✅ **Cross-Chain:** Native USDX on multiple chains (Base, Arbitrum, Optimism, etc.)
- ✅ **Secure:** Dual verification via Hyperlane ISM + LayerZero DVN
- ✅ **Native USDC:** Circle Bridge Kit (CCTP) for seamless USDC bridging
- ✅ **Hub-and-Spoke:** Centralized collateral on Ethereum, distributed tokens on spokes
- ✅ **Scalable:** Add new spoke chains without hub redeployment

## Project Structure

```
usdx/
├── docs/                    # All documentation
├── contracts/               # Smart contracts (Foundry + Hardhat)
├── frontend/                # Next.js frontend application
├── backend/                 # Backend services (optional)
├── infrastructure/           # Infrastructure as code, monitoring
└── README.md                # This file
```

## Agent-Specific Instructions

### 🤖 For Smart Contracts Agent

**Start Here**: **[docs/21-smart-contract-development-setup.md](./docs/21-smart-contract-development-setup.md)**

**Quick Setup**:
```bash
cd contracts
foundryup  # Install Foundry
npm install  # Install Hardhat dependencies
cp .env.example .env  # Configure environment
```

**Key Documents**:
- **[docs/21-smart-contract-development-setup.md](./docs/21-smart-contract-development-setup.md)** - Complete setup guide
- **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Phase 2 tasks
- **[docs/05-technical-specification.md](./docs/05-technical-specification.md)** - Contract interfaces

**First Tasks**:
1. Set up Foundry + Hardhat
2. Configure mainnet forking
3. Start with USDXToken.sol (Week 2)

### 🎨 For Frontend Agent

**Start Here**: **[docs/20-frontend-architecture.md](./docs/20-frontend-architecture.md)**

**Quick Setup**:
```bash
cd frontend
pnpm install  # Install dependencies
cp .env.example .env.local  # Configure environment
pnpm dev  # Start development server
```

**Key Documents**:
- **[docs/20-frontend-architecture.md](./docs/20-frontend-architecture.md)** - Complete architecture & MVP features
- **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Phase 4 tasks
- **[docs/03-flow-diagrams.md](./docs/03-flow-diagrams.md)** - User flows

**First Tasks**:
1. Set up Next.js project
2. Configure wagmi + RainbowKit
3. Build wallet connection component

### ⚙️ For Backend Agent

**Start Here**: **[docs/02-architecture.md](./docs/02-architecture.md)** (Layer 4: Infrastructure Services)

**Quick Setup**:
```bash
cd backend
npm install  # Install dependencies
cp .env.example .env  # Configure environment
npm run dev  # Start development server
```

**Key Documents**:
- **[docs/RESEARCH-bridge-kit.md](./docs/RESEARCH-bridge-kit.md)** - Bridge Kit backend integration
- **[docs/02-architecture.md](./docs/02-architecture.md)** - System architecture
- **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Backend tasks

**First Tasks**:
1. Set up Node.js/Express service
2. Integrate Bridge Kit SDK (optional - can be frontend-only)
3. Set up transaction indexing

### 🏗️ For Infrastructure Agent

**Start Here**: **[docs/02-architecture.md](./docs/02-architecture.md)** (Infrastructure section)

**Quick Setup**:
```bash
cd infrastructure
# Set up monitoring, indexing, deployment configs
```

**Key Documents**:
- **[docs/02-architecture.md](./docs/02-architecture.md)** - Infrastructure requirements
- **[docs/06-implementation-plan.md](./docs/06-implementation-plan.md)** - Deployment phases
- **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Infrastructure tasks

**First Tasks**:
1. Set up monitoring (Tenderly, OpenZeppelin Defender)
2. Configure indexer (The Graph or custom)
3. Set up CI/CD pipelines

## Documentation

All documentation is in the `docs/` folder. See **[docs/README.md](./docs/README.md)** for complete documentation index.

## Development Workflow

1. **Read agent-specific instructions** above
2. **Set up development environment** (see setup guides)
3. **Follow task breakdown** in `docs/22-detailed-task-breakdown.md`
4. **Check open questions** in `docs/10-open-questions.md`

## Technology Stack

### Smart Contracts
- Foundry (primary) + Hardhat (secondary)
- Solidity ^0.8.20
- OpenZeppelin Contracts

### Frontend
- Next.js 14+ (App Router)
- TypeScript
- wagmi v2 + viem
- RainbowKit
- Circle Bridge Kit SDK (`@circle-fin/bridge-kit@1.1.2`)

### Backend (Optional)
- Node.js + Express
- Bridge Kit SDK
- PostgreSQL (for indexing)

### Infrastructure
- The Graph (indexing)
- Tenderly (monitoring)
- OpenZeppelin Defender (security)

## Getting Help

- **Architecture questions**: See `usdx/docs/02-architecture.md`
- **Implementation questions**: See `usdx/docs/22-detailed-task-breakdown.md`
- **Bridge Kit integration**: See `usdx/docs/BRIDGE-KIT-GUIDE.md`
- **Protocol questions**: See `usdx/docs/RESEARCH-*.md` files
- **Open questions**: See `usdx/docs/10-open-questions.md`

## Status

**Current Phase**: Design Complete ✅ | Ready for Implementation

**Next Phase**: Phase 1 - Setup & Infrastructure (Week 1)
