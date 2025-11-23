# USDX Protocol Demo - Quick Start

## For Investor Presentations 🎯

### One-Command Demo
```bash
cd /workspace/usdx/contracts && ./run-demo.sh
```

This will show:
- ✅ Deposit USDC on Ethereum
- ✅ Bridge to Polygon via LayerZero  
- ✅ Mint USDX stablecoin
- ✅ Use USDX (transfer)
- ✅ Burn and redeem with yield

**Demo Duration**: ~10 seconds
**Output**: Beautifully formatted terminal output with step-by-step logging

---

## Alternative Commands

### Direct Forge Test (Verbose)
```bash
forge test --match-test testCompleteE2EFlow -vv
```

### All Integration Tests
```bash
forge test --match-path "test/forge/Integration*.t.sol" -vv
```

### Super Verbose (Shows Traces)
```bash
forge test --match-test testCompleteE2EFlow -vvvv
```

---

## What Makes This Special

### 🌉 Cross-Chain Magic
- Seamless Ethereum ↔ Polygon bridging
- LayerZero omnichain messaging
- No centralized bridge risk

### 💰 Capital Efficient
- Deposit once on Ethereum
- Use stablecoin on any chain
- Yield continues accruing

### 🔒 Fully Collateralized
- 1:1 USDC backing
- Transparent on-chain verification
- Always redeemable

### 📊 Live Demonstration
The test shows REAL transactions:
- Before/after balances
- Cross-chain messages
- Yield generation
- Full capital recovery

---

## Reading the Output

```
[BEFORE]  → State before action
[ACTION]  → What's happening
[SUCCESS] → Operation completed
[AFTER]   → New state
[OK]      → Verification passed
```

Each phase clearly separated with visual dividers.

---

## Presentation Tips

### Opening (30 seconds)
"Let me show you our protocol working end-to-end across two chains..."

### During Demo (2 minutes)
- Phase 1: "User deposits USDC on Ethereum..."
- Phase 2: "We bridge the collateral to Polygon via LayerZero..."
- Phase 3: "User mints USDX stablecoin on Polygon..."
- Phase 4: "USDX is fully liquid - transferable like any token..."
- Phase 5-6: "User can burn and redeem anytime, getting capital back with yield..."

### Closing (30 seconds)
"As you can see, all tests passed. The protocol handles deposits, cross-chain transfers, minting, usage, and redemption - all working seamlessly."

---

## Technical Specs for Q&A

- **Smart Contracts**: 7 contracts tested
- **Chains**: Ethereum (hub) + Polygon (spoke)
- **Bridge**: LayerZero OFT standard
- **Collateral**: USDC → Yearn Vault
- **Stablecoin**: USDX (1:1 with USDC)
- **Test Framework**: Foundry (Forge)
- **Language**: Solidity 0.8.30

---

## Troubleshooting

**Forge not found?**
```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc && foundryup
```

**Test fails?**
```bash
forge install  # Install dependencies
forge clean    # Clean build cache
forge test --match-test testCompleteE2EFlow -vv
```

**Need help?**
- Full guide: `docs/integration-test-demo.md`
- Deployment: `contracts/DEPLOYMENT-GUIDE.md`
- Security: `contracts/SECURITY-REVIEW.md`

---

**Ready to impress?** Run `./run-demo.sh` and watch the magic happen! ✨
