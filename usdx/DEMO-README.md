# USDX Protocol - Complete Demo Guide

## 🎯 Quick Start (Single Command)

```bash
./run-complete-demo.sh
```

This one command will:
1. 🌐 Start local blockchain networks (Ethereum + Base)
2. 📦 Deploy all USDX Protocol contracts
3. 💰 Fund test user wallets
4. 🔄 Run comprehensive E2E integration test
5. 📊 Display beautiful verbose output

**Duration**: ~2 minutes  
**Perfect for**: Investor presentations, live demos, technical reviews

---

## 🎬 Two Demo Options

### Option 1: Complete Demo (Recommended for Presentations)

**What it does**: Starts everything from scratch - chains, deployments, and tests

```bash
./run-complete-demo.sh
```

**What you'll see**:
- Multi-chain setup starting
- Smart contracts deploying
- Verbose E2E test execution showing:
  - Phase 1: Deposit USDC on Ethereum
  - Phase 2: Lock & bridge shares via LayerZero
  - Phase 3: Mint USDX on Base
  - Phase 4: Use USDX (transfer)
  - Phase 5: Burn USDX
  - Phase 6: Redeem for USDC with yield

**Use when**:
- Presenting to investors
- Live demonstrations
- Starting from clean slate
- Showing full system capabilities

---

### Option 2: Quick Test Only (If Chains Already Running)

**What it does**: Runs the verbose E2E test against mock contracts (no real chains needed)

```bash
cd contracts && ./run-demo.sh
```

Or directly:
```bash
cd contracts && forge test --match-test testCompleteE2EFlow -vv
```

**What you'll see**:
- Same beautiful verbose output
- All 6 phases of the user flow
- Complete test execution in ~10 seconds
- Uses Foundry's built-in mocks

**Use when**:
- Quick verification
- Development testing
- CI/CD pipelines
- No need for live chains

---

## 📋 What Each Demo Shows

### Phase 1: Deposit on Hub Chain (Ethereum)
```
[BEFORE] User USDC Balance: 10000 USDC
[ACTION] User deposits 1000 USDC into vault...
[SUCCESS] Deposit completed!
[AFTER] User USDX Balance: 1000 USDX
```
- User deposits USDC on Ethereum hub chain
- Receives USDX tokens 1:1
- Gets vault wrapper shares for yield

### Phase 2: Cross-Chain Bridge via LayerZero
```
[ACTION] User locks 1000 shares in OFT Adapter...
[SUCCESS] Shares locked!
[ACTION] Sending OFT tokens cross-chain to Base...
[SUCCESS] Message delivered on Base!
```
- Locks vault shares in OFT adapter
- Bridges to Base using LayerZero
- Shares available on destination chain

### Phase 3: Mint USDX on Spoke Chain (Base)
```
[ACTION] User mints 500 USDX using shares...
[SUCCESS] USDX minted on Base!
[AFTER] User USDX Balance on Base: 500 USDX
```
- Mints USDX on Base using shares as collateral
- Shares burned proportionally
- USDX ready for DeFi use on Base

### Phase 4: Use USDX
```
[ACTION] User transfers 250 USDX to recipient...
[SUCCESS] Transfer completed!
```
- Transfers USDX to another user
- Demonstrates full liquidity
- Shows real-world usability

### Phase 5: Burn USDX
```
[ACTION] User burns 250 USDX...
[SUCCESS] USDX burned!
```
- Burns USDX to exit position
- Frees up collateral
- Prepares for redemption

### Phase 6: Redeem and Withdraw
```
[ACTION] Sending shares back to Ethereum...
[ACTION] User redeems shares for USDC...
[SUCCESS] Redemption completed!
[RESULT] USDC Received: 500 USDC
```
- Bridges shares back to Ethereum
- Redeems for original USDC
- User recovers capital (potentially with yield)

---

## 🏗️ What Gets Deployed

### Hub Chain (Ethereum - Port 8545)
- **MockUSDC** - Test USDC token
- **MockYearnVault** - Simulated yield-bearing vault
- **USDXToken** - USDX stablecoin
- **USDXVault** - Main vault contract
- **USDXYearnVaultWrapper** - ERC4626 wrapper
- **USDXShareOFTAdapter** - Cross-chain adapter

### Spoke Chain (Base - Port 8546)
- **USDXToken** - USDX stablecoin on Base
- **USDXShareOFT** - OFT shares on Base
- **USDXSpokeMinter** - Minting contract

---

## 🔧 Manual Control

### Start Chains Only
```bash
./start-multi-chain.sh
```

### Stop All Chains
```bash
./stop-multi-chain.sh
```

### Check Chain Status
```bash
# Hub (Ethereum)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# Spoke (Base)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8546
```

### View Chain Logs
```bash
tail -f logs/anvil-hub.log    # Hub chain
tail -f logs/anvil-spoke.log  # Spoke chain
```

---

## 📊 Presentation Tips

