# USDX Protocol - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Choose Your Role

Read **[AGENT-INSTRUCTIONS.md](./AGENT-INSTRUCTIONS.md)** to find your role-specific instructions.

### Step 2: Set Up Your Environment

Follow **[SETUP.md](./SETUP.md)** for complete setup instructions.

### Step 3: Start Development

Follow **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** for detailed tasks.

## Quick Commands by Role

### 🤖 Smart Contracts Agent

```bash
cd contracts
foundryup && npm install
forge install OpenZeppelin/openzeppelin-contracts
cp .env.example .env
# Edit .env with RPC URLs
forge test
```

### 🎨 Frontend Agent

```bash
cd frontend
pnpm install
cp .env.example .env.local
# Edit .env.local with contract addresses
pnpm dev
```

### ⚙️ Backend Agent

```bash
cd backend
npm install
cp .env.example .env
createdb usdx_indexer
npm run migrate
npm run dev
```

### 🏗️ Infrastructure Agent

See **[infrastructure/README.md](./infrastructure/README.md)** for setup.

## Essential Documents

1. **[AGENT-INSTRUCTIONS.md](./AGENT-INSTRUCTIONS.md)** - Your role-specific guide
2. **[SETUP.md](./SETUP.md)** - Environment setup
3. **[docs/HANDOFF-GUIDE.md](./docs/HANDOFF-GUIDE.md)** - Complete handoff guide
4. **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Detailed tasks

## Project Structure

```
usdx/
├── docs/           # All documentation (29 files)
├── contracts/      # Smart contracts (Foundry + Hardhat)
├── frontend/       # Next.js frontend
├── backend/        # Backend services (optional)
└── infrastructure/ # Infrastructure configs
```

## Status

✅ **Documentation**: Complete
✅ **Project Structure**: Created
✅ **Configuration Files**: Ready
✅ **Environment Templates**: Ready
⏳ **Code**: Ready to be written

## Next Steps

1. Read your agent instructions
2. Set up your development environment
3. Start with Phase 1 tasks
4. Follow the task breakdown

**Let's build USDX! 🚀**
