# USDX Protocol - Agent-Specific Instructions

This document provides specific instructions for different development agents working on the USDX protocol.

## 🤖 Smart Contracts Agent

### Your Mission
Develop, test, and deploy all smart contracts for the USDX protocol.

### Start Here
1. **Read**: **[docs/21-smart-contract-development-setup.md](./docs/21-smart-contract-development-setup.md)**
2. **Read**: **[docs/05-technical-specification.md](./docs/05-technical-specification.md)**
3. **Read**: **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Phase 2

### Setup Instructions

```bash
cd contracts

# 1. Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2. Install Hardhat dependencies
npm install

# 3. Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install LayerZero-Labs/layerzero-contracts
forge install hyperlane-xyz/hyperlane-monorepo

# 4. Configure environment
cp .env.example .env
# Edit .env with your RPC URLs

# 5. Test setup
forge test
npx hardhat test
forge test --fork-url $MAINNET_RPC_URL  # Test mainnet forking
```

### Your Tasks (Phase 2: Weeks 2-7)

**Week 2**:
- [ ] USDXToken.sol - ERC20 implementation
- [ ] USDXVault.sol - Core vault logic
- [ ] Unit tests (Foundry)
- [ ] Fork tests (Foundry)

**Week 3**:
- [ ] Research OVault contracts
- [ ] Research Yield Routes contracts
- [ ] Integrate OVault into USDXVault
- [ ] Integrate Yield Routes into USDXVault
- [ ] Test with real Yearn vault (fork tests)

**Week 4**:
- [ ] LayerZeroAdapter.sol - OApp implementation
- [ ] Test LayerZero integration
- [ ] HyperlaneAdapter.sol - Mailbox + ISM
- [ ] Test Hyperlane integration

**Week 5**:
- [ ] CrossChainBridge.sol - Bridge orchestration
- [ ] USDXSpokeMinter.sol - Spoke chain minting
- [ ] Integration tests

**Weeks 6-7**:
- [ ] Complete test coverage (90%+)
- [ ] Fuzz tests
- [ ] Invariant tests
- [ ] Gas optimization
- [ ] Security review preparation

### Key Commands

```bash
# Foundry
forge build                    # Compile
forge test                     # Run tests
forge test --fork-url $RPC    # Fork tests
forge test --gas-report        # Gas report
forge coverage                 # Coverage

# Hardhat
npx hardhat compile            # Compile
npx hardhat test               # Run tests
npx hardhat run script/deploy.ts --network sepolia
```

### Important Notes
- **Use Foundry for testing** (faster, better fuzzing)
- **Use Hardhat for deployment** (better scripts)
- **Always test with mainnet forks** before testnet
- **Target 90%+ test coverage**
- **Gas optimize all contracts**

### Resources
- **[Setup Guide](./docs/21-smart-contract-development-setup.md)**
- **[Task Breakdown](./docs/22-detailed-task-breakdown.md)** - Phase 2
- **[Technical Spec](./docs/05-technical-specification.md)**
- **[Architecture](./docs/02-architecture.md)**

---

## 🎨 Frontend Agent

### Your Mission
Build the frontend application for USDX protocol with all MVP features.

### Start Here
1. **Read**: **[docs/20-frontend-architecture.md](./docs/20-frontend-architecture.md)**
2. **Read**: **[docs/03-flow-diagrams.md](./docs/03-flow-diagrams.md)**
3. **Read**: **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Phase 4

### Setup Instructions

```bash
cd frontend

# 1. Install dependencies
pnpm install

# 2. Configure environment
cp .env.example .env.local
# Edit .env.local with contract addresses and RPC URLs

# 3. Start development server
pnpm dev
```

Visit http://localhost:3000

### Your Tasks (Phase 4: Weeks 8-14)

**Week 8**:
- [ ] Set up Next.js project
- [ ] Configure wagmi + RainbowKit
- [ ] Build WalletConnectButton component
- [ ] Build ChainSelector component
- [ ] Integrate Bridge Kit SDK

**Week 9**:
- [ ] Create useBridgeKit hook
- [ ] Build BridgeKitTransfer component
- [ ] Generate contract types
- [ ] Create contract hooks (wagmi)
- [ ] Build Dashboard component

**Week 10**:
- [ ] Build DepositFlow component
- [ ] Integrate Bridge Kit for USDC bridging
- [ ] Integrate USDXVault deposit
- [ ] Build MintFlow component
- [ ] Integrate USDXSpokeMinter