### For Investors (Focus on Value)
```bash
./run-complete-demo.sh
```

**Talking Points**:
1. "Let me show you our protocol working end-to-end..."
2. "Notice how we start with USDC on Ethereum..."
3. "The vault shares get bridged seamlessly to Base..."
4. "User can mint USDX and use it immediately on Base..."
5. "Full capital recovery with potential yield..."

**Key Highlights**:
- Cross-chain capability = larger addressable market
- Capital efficiency = deposit once, use anywhere
- Yield-bearing = continuous value accrual
- Full liquidity = no capital lock-up

### For Technical Audiences (Focus on Architecture)
```bash
./run-complete-demo.sh
```

**Talking Points**:
1. "We use LayerZero's OFT standard for cross-chain..."
2. "The collateralization ratio is maintained through burns..."
3. "ERC4626 vault wrapper for yield integration..."
4. "Omnichain fungible tokens enable seamless bridging..."

**Key Highlights**:
- LayerZero integration for trustless messaging
- OFT standard for share tokenization
- ERC4626 for standardized vaults
- Proper access control and role management

### For Users (Focus on UX)
```bash
./run-complete-demo.sh
```

**Talking Points**:
1. "Simple 3-step process: Deposit → Mint → Use"
2. "Your USDC keeps earning yield while you use USDX"
3. "Transfer USDX anywhere, use in any DeFi protocol"
4. "Redeem anytime - get your capital back plus yield"

**Key Highlights**:
- Simple user flow
- Continuous yield generation
- Full liquidity
- Easy exit strategy

---

## 🐛 Troubleshooting

### "Anvil not found"
```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### "Port already in use"
```bash
./stop-multi-chain.sh
sleep 2
./run-complete-demo.sh
```

### "Deployment failed"
Check deployment logs:
```bash
cat logs/deploy-hub.log
cat logs/deploy-spoke-base.log
```

### "Test failed"
Run with extra verbosity:
```bash
cd contracts
forge test --match-test testCompleteE2EFlow -vvvv
```

### "RPC not responding"
Verify chains are running:
```bash
ps aux | grep anvil
lsof -i :8545
lsof -i :8546
```

---

## 📈 Advanced Usage

### Run Specific Test Phases
```bash
cd contracts

# Just the E2E flow
forge test --match-test testCompleteE2EFlow -vv

# Cross-chain transfer only
forge test --match-test testCrossChainUSDXTransfer -vv

# All integration tests
forge test --match-path "test/forge/Integration*.t.sol" -vv
```

### Custom RPC URLs
```bash
HUB_RPC_URL="..." SPOKE_BASE_RPC_URL="..." ./start-multi-chain.sh
```

### Disable Arc Chain
```bash
START_ARC=false ./run-complete-demo.sh
```

### Run Against Live Chains (with deployed contracts)
```bash
cd contracts
forge script script/E2EDemo.s.sol:E2EDemo \
  --rpc-url http://localhost:8545 \
  --broadcast \
  -vvvv
```

---

## 📚 Related Documentation

- **Quick Start**: `contracts/DEMO-QUICK-START.md`
- **Full Guide**: `docs/integration-test-demo.md`
- **Implementation**: `docs/DEMO-IMPLEMENTATION-SUMMARY.md`
- **Deployment**: `contracts/DEPLOYMENT-GUIDE.md`
- **Multi-Chain Setup**: `docs/MULTI-CHAIN-LOCAL-SETUP.md`

---

## 🎓 Understanding the Output

### Status Indicators
- `[BEFORE]` - State before action
- `[ACTION]` - What's happening now
- `[SUCCESS]` - Operation completed
- `[AFTER]` - New state
- `[INFO]` - Additional context
- `[RESULT]` - Final outcome
- `[OK]` - Verification passed

### Color Coding (in terminal)
- 🔵 Blue: Informational
- 🟢 Green: Success
- 🟡 Yellow: Warning/Note
- 🔴 Red: Error
- 🟣 Magenta: Important
- 🔶 Cyan: Highlights

---

## 💡 Tips for Best Demo Experience

1. **Test Before Live Demo**: Run once before presenting
2. **Clean Slate**: Use `./stop-multi-chain.sh` before starting
3. **Stable Internet**: RPC URLs need connectivity for forking
4. **Terminal Size**: Use fullscreen for best visibility
5. **Recording**: Consider screen recording for async presentations

---

## ✅ Success Criteria

After running the demo, you should see:
- ✅ All chains started successfully
- ✅ All contracts deployed
- ✅ All test phases passed
- ✅ Verbose output with clear formatting
- ✅ Final summary showing all features validated

**All tests should show `[PASS]` and green checkmarks!**

---

## 🚀 Ready to Demo?

```bash
./run-complete-demo.sh
```

**That's it!** Sit back and watch the protocol demonstrate itself with beautiful, verbose logging perfect for any audience.

---

**Questions or Issues?** Check the troubleshooting section or review the logs in the `logs/` directory.
