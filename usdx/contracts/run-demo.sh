#!/bin/bash

# USDX Protocol - End-to-End Integration Test Demo
# This script runs the verbose integration test perfect for investor presentations

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "                   USDX PROTOCOL - INTEGRATION TEST DEMO                        "
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "This demonstration will show the complete user flow:"
echo "  1. Deposit USDC on Ethereum hub chain"
echo "  2. Lock vault shares in OFT adapter"
echo "  3. Bridge shares cross-chain to Polygon via LayerZero"
echo "  4. Mint USDX stablecoin on Polygon using vault shares as collateral"
echo "  5. Use USDX (transfer to another user)"
echo "  6. Burn USDX and unlock shares"
echo "  7. Bridge shares back to Ethereum"
echo "  8. Redeem shares for USDC (with potential yield)"
echo ""
echo "Press Enter to start the demonstration..."
read

# Ensure we're in the contracts directory
cd "$(dirname "$0")"

# Check if Foundry is installed
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry not found. Installing..."
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup
fi

# Add forge to PATH
export PATH="$HOME/.foundry/bin:$PATH"

# Run the verbose integration test
echo ""
echo "Running integration test with verbose logging..."
echo ""

forge test --match-test testCompleteE2EFlow -vv

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                        ✅ DEMO COMPLETED SUCCESSFULLY                         "
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Key Highlights:"
    echo "  ✓ Cross-chain functionality via LayerZero"
    echo "  ✓ Collateralized stablecoin minting"
    echo "  ✓ Yield-bearing vault integration"
    echo "  ✓ Full capital recovery demonstrated"
    echo ""
else
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                           ❌ TEST FAILED                                      "
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    exit 1
fi