**Week 11**:
- [ ] Build TransferFlow component
- [ ] Integrate CrossChainBridge
- [ ] Handle LayerZero/Hyperlane messaging
- [ ] Build WithdrawalFlow component

**Week 12**:
- [ ] Build TransactionHistory component
- [ ] Add transaction filtering
- [ ] Add transaction status tracking
- [ ] UI/UX improvements

**Week 13**:
- [ ] Mobile responsiveness
- [ ] Error handling improvements
- [ ] Loading states
- [ ] User testing

**Week 14**:
- [ ] Component tests
- [ ] Integration tests
- [ ] Bug fixes
- [ ] Performance optimization

### Key Commands

```bash
pnpm dev              # Start dev server
pnpm build            # Build for production
pnpm lint             # Run ESLint
pnpm type-check       # TypeScript check
pnpm test             # Run tests
```

### Important Notes
- **Bridge Kit is SDK-only** - Build custom UI
- **No API key needed** for Bridge Kit
- **Use wagmi v2** for contract interactions
- **Use TanStack Query** for server state
- **Mobile-first** design approach

### Resources
- **[Architecture Guide](./docs/20-frontend-architecture.md)**
- **[Task Breakdown](./docs/22-detailed-task-breakdown.md)** - Phase 4
- **[Flow Diagrams](./docs/03-flow-diagrams.md)**
- **[Bridge Kit Guide](./docs/RESEARCH-bridge-kit.md)**

---

## ⚙️ Backend Agent

### Your Mission
Set up backend services for transaction indexing, API, and monitoring (optional for MVP).

### Start Here
1. **Read**: **[docs/02-architecture.md](./docs/02-architecture.md)** - Layer 4
2. **Read**: **[docs/RESEARCH-bridge-kit.md](./docs/RESEARCH-bridge-kit.md)**
3. **Read**: **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Backend tasks

### Setup Instructions

```bash
cd backend

# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env with database, RPC URLs, etc.

# 3. Set up database (PostgreSQL)
createdb usdx_indexer
npm run migrate

# 4. Start development server
npm run dev
```

### Your Tasks

**Phase 1: Indexer Setup**
- [ ] Decide on indexing approach (The Graph vs custom)
- [ ] Set up The Graph subgraph OR custom indexer
- [ ] Index core events (deposit, mint, transfer, withdraw)
- [ ] Test indexing on testnet

**Phase 2: API Service**
- [ ] Set up Express.js API
- [ ] Create balance aggregation endpoint
- [ ] Create transaction history endpoint
- [ ] Create vault stats endpoint
- [ ] Add error handling

**Phase 3: Monitoring**
- [ ] Set up monitoring service
- [ ] Configure alerts
- [ ] Set up dashboards

### Important Notes
- **Backend is optional** for MVP - Bridge Kit can be frontend-only
- **The Graph recommended** for indexing (easier than custom)
- **Focus on API** for better UX (faster queries)
- **Monitoring is critical** for production

### Resources
- **[Architecture](./docs/02-architecture.md)**
- **[Bridge Kit Guide](./docs/RESEARCH-bridge-kit.md)**
- **[Task Breakdown](./docs/22-detailed-task-breakdown.md)**

---

## 🏗️ Infrastructure Agent

### Your Mission
Set up monitoring, deployment automation, indexing infrastructure, and CI/CD.

### Start Here
1. **Read**: **[docs/02-architecture.md](./docs/02-architecture.md)** - Infrastructure
2. **Read**: **[docs/06-implementation-plan.md](./docs/06-implementation-plan.md)** - Deployment phases
3. **Read**: **[docs/22-detailed-task-breakdown.md](./docs/22-detailed-task-breakdown.md)** - Infrastructure tasks

### Setup Instructions

```bash
cd infrastructure

# 1. Set up Tenderly
# - Create account at tenderly.co
# - Add project
# - Configure alerts

# 2. Set up OpenZeppelin Defender
# - Create account at defender.openzeppelin.com
# - Set up monitoring
# - Configure alerts

# 3. Set up The Graph (if using)
# - Create subgraph
# - Deploy to The Graph Network
```

### Your Tasks

**Phase 1: Monitoring Setup**
- [ ] Set up Tenderly
  - [ ] Add contracts
  - [ ] Configure alerts
  - [ ] Set up dashboards
