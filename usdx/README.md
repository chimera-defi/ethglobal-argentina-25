# USDX Cross-Chain Stablecoin Protocol

## Quick Start

**New to the project?** 
1. **📄 Read [USDX-PROSPECTUS.md](./docs/USDX-PROSPECTUS.md)** - **Executive prospectus for VCs and engineers** (start here!)
2. Read **[AGENT-INSTRUCTIONS.md](./AGENT-INSTRUCTIONS.md)** - Agent-specific instructions
3. Read **[SETUP.md](./SETUP.md)** - Development environment setup
4. Read **[docs/HANDOFF-GUIDE.md](./docs/HANDOFF-GUIDE.md)** - Complete handoff guide

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
- Bridge Kit SDK

### Backend (Optional)
- Node.js + Express
- Bridge Kit SDK
- PostgreSQL (for indexing)

### Infrastructure
- The Graph (indexing)
- Tenderly (monitoring)
- OpenZeppelin Defender (security)

## Getting Help

- **Architecture questions**: See `docs/02-architecture.md`
- **Implementation questions**: See `docs/22-detailed-task-breakdown.md`
- **Protocol questions**: See `docs/RESEARCH-*.md` files
- **Open questions**: See `docs/10-open-questions.md`

## Status

**Current Phase**: Design Complete ✅ | Ready for Implementation

**Next Phase**: Phase 1 - Setup & Infrastructure (Week 1)
