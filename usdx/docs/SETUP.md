# USDX Protocol - Development Environment Setup

## Overview

This guide helps you set up the complete development environment for USDX protocol.

## Prerequisites

- **Node.js**: v20+ (recommend using nvm)
- **Foundry**: For smart contract development
- **pnpm**: For frontend package management (or npm)
- **PostgreSQL**: For backend (optional)
- **Git**: Version control

## Quick Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd usdx
```

### 2. Install Root Dependencies

```bash
npm install
```

### 3. Set Up Each Component

Follow the README in each directory:
- **[contracts/README.md](./contracts/README.md)** - Smart contracts setup
- **[frontend/README.md](./frontend/README.md)** - Frontend setup
- **[backend/README.md](./backend/README.md)** - Backend setup (optional)
- **[infrastructure/README.md](./infrastructure/README.md)** - Infrastructure setup

## Detailed Setup by Component

### Smart Contracts Setup

```bash
cd contracts

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install Node.js dependencies
npm install

# Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install LayerZero-Labs/layerzero-contracts
forge install hyperlane-xyz/hyperlane-monorepo

# Configure environment
cp .env.example .env
# Edit .env with your RPC URLs

# Test setup
forge test
npx hardhat test
forge test --fork-url $MAINNET_RPC_URL
```

### Frontend Setup

```bash
cd frontend

# Install dependencies
pnpm install  # or npm install

# Configure environment
cp .env.example .env.local
# Edit .env.local with contract addresses and RPC URLs

# Start development server
pnpm dev
```

Visit http://localhost:3000

### Backend Setup (Optional)

```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with database, RPC URLs, etc.

# Set up database
createdb usdx_indexer
npm run migrate

# Start development server
npm run dev
```

### Infrastructure Setup

See **[infrastructure/README.md](./infrastructure/README.md)** for detailed setup.

## Environment Variables

### Contracts (.env)

```env
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_key
```

### Frontend (.env.local)

```env
NEXT_PUBLIC_USDX_TOKEN_ADDRESS_ETHEREUM=0x...
NEXT_PUBLIC_RPC_URL_ETHEREUM=https://...
NEXT_PUBLIC_CHAIN_ID_ETHEREUM=1
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=...
```

### Backend (.env)

```env
DATABASE_URL=postgresql://user:password@localhost:5432/usdx_indexer
MAINNET_RPC_URL=https://...
PORT=3001
```

## Verification

### Verify Smart Contracts Setup

```bash
cd contracts
forge build                    # Should compile successfully
forge test                    # Should run tests
forge test --fork-url $MAINNET_RPC_URL  # Should fork mainnet
```

### Verify Frontend Setup

```bash
cd frontend
pnpm dev                      # Should start dev server
# Visit http://localhost:3000
# Should see Next.js welcome page
```

### Verify Backend Setup

```bash
cd backend
npm run dev                   # Should start server
# Visit http://localhost:3001
# Should see API running
```

## Common Issues

### Foundry Not Found

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Node Version Issues

```bash
# Use nvm to manage Node versions
nvm install 20
nvm use 20
```

### RPC URL Issues

- Get free RPC URLs from Alchemy or Infura
- Make sure RPC URLs are correct for each network
- Test RPC URLs with curl or web3 tools

### Contract Import Issues

```bash
# Update Foundry remappings
cd contracts
forge remappings > remappings.txt
```

## Next Steps

1. ✅ Complete setup for your component
2. ✅ Read agent-specific instructions: **[AGENT-INSTRUCTIONS.md](./AGENT-INSTRUCTIONS.md)**
3. ✅ Read task breakdown: **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)**
4. ⏳ Begin development

## Getting Help

- **Setup issues**: Check component-specific README
- **Architecture questions**: See `docs/02-architecture.md`
- **Implementation questions**: See `docs/22-detailed-task-breakdown.md`
- **Open questions**: See `docs/10-open-questions.md`
