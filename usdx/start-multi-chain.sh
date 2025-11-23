#!/bin/bash

# USDX Protocol - Multi-Chain Local Setup Script
# This script starts hub and spoke chains, deploys contracts, and starts the bridge relayer
# Supports: Hub (Ethereum Sepolia), Spoke Base (Base Sepolia), Spoke Arc (Arc Testnet)

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
BLUE='\033[0;34m'
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

# RPC URL configuration with fallbacks
# Hub Chain (Ethereum Sepolia)
if [ -z "$HUB_RPC_URL" ]; then
    echo -e "${YELLOW}⚠️  HUB_RPC_URL not set. Trying fallback RPCs...${NC}"
    # Try multiple RPC endpoints
    HUB_RPC_URL="https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"  # Public Infura
    # Fallback: https://rpc.sepolia.org (public)
fi

# Spoke Chain - Base Sepolia
if [ -z "$SPOKE_BASE_RPC_URL" ]; then
    echo -e "${YELLOW}⚠️  SPOKE_BASE_RPC_URL not set. Using public Base Sepolia RPC...${NC}"
    SPOKE_BASE_RPC_URL="https://sepolia.base.org"  # Public Base Sepolia RPC
fi

# Spoke Chain - Arc Testnet (optional)
if [ -z "$SPOKE_ARC_RPC_URL" ]; then
    SPOKE_ARC_RPC_URL="https://rpc.testnet.arc.network"  # Public Arc Testnet RPC
fi

# Check which chains to start
START_ARC=${START_ARC:-false}  # Set START_ARC=true to also start Arc chain

# Create log directory
mkdir -p logs

# Function to test RPC connection
test_rpc() {
    local rpc_url=$1
    local chain_name=$2
    
    echo -e "${BLUE}🔍 Testing ${chain_name} RPC: ${rpc_url}${NC}"
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        "$rpc_url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} ${chain_name} RPC is accessible"
        return 0
    else
        echo -e "${YELLOW}⚠️  ${chain_name} RPC test failed, but continuing...${NC}"
        return 1
    fi
}

# Test RPC connections
test_rpc "$HUB_RPC_URL" "Hub (Ethereum Sepolia)"
test_rpc "$SPOKE_BASE_RPC_URL" "Spoke Base (Base Sepolia)"
if [ "$START_ARC" = "true" ]; then
    test_rpc "$SPOKE_ARC_RPC_URL" "Spoke Arc (Arc Testnet)"
fi

echo ""

# Start Hub Chain (Ethereum Sepolia)
echo -e "${GREEN}✓${NC} Starting Hub Chain (Ethereum Sepolia) on port 8545..."
echo "   Chain ID: 11155111"
echo "   RPC: $HUB_RPC_URL"
anvil \
  --port 8545 \
  --chain-id 11155111 \
  --fork-url "$HUB_RPC_URL" \
  --block-time 2 \
  > logs/anvil-hub.log 2>&1 &
HUB_PID=$!
echo "   PID: $HUB_PID"

sleep 3

# Start Spoke Chain - Base Sepolia
echo -e "${GREEN}✓${NC} Starting Spoke Chain (Base Sepolia) on port 8546..."
echo "   Chain ID: 84532"
echo "   RPC: $SPOKE_BASE_RPC_URL"
anvil \
  --port 8546 \
  --chain-id 84532 \
  --fork-url "$SPOKE_BASE_RPC_URL" \
  --block-time 2 \
  > logs/anvil-spoke.log 2>&1 &
SPOKE_BASE_PID=$!
echo "   PID: $SPOKE_BASE_PID"

sleep 3

# Start Spoke Chain - Arc Testnet (optional)
if [ "$START_ARC" = "true" ]; then
    echo -e "${GREEN}✓${NC} Starting Spoke Chain (Arc Testnet) on port 8547..."
    echo "   Chain ID: 5042002"
    echo "   RPC: $SPOKE_ARC_RPC_URL"
    anvil \
      --port 8547 \
      --chain-id 5042002 \
      --fork-url "$SPOKE_ARC_RPC_URL" \
      --block-time 2 \
      > logs/anvil-arc.log 2>&1 &
    SPOKE_ARC_PID=$!
    echo "   PID: $SPOKE_ARC_PID"
    sleep 3
else
    SPOKE_ARC_PID=""
fi

# Check if chains are running
if ! kill -0 $HUB_PID 2>/dev/null; then
    echo -e "${RED}❌ Hub chain failed to start. Check logs/anvil-hub.log${NC}"
    exit 1
fi

