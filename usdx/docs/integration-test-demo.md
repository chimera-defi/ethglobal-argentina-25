# USDX Protocol - Integration Test Demo Guide

## Overview

This guide explains how to run the verbose end-to-end integration test that demonstrates the complete USDX Protocol flow. This test is perfect for presenting to investors, partners, and users to showcase the protocol's functionality.

## What the Demo Shows

The integration test demonstrates a complete user journey across two chains (Ethereum and Polygon):

### Phase 1: Deposit on Hub Chain (Ethereum)
- User deposits USDC into the USDX Vault
- User receives USDX tokens 1:1 with deposited USDC
- User receives vault wrapper shares representing yield-bearing position

### Phase 2: Cross-Chain Bridge via LayerZero
- User locks vault shares in the OFT (Omnichain Fungible Token) adapter
- Receives OFT tokens representing locked shares
- Sends OFT tokens cross-chain to Polygon using LayerZero
- LayerZero delivers message and mints share tokens on Polygon

### Phase 3: Mint USDX on Spoke Chain (Polygon)
- User mints USDX on Polygon using bridged vault shares as collateral
- Shares are burned proportionally to maintain proper collateralization
- User now has liquid USDX stablecoin on Polygon for DeFi activities

### Phase 4: Use USDX on Polygon
- User transfers USDX to another address
- Demonstrates USDX is fully liquid and usable in the destination chain ecosystem

### Phase 5: Burn USDX
- User burns USDX tokens when ready to exit position
- Reduces minted amount tracking for user

### Phase 6: Redeem and Withdraw
- User bridges remaining shares back to Ethereum via LayerZero
- Unlocks shares from OFT adapter
- Redeems vault wrapper shares for USDC
- User receives original capital back (potentially with yield)

## Running the Demo

### Quick Start

From the contracts directory, simply run:

```bash
./run-demo.sh
```

### Manual Execution

If you prefer to run the test directly:

```bash
cd /workspace/usdx/contracts
forge test --match-test testCompleteE2EFlow -vv
```

### Understanding the Output

The test produces detailed logging showing:

- **[BEFORE]** - State before each action
- **[ACTION]** - What operation is being performed
- **[SUCCESS]** - Confirmation that operation completed
- **[AFTER]** - State after each action
- **[INFO]** - Additional contextual information
- **[RESULT]** - Final results of operations
- **[OK]** - Verification checkmarks

Each phase is clearly separated with visual dividers for easy reading.

## Key Features Demonstrated

### 1. Cross-Chain Interoperability
- Seamless bridging between Ethereum and Polygon using LayerZero
- Omnichain fungible token (OFT) standard for share representation
- Trustless message passing and state synchronization

### 2. Collateralized Stablecoin
- USDX is backed 1:1 by USDC collateral
- Shares represent claim on underlying yield-bearing assets
- Proper collateralization maintained through burn mechanism

### 3. Yield-Bearing Vault Integration
- Integration with Yearn-style vaults for yield generation
- Users maintain exposure to yield while using minted stablecoin
- Vault wrapper shares track yield accrual

### 4. Capital Efficiency
- Users can deposit once on Ethereum
- Use the stablecoin on any supported spoke chain
- Redeem back to original assets with potential yield gains

## Technical Details

### Test File Location
`/workspace/usdx/contracts/test/forge/IntegrationE2E_OVault.t.sol`

### Chains Simulated
- **Hub Chain**: Ethereum (EID: 30101)
- **Spoke Chain**: Polygon (EID: 30109)

### Test Amounts
- Initial balance: 10,000 USDC
- Deposit amount: 1,000 USDC
- Mint amount: 500 USDX (half of shares)
- Transfer amount: 250 USDX (half of minted)

### Smart Contracts Tested
1. **USDXVault** - Main vault contract on hub chain
2. **USDXToken** - USDX stablecoin (on both hub and spoke)
3. **USDXYearnVaultWrapper** - ERC4626-compatible vault wrapper
4. **USDXShareOFTAdapter** - Adapter for cross-chain share transfers
5. **USDXShareOFT** - OFT implementation on spoke chains
6. **USDXSpokeMinter** - Minting contract on spoke chains
7. **USDXVaultComposerSync** - Composer for complex operations

## Presentation Tips

### For Investors
1. Emphasize the cross-chain capability and market opportunity
2. Highlight the capital efficiency - deposit once, use anywhere
3. Show the yield-bearing nature of the underlying collateral
4. Demonstrate full capital recovery (no permanent capital lock)

### For Technical Audiences
1. Walk through each phase explaining the smart contract interactions
2. Highlight the LayerZero integration for trustless cross-chain messaging
3. Explain the OFT standard and share tokenization
4. Discuss the collateralization mechanism and safety features

### For Users
1. Show the simple user flow: deposit → mint → use → redeem
2. Emphasize liquidity - USDX is fully transferable and usable in DeFi
3. Highlight yield generation while stablecoin is in use
4. Demonstrate easy exit - burn and redeem anytime

## Running Additional Tests

### Run all integration tests:
```bash
forge test --match-path "test/forge/Integration*.t.sol" -vv
```

### Run specific test suites:
```bash
# OVault integration tests
forge test --match-contract IntegrationOVaultTest -vv

# E2E flow only
forge test --match-test testCompleteE2EFlow -vv

# Cross-chain USDX transfer
forge test --match-test testCrossChainUSDXTransfer -vv
```

### Run with extra verbosity (shows traces):
```bash
forge test --match-test testCompleteE2EFlow -vvvv
```

## Troubleshooting

### Foundry Not Installed
The demo script will automatically install Foundry if not found. Alternatively:
```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### Stack Too Deep Error
The test requires `via_ir = true` in `foundry.toml`. This is already configured.

### Compilation Issues
Ensure dependencies are installed:
```bash
forge install
```

## Next Steps

After the demo:
1. Review the test code to understand implementation details
2. Explore individual contract test suites for deeper dive
3. Check deployment scripts for mainnet deployment process
4. Review security considerations and audit reports

## Support

For questions or issues:
- Review contract documentation in `/workspace/usdx/docs/`
- Check deployment guide in `/workspace/usdx/contracts/DEPLOYMENT-GUIDE.md`
- Review security audit in `/workspace/usdx/contracts/SECURITY-REVIEW.md`

---

**Last Updated**: 2025-11-23
**Test Version**: Integration E2E v1.0
**Protocol Version**: USDX v1.0
