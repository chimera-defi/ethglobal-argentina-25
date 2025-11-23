# USDX Cross-Chain Stablecoin Protocol

**A decentralized stablecoin with unified yield generation across multiple chains**

[![Layer Zero](https://img.shields.io/badge/LayerZero-OVault%20Integrated-blue)]() [![Status](https://img.shields.io/badge/status-Ready%20for%20Testnet-green)]()

## 🎬 Live Demo (For Investors & Presentations)

**Want to see the protocol in action? One command starts everything:**

```bash
./run-complete-demo.sh
```

**What it does**:
1. 🌐 Starts local Ethereum + Base chains
2. 📦 Deploys all smart contracts
3. 💰 Funds test wallets
4. 🔄 Runs complete E2E flow with verbose logging

**Shows**: Deposit → Cross-Chain Bridge → Mint USDX → Transfer → Burn → Redeem  
**Duration**: ~2 minutes | **[Full Demo Guide →](./DEMO-README.md)**

---

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
└─ ERC-4626 standard compliance
```

## 📊 Current Status

**Production-ready smart contracts** with complete LayerZero OVault integration. Ready for testnet deployment.

See **[docs/REVIEW-SUMMARY.md](./docs/REVIEW-SUMMARY.md)** for technical details.

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

## 🌉 Bridge Kit Integration

USDX uses **Circle Bridge Kit** (built on CCTP) for secure USDC cross-chain transfers between spoke chains and the hub chain. Bridge Kit enables users to bridge USDC before depositing into the vault.

### Bridge Kit Integration Flow

#### Frontend Integration (User-Initiated)

```
┌─────────┐
│  User   │
└────┬────┘
     │
     │ 1. User initiates deposit from Spoke Chain
     │    to Hub Chain vault via UI
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
│    on Spoke     │
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
                                    │    USDC minted on Hub
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  Hub Chain      │
                           │  (Ethereum)     │
                           └────┬────────────┘
                                │
                                │ 5. USDC arrives on Hub
                                │
                                ▼
                           ┌─────────────────┐
                           │  USDXVault      │
                           │  - Receives USDC│
                           │  - User deposits│
                           └─────────────────┘
```

### Complete User Journey: Spoke → Hub → Spoke

```
Step 1: Bridge USDC (Spoke → Hub)
  User on Spoke Chain → Bridge Kit SDK → USDC bridged to Hub Chain (Ethereum)
  USDC arrives on Hub Chain via CCTP

Step 2: Deposit into Vault (Hub Chain)
  User → depositUSDC(amount) → USDXVault (Hub Chain only)
  USDXVault → OVault → Yearn USDC Vault
  User receives OVault position on Hub Chain
  Yield starts accruing automatically in Yearn vault

Step 3: Mint USDX on Spoke Chain
  User → mintUSDXFromOVault(shares, hubChainId) → USDXSpokeMinter (Spoke Chain)
  USDXSpokeMinter → verifies position on Hub Chain via OVault
  USDXToken → mints USDX on Spoke Chain
  User now has USDX on Spoke Chain

Step 4: Use USDX on Spoke Chain
  User can use USDX on Spoke Chain
  USDC collateral remains in Yearn vault on Hub Chain (earning yield)

Step 5: Redeem (Spoke → Hub)
  User → burn USDX (Spoke Chain)
  User → withdrawUSDCFromOVault(amount) → USDXVault (Hub Chain)
  OVault → withdraws from Yearn → returns USDC
  User → Bridge Kit SDK → USDC bridged back to Spoke Chain
  User receives USDC (with accrued yield) on Spoke Chain
```

### Bridge Kit Implementation

**Files:**
- `/frontend/src/lib/bridgeKit.ts` - Core utilities and helper functions
- `/frontend/src/hooks/useBridgeKit.ts` - React hook for Bridge Kit
- `/frontend/src/components/BridgeKitFlow.tsx` - UI component for bridging

**Supported Chains:**
- **Testnets:** Ethereum Sepolia, Base Sepolia, Arbitrum Sepolia, Optimism Sepolia
- **Mainnets:** Ethereum, Base, Arbitrum, Optimism

See **[docs/BRIDGE-KIT-GUIDE.md](./docs/BRIDGE-KIT-GUIDE.md)** for complete Bridge Kit integration guide.

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
│   └── test/forge/         # Comprehensive test suite
├── frontend/                # Next.js frontend application
├── backend/                 # Backend services (optional)
├── infrastructure/          # Infrastructure as code, monitoring
└── README.md               # This file
```

## 🚀 For Developers

**Quick Setup:**
```bash
cd contracts
foundryup && npm install
cp .env.example .env
forge test  # Run tests
```

**Documentation:**
- **[docs/README.md](./docs/README.md)** - Complete documentation index
- **[SETUP.md](./SETUP.md)** - Development environment setup
- **[docs/layerzero/CURRENT-STATUS.md](./docs/layerzero/CURRENT-STATUS.md)** - Implementation guide

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

## 📖 Learn More

- **[docs/USDX-PROSPECTUS.md](./docs/USDX-PROSPECTUS.md)** - Executive prospectus
- **[docs/02-architecture.md](./docs/02-architecture.md)** - System architecture
- **[docs/README.md](./docs/README.md)** - Complete documentation

## 🚀 Getting Started

Ready to dive in? Check out our [documentation](./docs/README.md) or jump straight to the [deployment guide](./docs/layerzero/CURRENT-STATUS.md).

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
