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

## The E2E Flow

The test demonstrates a complete user journey:

**Phase 1: Deposit on Ethereum**
- User deposits 1,000 USDC
- Receives 1,000 USDX tokens (1:1)
- Gets vault wrapper shares for yield

**Phase 2: Cross-Chain Bridge**
- Locks shares in OFT adapter
- Bridges to Base via LayerZero
- Shares available on destination chain

**Phase 3: Mint on Base**
- Mints 500 USDX using shares as collateral
- Shares burned proportionally
- USDX ready for DeFi on Base

**Phase 4: Use USDX**
- Transfers 250 USDX to another user
- Demonstrates full liquidity

**Phase 5: Burn**
- Burns 250 USDX
- Frees up collateral

**Phase 6: Redeem**
- Bridges shares back to Ethereum
- Redeems for USDC (with yield)
- Full capital recovery

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
- Focus on: Cross-chain capability, capital efficiency, yield generation
- Show: Complete flow in ~2 minutes
- Highlight: Full capital recovery demonstrated

### Technical
- Focus on: LayerZero integration, OFT standard, ERC4626 vaults
- Show: Code structure and contract interactions
- Highlight: Trustless cross-chain messaging

### Users
- Focus on: Simple 3-step process (Deposit → Use → Redeem)
- Show: Easy transfers and full liquidity
- Highlight: Continuous yield while using USDX

---

## Implementation Details

**Test File:** `contracts/test/forge/IntegrationE2E_OVault.t.sol`
- Enhanced with comprehensive console logging
- 6 phases with before/after states
- Professional formatted output

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