- [ ] Set up OpenZeppelin Defender
  - [ ] Configure monitoring
  - [ ] Set up alerts
  - [ ] Configure admin operations

**Phase 2: Indexing Setup**
- [ ] Create The Graph subgraph
  - [ ] Define schema
  - [ ] Write mappings
  - [ ] Test locally
  - [ ] Deploy to testnet
- [ ] OR Set up custom indexer
  - [ ] Set up PostgreSQL
  - [ ] Write indexer service
  - [ ] Test indexing

**Phase 3: Deployment Automation**
- [ ] Set up deployment scripts
- [ ] Configure multi-chain deployment
- [ ] Set up contract verification
- [ ] Test deployments

**Phase 4: CI/CD**
- [ ] Set up GitHub Actions
- [ ] Configure test automation
- [ ] Configure deployment automation
- [ ] Set up security scanning

### Important Notes
- **Monitoring is critical** - Set up early
- **The Graph recommended** for indexing
- **Multi-chain deployment** requires careful configuration
- **CI/CD essential** for safe deployments

### Resources
- **[Architecture](./docs/02-architecture.md)**
- **[Implementation Plan](./docs/06-implementation-plan.md)**
- **[Task Breakdown](./docs/22-detailed-task-breakdown.md)**

---

## 📋 Common Tasks for All Agents

### Daily Workflow
1. **Check open questions**: `docs/10-open-questions.md`
2. **Update progress**: Update task breakdown
3. **Commit frequently**: Small, focused commits
4. **Test thoroughly**: Don't skip tests
5. **Document changes**: Update relevant docs

### Communication
- **Questions?** Check docs first, then ask
- **Blockers?** Document in open questions
- **Decisions needed?** Document in open questions
- **Progress updates**: Update task breakdown

### Best Practices
- **Read docs first**: Most answers are documented
- **Test locally**: Before pushing
- **Follow conventions**: Use existing patterns
- **Ask early**: Don't wait on blockers
- **Document decisions**: Update relevant docs

---

## 🚀 Quick Start Checklist

### Smart Contracts Agent
- [ ] Read setup guide
- [ ] Install Foundry + Hardhat
- [ ] Configure mainnet forking
- [ ] Start with USDXToken.sol

### Frontend Agent
- [ ] Read architecture guide
- [ ] Set up Next.js project
- [ ] Configure wagmi + RainbowKit
- [ ] Build wallet connection component

### Backend Agent
- [ ] Read architecture guide
- [ ] Decide on indexing approach
- [ ] Set up database/indexer
- [ ] Build API endpoints

### Infrastructure Agent
- [ ] Read architecture guide
- [ ] Set up monitoring (Tenderly + Defender)
- [ ] Set up indexing (The Graph or custom)
- [ ] Configure deployment automation

---

## 📚 Documentation Index

All documentation is in the `docs/` folder. See **[docs/README.md](./docs/README.md)** for complete index.

**Essential Reading**:
- `docs/HANDOFF-GUIDE.md` - Complete handoff guide
- `docs/22-detailed-task-breakdown.md` - Detailed tasks
- `docs/10-open-questions.md` - Open questions

**Agent-Specific**:
- Smart Contracts: `docs/21-smart-contract-development-setup.md`
- Frontend: `docs/20-frontend-architecture.md`
- Backend: `docs/02-architecture.md` (Layer 4)
- Infrastructure: `docs/02-architecture.md` (Infrastructure)

---

## 🆘 Getting Help

1. **Check documentation first** - Most answers are documented
2. **Check open questions** - `docs/10-open-questions.md`
3. **Review architecture** - `docs/02-architecture.md`
4. **Check task breakdown** - `docs/22-detailed-task-breakdown.md`
5. **Ask specific questions** - Document in open questions

---

## ✅ Success Criteria

### Smart Contracts Agent
- ✅ All contracts compile
- ✅ 90%+ test coverage
- ✅ Gas optimized
- ✅ Security review passed

### Frontend Agent
- ✅ All MVP features working
- ✅ Mobile responsive
- ✅ User testing passed
- ✅ Performance acceptable

### Backend Agent
- ✅ Indexer working
- ✅ API endpoints functional
- ✅ Monitoring set up
- ✅ Documentation complete

### Infrastructure Agent
- ✅ Monitoring configured
- ✅ Deployment automated
- ✅ CI/CD working
- ✅ Documentation complete

---

**Remember**: Read the docs, follow the task breakdown, test thoroughly, and communicate early!
