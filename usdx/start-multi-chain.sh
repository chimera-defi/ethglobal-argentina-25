#!/bin/bash

# USDX Protocol - Multi-Chain Local Setup Script
# This script starts both hub and spoke chains, deploys contracts, and starts the bridge relayer

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║      🚀 USDX Protocol - Multi-Chain Local Setup          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if anvil is installed
if ! command -v anvil &> /dev/null; then
    echo -e "${RED}❌ Anvil not found. Please install Foundry first:${NC}"
    echo "   curl -L https://foundry.paradigm.xyz | bash"
    echo "   foundryup"
    exit 1
fi

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    echo -e "${RED}❌ Forge not found. Please install Foundry first.${NC}"
    exit 1
fi

# Check for RPC URLs
if [ -z "$ETH_RPC_URL" ]; then
    echo -e "${YELLOW}⚠️  ETH_RPC_URL not set. Using default (may be slow).${NC}"
    ETH_RPC_URL="https://eth.llamarpc.com"
fi

if [ -z "$POLYGON_RPC_URL" ]; then
    echo -e "${YELLOW}⚠️  POLYGON_RPC_URL not set. Using default (may be slow).${NC}"
    POLYGON_RPC_URL="https://polygon.llamarpc.com"
fi

# Create log directory
mkdir -p logs

echo -e "${GREEN}✓${NC} Starting Hub Chain (Ethereum) on port 8545..."
anvil \
  --port 8545 \
  --chain-id 1 \
  --fork-url "$ETH_RPC_URL" \
  --block-time 2 \
  > logs/anvil-hub.log 2>&1 &
HUB_PID=$!
echo "  PID: $HUB_PID"

sleep 2

echo -e "${GREEN}✓${NC} Starting Spoke Chain (Polygon) on port 8546..."
anvil \
  --port 8546 \
  --chain-id 137 \
  --fork-url "$POLYGON_RPC_URL" \
  --block-time 2 \
  > logs/anvil-spoke.log 2>&1 &
SPOKE_PID=$!
echo "  PID: $SPOKE_PID"

sleep 2

# Check if both are running
if ! kill -0 $HUB_PID 2>/dev/null; then
    echo -e "${RED}❌ Hub chain failed to start. Check logs/anvil-hub.log${NC}"
    exit 1
fi

if ! kill -0 $SPOKE_PID 2>/dev/null; then
    echo -e "${RED}❌ Spoke chain failed to start. Check logs/anvil-spoke.log${NC}"
    kill $HUB_PID
    exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} Both chains are running!"
echo ""

# Deploy contracts
cd contracts

echo -e "${GREEN}✓${NC} Deploying Hub contracts..."
forge script script/DeployHubOnly.s.sol:DeployHubOnly \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  > ../logs/deploy-hub.log 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Hub deployment failed. Check logs/deploy-hub.log${NC}"
    kill $HUB_PID $SPOKE_PID
    exit 1
fi

echo -e "${GREEN}✓${NC} Deploying Spoke contracts..."
forge script script/DeploySpokeOnly.s.sol:DeploySpokeOnly \
  --rpc-url http://localhost:8546 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  > ../logs/deploy-spoke.log 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Spoke deployment failed. Check logs/deploy-spoke.log${NC}"
    kill $HUB_PID $SPOKE_PID
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}✓${NC} Contracts deployed successfully!"
echo ""

# Start bridge relayer (if Node.js is available)
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓${NC} Starting bridge relayer..."
    cd contracts
    node script/bridge-relayer.js > ../logs/bridge-relayer.log 2>&1 &
    RELAYER_PID=$!
    cd ..
    echo "  PID: $RELAYER_PID"
else
    echo -e "${YELLOW}⚠️  Node.js not found. Bridge relayer not started.${NC}"
    echo "   You'll need to manually sync positions between chains."
    RELAYER_PID=""
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              ✅ USDX Multi-Chain Setup Complete!          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📡 Hub Chain (Ethereum):   http://localhost:8545"
echo "📡 Spoke Chain (Polygon):  http://localhost:8546"
echo ""
echo "📝 Process IDs:"
echo "   Hub Chain:      $HUB_PID"
echo "   Spoke Chain:    $SPOKE_PID"
if [ -n "$RELAYER_PID" ]; then
echo "   Bridge Relayer: $RELAYER_PID"
fi
echo ""
echo "📋 Logs:"
echo "   Hub:     logs/anvil-hub.log"
echo "   Spoke:   logs/anvil-spoke.log"
if [ -n "$RELAYER_PID" ]; then
echo "   Relayer: logs/bridge-relayer.log"
fi
echo ""
echo "🎯 Next Steps:"
echo "   1. Start frontend: cd frontend && npm run dev"
echo "   2. Configure MetaMask with both networks (see MULTI-CHAIN-LOCAL-SETUP.md)"
echo "   3. Test deposit on hub → mint on spoke flow"
echo ""
echo "🛑 To stop all services:"
echo "   kill $HUB_PID $SPOKE_PID${RELAYER_PID:+ $RELAYER_PID}"
echo ""

# Save PIDs to file for easy cleanup
echo "$HUB_PID $SPOKE_PID ${RELAYER_PID}" > .usdx-pids

echo "💡 Run './stop-multi-chain.sh' to stop all services"
echo ""
