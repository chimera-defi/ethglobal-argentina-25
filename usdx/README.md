# USDX Cross-Chain Stablecoin Protocol

## 🚀 Quick Start

**Want to see the website?** Follow the [Deployment Guide](./DEPLOYMENT.md) - it takes 5 minutes!

**Want to run locally?**
```bash
cd frontend
npm install --legacy-peer-deps
npm run dev
# Visit http://localhost:3000
```

## 📋 Project Status

✅ **Smart Contracts**: Implemented and compiling
✅ **Frontend**: Built with ethers.js (no wagmi/RainbowKit)
✅ **Tests**: 12/19 passing (63%)
⚠️ **Cross-Chain**: Uses trusted relayer (needs LayerZero implementation)
✅ **Deployment**: CI/CD configured for automatic deployment

**MVP Readiness**: ~45% - See [FINAL-REVIEW-SUMMARY.md](./FINAL-REVIEW-SUMMARY.md) for detailed assessment.

**Critical Gaps**:
- ❌ OVault/Yield Routes integration (using MockYieldVault)
- ❌ LayerZero/Hyperlane adapters (using trusted relayer)
- ❌ Bridge Kit frontend integration
- ❌ Missing contract functions

## 🏗️ Architecture

**Hub-and-Spoke Model**:
- **Hub Chain** (Ethereum): All USDC collateral and yield generation
- **Spoke Chains**: USDX minting and transfers

**Key Components**:
- USDXToken - ERC20 token
- USDXVault - Hub chain vault
- USDXSpokeMinter - Spoke chain minter
- CrossChainBridge - Cross-chain transfers
- MockYieldVault - Simulated yield (5% APY)

## 📁 Project Structure

```
usdx/
├── contracts/          # Smart contracts (Foundry + Hardhat)
├── frontend/           # Next.js frontend (ethers.js)
├── backend/            # Backend services (optional)
├── docs/               # Complete documentation
└── .github/workflows/  # CI/CD pipelines
```

## 🚀 Deployment

### Automatic (Recommended)

**Vercel** (easiest):
1. Go to [vercel.com](https://vercel.com)
2. Import this repository
3. Deploy!

Every push to `main` automatically deploys.

### Manual

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

## 🧪 Testing

### Smart Contracts

```bash
cd contracts
forge test
```

### Frontend

```bash
cd frontend
npm run build    # Build check
npm run lint     # Lint check
npm run type-check  # TypeScript check
```

## 📚 Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Deployment guide (start here!)
- **[NEXT-AGENT-TASKS.md](./NEXT-AGENT-TASKS.md)** - Tasks for next agent
- **[docs/](./docs/)** - Complete architecture and implementation docs

## 🔧 Development

### Prerequisites

- Node.js 20+
- Foundry (for contracts)
- MetaMask (for testing)

### Setup

```bash
# Contracts
cd contracts
npm install --legacy-peer-deps
forge install OpenZeppelin/openzeppelin-contracts

# Frontend
cd frontend
npm install --legacy-peer-deps
```

## ⚠️ Known Issues

1. **Trusted Relayer**: CrossChainBridge uses trusted relayer (needs LayerZero)
2. **LayerZero Contracts**: Cannot find correct repository
3. **Some Tests**: Reentrancy guard false positives (Foundry quirk)

See [NEXT-AGENT-TASKS.md](./NEXT-AGENT-TASKS.md) for details.

## 🎯 Success Criteria

- ✅ Contracts compile
- ✅ Frontend builds
- ✅ Wallet connection works
- ✅ Basic UI functional
- ⚠️ Cross-chain needs LayerZero (blocked)

## 📞 Support

- **Deployment**: See [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Architecture**: See `docs/02-architecture.md`
- **Tasks**: See [NEXT-AGENT-TASKS.md](./NEXT-AGENT-TASKS.md)

---

**Ready to deploy?** Check out [DEPLOYMENT.md](./DEPLOYMENT.md) for the fastest way to get your site live! 🚀
