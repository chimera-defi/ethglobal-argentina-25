# USDX Protocol - E2E Demo Guide

## Quick Start

**One command for everything:**

```bash
# Full demo: Start chains + deploy + test (~2 min)
./run-demo.sh

# Quick test: Just run test with mocks (~10 sec)
./run-demo.sh --quick
```

---

## What It Does

### Full Mode (`./run-demo.sh`)
1. Starts Ethereum (hub) and Base (spoke) local chains
2. Deploys all USDX Protocol contracts
3. Funds test user wallets
4. Runs verbose E2E test showing complete flow

### Quick Mode (`./run-demo.sh --quick`)
1. Runs E2E test with mock contracts
2. No chain setup needed
3. Perfect for CI/CD and quick validation

---

## What It Demonstrates

The demo runs **two comprehensive E2E tests** showing different user flows:

### Test 1: OVault Flow (Collateralized Minting)

**Phase 1: Deposit on Ethereum**
- User deposits 1,000 USDC
- Receives 1,000 USDX tokens (1:1)
- Gets vault wrapper shares for yield

**Phase 2: Cross-Chain Share Bridge**
- Locks shares in OFT adapter
- Bridges shares to Base via LayerZero
- Shares available on destination chain

**Phase 3: Collateralized Mint on Base**
- Mints 500 USDX using shares as collateral
- Shares burned proportionally
- USDX ready for DeFi on Base

**Phase 4-6: Use, Burn, Redeem**
- Transfer USDX, burn, redeem shares
- Full capital recovery with yield

### Test 2: Direct USDX Cross-Chain Flow (Simpler!)

**Flow 1: Mint on Hub**
- User deposits USDC on Ethereum
- Mints USDX directly (1:1)

**Flow 2: Send USDX Cross-Chain**
- User sends USDX from Ethereum to Base
- Instant cross-chain transfer via LayerZero
- USDX burns on source, mints on destination

**Flow 3: Use USDX on Any Chain**
- Use USDX natively on Base for DeFi
- No need to bridge back!
- True omnichain stablecoin

**Key Insight**: Users can mint USDX once and use it on any supported chain. No need for complex share bridging for simple transfers!

---

## What Gets Deployed

**Hub Chain (Ethereum - Port 8545):**
- MockUSDC, MockYearnVault
- USDXToken, USDXVault
- USDXYearnVaultWrapper, USDXShareOFTAdapter

**Spoke Chain (Base - Port 8546):**
- USDXToken, USDXShareOFT, USDXSpokeMinter

---

## Manual Control

```bash
# Start chains only
./start-multi-chain.sh

# Stop everything
./stop-multi-chain.sh

# Run specific tests
cd contracts
forge test --match-test testCompleteE2EFlow -vv

# Check chain status
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

---

## Troubleshooting

**"Foundry not found"**
```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc && foundryup
```

**"Port already in use"**
```bash
./stop-multi-chain.sh
sleep 2
./run-demo.sh
```

**Test failures**
```bash
cd contracts
forge test --match-test testCompleteE2EFlow -vvvv  # Extra verbose
```

---

## For Presentations

### Investors
**Emphasize the omnichain value proposition:**
- "Users mint USDX once on Ethereum, use it on any chain"
- "True cross-chain stablecoin - no complex bridging needed"
- "Lower fees on L2s while maintaining Ethereum security"
- Show Test 2 first (simpler, more impressive)

### Technical Audiences
**Show both architectural patterns:**
- Test 1: Collateralized minting via OVault (advanced users)
- Test 2: Direct USDX cross-chain transfer (simple users)
- Highlight: LayerZero OFT standard, burn-and-mint pattern
- Discuss: Trade-offs between collateralized vs direct minting

### Users
**Keep it simple:**
- "Deposit USDC once on Ethereum"
- "Send your USDX to Base with one click"
- "Use USDX in Base DeFi at lower fees"
- Show Test 2 - it's the user-friendly flow

---

## Implementation Details

**Test File:** `contracts/test/forge/IntegrationE2E_OVault.t.sol`

**Test 1: `testCompleteE2EFlow`**
- Full OVault collateralized flow
- 6 phases showing deposit → share bridge → mint → use → burn → redeem
- Demonstrates advanced yield-bearing vault integration

**Test 2: `testCompleteUserFlows`** ⭐ **Recommended for demos**
- Simpler, more intuitive flow
- Shows direct cross-chain USDX transfer
- 3 flows: Mint → Send Cross-Chain → Use Anywhere
- Better for explaining core value proposition

**Configuration:** `contracts/foundry.toml`
- `via_ir = true` (required for complex logging)
- Solidity 0.8.30
- Optimizer enabled (200 runs)

**Test Results:** 124/124 tests passing

---

## File Structure

```
/workspace/usdx/
├── run-demo.sh                    # Main demo script (quick or full)
├── start-multi-chain.sh           # Start chains (called by demo)
├── stop-multi-chain.sh            # Stop chains
│
├── contracts/
│   ├── test/forge/
│   │   └── IntegrationE2E_OVault.t.sol  # Verbose E2E test
│   ├── script/
│   │   └── E2EDemo.s.sol          # Live chain demo script
│   └── foundry.toml               # Config (via_ir = true)
│
└── docs/
    └── e2e-demo-guide.md          # This file
```

---

## Related Docs

- **Setup**: `docs/21-smart-contract-development-setup.md`
- **Architecture**: `docs/02-architecture.md`
- **Multi-Chain**: `docs/MULTI-CHAIN-LOCAL-SETUP.md`
- **Deployment**: `contracts/DEPLOYMENT-GUIDE.md`

---

**Ready to demo?** → `./run-demo.sh`