if ! kill -0 $SPOKE_BASE_PID 2>/dev/null; then
    echo -e "${RED}❌ Spoke Base chain failed to start. Check logs/anvil-spoke.log${NC}"
    kill $HUB_PID 2>/dev/null || true
    exit 1
fi

if [ -n "$SPOKE_ARC_PID" ] && ! kill -0 $SPOKE_ARC_PID 2>/dev/null; then
    echo -e "${RED}❌ Spoke Arc chain failed to start. Check logs/anvil-arc.log${NC}"
    kill $HUB_PID $SPOKE_BASE_PID 2>/dev/null || true
    exit 1
fi

echo ""
if [ "$START_ARC" = "true" ]; then
    echo -e "${GREEN}✓${NC} All chains are running! (Hub + Base + Arc)"
else
    echo -e "${GREEN}✓${NC} Chains are running! (Hub + Base)"
    echo -e "${BLUE}💡 Tip: Set START_ARC=true to also start Arc chain${NC}"
fi
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
    kill $HUB_PID $SPOKE_BASE_PID ${SPOKE_ARC_PID:+$SPOKE_ARC_PID} 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}✓${NC} Deploying Spoke contracts (Base Sepolia)..."
forge script script/DeploySpokeOnly.s.sol:DeploySpokeOnly \
  --rpc-url http://localhost:8546 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  > ../logs/deploy-spoke-base.log 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Spoke Base deployment failed. Check logs/deploy-spoke-base.log${NC}"
    kill $HUB_PID $SPOKE_BASE_PID ${SPOKE_ARC_PID:+$SPOKE_ARC_PID} 2>/dev/null || true
    exit 1
fi

# Deploy Arc chain if started
if [ "$START_ARC" = "true" ] && [ -n "$SPOKE_ARC_PID" ]; then
    echo -e "${GREEN}✓${NC} Deploying Spoke contracts (Arc Testnet)..."
    forge script script/DeploySpoke.s.sol:DeploySpoke \
      --rpc-url http://localhost:8547 \
      --broadcast \
      --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
      > ../logs/deploy-spoke-arc.log 2>&1

    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Spoke Arc deployment failed. Check logs/deploy-spoke-arc.log${NC}"
        echo "   Continuing with Hub and Base chains..."
    fi
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
echo "📡 Chains Running:"
echo "   Hub Chain (Ethereum Sepolia):  http://localhost:8545 (Chain ID: 11155111)"
echo "   Spoke Chain (Base Sepolia):   http://localhost:8546 (Chain ID: 84532)"
if [ -n "$SPOKE_ARC_PID" ]; then
echo "   Spoke Chain (Arc Testnet):     http://localhost:8547 (Chain ID: 5042002)"
fi
echo ""
echo "📝 Process IDs:"
echo "   Hub Chain:      $HUB_PID"
echo "   Spoke Base:    $SPOKE_BASE_PID"
if [ -n "$SPOKE_ARC_PID" ]; then
echo "   Spoke Arc:      $SPOKE_ARC_PID"
fi
if [ -n "$RELAYER_PID" ]; then
echo "   Bridge Relayer: $RELAYER_PID"
fi
echo ""
echo "📋 Logs:"
echo "   Hub:        logs/anvil-hub.log"
echo "   Spoke Base: logs/anvil-spoke.log"
if [ -n "$SPOKE_ARC_PID" ]; then
echo "   Spoke Arc:   logs/anvil-arc.log"
fi
if [ -n "$RELAYER_PID" ]; then
echo "   Relayer:     logs/bridge-relayer.log"
fi
echo ""
echo "🎯 Next Steps:"
echo "   1. Start frontend: cd frontend && npm run dev"
echo "   2. Configure MetaMask with networks (see MULTI-CHAIN-LOCAL-SETUP.md)"
echo "   3. Test deposit on hub → mint on spoke flow"
echo ""
echo "🛑 To stop all services:"
STOP_PIDS="$HUB_PID $SPOKE_BASE_PID"
if [ -n "$SPOKE_ARC_PID" ]; then
    STOP_PIDS="$STOP_PIDS $SPOKE_ARC_PID"
fi
if [ -n "$RELAYER_PID" ]; then
    STOP_PIDS="$STOP_PIDS $RELAYER_PID"
fi
echo "   kill $STOP_PIDS"
echo ""

# Save PIDs to file for easy cleanup
echo "$HUB_PID $SPOKE_BASE_PID ${SPOKE_ARC_PID} ${RELAYER_PID}" > .usdx-pids

echo "💡 Run './stop-multi-chain.sh' to stop all services"
echo ""
