# USDX Cross-Chain Stablecoin Protocol

**A decentralized stablecoin with unified yield generation across multiple chains**

[![Tests](https://img.shields.io/badge/tests-108%2F108%20passing-brightgreen)]() [![Layer Zero](https://img.shields.io/badge/LayerZero-OVault%20Integrated-blue)]() [![Status](https://img.shields.io/badge/status-Ready%20for%20Testnet-green)]()

## 🎯 What is USDX?

USDX is a yield-bearing stablecoin that uses **LayerZero OVault** for cross-chain yield vault integration with a **hub-and-spoke architecture**:

- 💰 **Single Collateral Source** - All USDC on Ethereum (hub chain)
- 📈 **Unified Yield Generation** - Single Yearn USDC vault for all chains
- 🌐 **Multi-Chain Minting** - Mint USDX on any supported chain
- 🔗 **Decentralized Cross-Chain** - LayerZero for all cross-chain operations
- 🔒 **1:1 USDC Backing** - Every USDX backed by USDC in Yearn vault

## 🚀 Quick Start

**New to the project?** 
1. **📄 Read [docs/REVIEW-SUMMARY.md](./docs/REVIEW-SUMMARY.md)** - **Latest status & overview** (start here!)
2. **🏗️ Read [docs/USDX-PROSPECTUS.md](./docs/USDX-PROSPECTUS.md)** - Executive prospectus for VCs and engineers
3. **📚 Read [docs/layerzero/CURRENT-STATUS.md](./docs/layerzero/CURRENT-STATUS.md)** - Layer Zero implementation status
4. **⚙️ Read [SETUP.md](./SETUP.md)** - Development environment setup

## 🏗️ Layer Zero Integration Architecture

USDX uses **LayerZero OVault** to create a seamless cross-chain yield vault with hub-and-spoke topology:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     USDX PROTOCOL ARCHITECTURE                      │
│                    Hub-and-Spoke with LayerZero                     │
└─────────────────────────────────────────────────────────────────────┘

                        HUB CHAIN (ETHEREUM)
    ┌──────────────────────────────────────────────────────────────┐
    │                                                              │
    │  ┌─────────────────────────────────────────────────────┐   │
    │  │         COLLATERAL & YIELD GENERATION               │   │
    │  │                                                      │   │
    │  │  User USDC → USDXVault                              │   │
    │  │                ↓                                     │   │
    │  │         USDXYearnVaultWrapper (ERC-4626)            │   │
    │  │                ↓                                     │   │
    │  │         Yearn USDC Vault (Yield Source)             │   │
    │  │                ↓                                     │   │
    │  │         Yield Accrues Automatically 📈              │   │
    │  └─────────────────────────────────────────────────────┘   │
    │                                                              │
    │  ┌─────────────────────────────────────────────────────┐   │
    │  │      LAYERZERO OVAULT COMPONENTS (Hub)              │   │
    │  │                                                      │   │
    │  │  USDXShareOFTAdapter                                │   │
    │  │  ├─ Lockbox model for vault shares                  │   │
    │  │  ├─ Locks shares, mints OFT tokens                  │   │
    │  │  └─ Cross-chain via LayerZero                       │   │
    │  │                                                      │   │
    │  │  USDXVaultComposerSync                              │   │
    │  │  ├─ Orchestrates cross-chain operations             │   │
    │  │  ├─ deposit(): Assets → Shares → Send cross-chain   │   │
    │  │  └─ redeem(): Shares → Assets → Send cross-chain    │   │
    │  │                                                      │   │
    │  │  USDXToken (OFT)                                    │   │
    │  │  └─ USDX with LayerZero cross-chain transfers       │   │
    │  └─────────────────────────────────────────────────────┘   │
    │                                                              │
    └──────────────────────────────────────────────────────────────┘
                                  │
                                  │ LayerZero
                                  │ Messages
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
         ▼                        ▼                        ▼

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  SPOKE: POLYGON │    │ SPOKE: ARBITRUM │    │ SPOKE: OPTIMISM │
└─────────────────┘    └─────────────────┘    └─────────────────┘
│                      │                      │                  │
│ USDXShareOFT         │ USDXShareOFT         │ USDXShareOFT     │
│ ├─ Represents        │ ├─ Represents        │ ├─ Represents    │
│ │  hub shares        │ │  hub shares        │ │  hub shares    │
│ └─ Received via LZ   │ └─ Received via LZ   │ └─ Received via LZ│
│                      │                      │                  │
│ USDXSpokeMinter      │ USDXSpokeMinter      │ USDXSpokeMinter  │
│ ├─ Verifies shares   │ ├─ Verifies shares   │ ├─ Verifies shares│
│ ├─ Burns shares      │ ├─ Burns shares      │ ├─ Burns shares  │
│ └─ Mints USDX 💵     │ └─ Mints USDX 💵     │ └─ Mints USDX 💵 │
│                      │                      │                  │
│ USDXToken (OFT)      │ USDXToken (OFT)      │ USDXToken (OFT)  │
│ └─ Cross-chain via LZ│ └─ Cross-chain via LZ│ └─ Cross-chain via LZ│
│                      │                      │                  │
└─────────────────────┘ └─────────────────────┘ └─────────────────┘

═══════════════════════════════════════════════════════════════════

                         KEY COMPONENTS

LayerZero OVault Integration:
├─ Asset OFT Mesh: USDC (via Bridge Kit/CCTP)
├─ Share OFT Mesh: Hub (Adapter) + Spokes (OFT)
├─ ERC-4626 Vault: USDXYearnVaultWrapper
├─ Composer: USDXVaultComposerSync
└─ Cross-Chain Messaging: LayerZero endpoints

Hub-and-Spoke Model:
├─ Hub (Ethereum): All collateral + yield
├─ Spokes (L2s): USDX minting only
└─ No vault or yield logic on spokes ✓

Security:
├─ LayerZero DVNs (Decentralized Verifier Network)
├─ Trusted remote verification
├─ ERC-4626 standard compliance
└─ 108/108 tests passing ✅
```

## 📊 Implementation Status

- ✅ **All Core Contracts Implemented** (5 OVault contracts + integrations)
- ✅ **Tests Passing** - 108/108 (100% success rate)
- ✅ **Architecture Verified** - Matches LayerZero OVault spec
- ✅ **Hub-and-Spoke** - Correctly implemented
- ✅ **Token Naming** - "USDX" consistent across all chains
- 🚀 **Next Step** - Deploy to testnets

See **[docs/REVIEW-SUMMARY.md](./docs/REVIEW-SUMMARY.md)** for complete verification details.

## 🔧 Layer Zero Components Used

### Hub Chain (Ethereum)
```
✅ USDXYearnVaultWrapper.sol     - ERC-4626 wrapper for Yearn vault
✅ USDXShareOFTAdapter.sol       - Share OFTAdapter (lockbox model)
✅ USDXVaultComposerSync.sol     - Cross-chain orchestrator
✅ USDXVault.sol                 - Main vault contract
✅ USDXToken.sol                 - USDX with LayerZero OFT
```

### Spoke Chains (Polygon, Arbitrum, Optimism, Base, etc.)
```
✅ USDXShareOFT.sol              - Share OFT representation
✅ USDXSpokeMinter.sol           - Mints USDX using hub shares
✅ USDXToken.sol                 - USDX with LayerZero OFT
```

### Integration Points
```
✅ LayerZero V2 - Cross-chain messaging
✅ OVault Standard - Omnichain vault integration
✅ ERC-4626 - Tokenized vault standard
✅ Bridge Kit/CCTP - USDC transfers (Spoke ↔ Hub)
✅ Yearn Finance - Yield generation
```

## 📂 Project Structure

```
usdx/
├── docs/                    # All documentation
│   ├── REVIEW-SUMMARY.md                    # ⭐ Latest review (start here!)
│   ├── LAYERZERO-ARCHITECTURE-REVIEW.md     # Complete technical review
│   └── layerzero/                           # Layer Zero documentation
│       ├── CURRENT-STATUS.md                # Current status & next steps
│       ├── README.md                        # Layer Zero docs index
│       └── [reference docs & examples]
├── contracts/               # Smart contracts (Foundry + Hardhat)
│   ├── contracts/          # Contract implementations
│   │   ├── USDXVault.sol
│   │   ├── USDXToken.sol
│   │   ├── USDXYearnVaultWrapper.sol
│   │   ├── USDXShareOFTAdapter.sol
│   │   ├── USDXVaultComposerSync.sol
│   │   ├── USDXShareOFT.sol
│   │   └── USDXSpokeMinter.sol
│   └── test/forge/         # Tests (108/108 passing ✅)
├── frontend/                # Next.js frontend application
├── backend/                 # Backend services (optional)
├── infrastructure/          # Infrastructure as code, monitoring
└── README.md               # This file
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

## 🛠️ Technology Stack

### Smart Contracts
- **Foundry** (primary) + **Hardhat** (secondary)
- **Solidity** ^0.8.23
- **OpenZeppelin Contracts** v5.0+
- **LayerZero V2** - Cross-chain messaging
- **ERC-4626** - Tokenized vault standard

### Cross-Chain Infrastructure
- **LayerZero OVault** - Omnichain vault integration
- **LayerZero OFT** - Omnichain fungible token standard
- **Bridge Kit/CCTP** - USDC transfers (Circle's Cross-Chain Transfer Protocol)
- **Yearn Finance** - Yield generation

### Frontend
- **Next.js 14+** (App Router)
- **TypeScript**
- **wagmi v2** + **viem**
- **RainbowKit** - Wallet connection
- **Bridge Kit SDK** - USDC bridging

### Backend (Optional)
- **Node.js** + **Express**
- **Bridge Kit SDK**
- **PostgreSQL** (for indexing)

### Infrastructure
- **The Graph** (indexing)
- **Tenderly** (monitoring)
- **OpenZeppelin Defender** (security)
- **LayerZero Scan** (cross-chain message tracking)

## Getting Help

- **Architecture questions**: See `docs/02-architecture.md`
- **Implementation questions**: See `docs/22-detailed-task-breakdown.md`
- **Protocol questions**: See `docs/RESEARCH-*.md` files
- **Open questions**: See `docs/10-open-questions.md`

## 📈 Current Status

**Implementation:** ✅ Complete  
**Testing:** ✅ 108/108 tests passing (100%)  
**Architecture:** ✅ Verified and sound  
**Documentation:** ✅ Complete and current  
**Next Step:** 🚀 Ready for Testnet Deployment

### Recent Achievements (2025-11-23)
- ✅ Layer Zero OVault integration complete
- ✅ Hub-and-spoke architecture verified
- ✅ All core contracts implemented
- ✅ Comprehensive testing complete
- ✅ Documentation consolidated and updated
- ✅ Zero architectural divergences found
- ✅ Token naming consistent across chains

## 🧪 Testing

Run all tests:
```bash
cd contracts
forge test
```

**Test Results:** 108/108 passing ✅

Test breakdown:
- Integration E2E: 3/3 ✅
- Integration OVault: 3/3 ✅  
- Unit Tests: 102/102 ✅

## 🚀 Next Steps

### Immediate (Ready Now)
1. Deploy to Ethereum Sepolia (hub)
2. Deploy to Polygon Mumbai, Arbitrum Sepolia (spokes)
3. Configure LayerZero endpoints and trusted remotes
4. Test with real LayerZero infrastructure

### Before Mainnet
1. Security audit (focus on LayerZero integration)
2. Replace simplified LayerZero contracts with official SDK
3. Set up monitoring and alerting
4. Configure production DVNs and executors

See **[docs/layerzero/CURRENT-STATUS.md](./docs/layerzero/CURRENT-STATUS.md)** for detailed deployment guide.

## 📚 Documentation

### Essential Reading
- **[docs/REVIEW-SUMMARY.md](./docs/REVIEW-SUMMARY.md)** - Latest review & status
- **[docs/layerzero/CURRENT-STATUS.md](./docs/layerzero/CURRENT-STATUS.md)** - Layer Zero status
- **[docs/LAYERZERO-ARCHITECTURE-REVIEW.md](./docs/LAYERZERO-ARCHITECTURE-REVIEW.md)** - Technical review

### Complete Documentation
All documentation is in the `docs/` folder. See **[docs/README.md](./docs/README.md)** for complete documentation index.

### Layer Zero Specific
- **[docs/layerzero/README.md](./docs/layerzero/README.md)** - Layer Zero documentation index
- **[docs/layerzero/25-layerzero-ovault-comprehensive-understanding.md](./docs/layerzero/25-layerzero-ovault-comprehensive-understanding.md)** - OVault guide
- **[docs/layerzero/29-layerzero-ovault-examples.md](./docs/layerzero/29-layerzero-ovault-examples.md)** - Code examples
