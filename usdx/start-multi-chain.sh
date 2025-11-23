#!/bin/bash

# USDX Protocol - Multi-Chain Local Setup Script
# Batteries included - forks mainnet chains with default RPCs, ready to test!
# 
# Supports:
#   - Hub: Ethereum Mainnet (Chain ID: 1)
#   - Spoke Base: Base Mainnet (Chain ID: 8453)
#   - Spoke Arc: Arc Testnet (Chain ID: 5042002) - Enabled by default
#
# Usage:
#   ./start-multi-chain.sh                    # Start all chains (default)
#   START_ARC=false ./start-multi-chain.sh    # Disable Arc chain
#   HUB_RPC_URL=... ./start-multi-chain.sh    # Use custom RPC URLs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Load environment variables from .env if present so custom RPC overrides work
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo -e "${BLUE}ℹ️  Loading environment variables from $ENV_FILE${NC}"
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
else
    echo -e "${YELLOW}⚠️  No .env file found at $ENV_FILE. Using built-in defaults.${NC}"
fi

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

# RPC URL configuration with reliable defaults (batteries included)
# Hub Chain (Ethereum Mainnet)
if [ -z "$HUB_RPC_URL" ]; then
    echo -e "${BLUE}ℹ️  Using default Ethereum Mainnet RPC...${NC}"
    # Public RPC endpoints (reliable defaults)
    HUB_RPC_URL="https://eth.llamarpc.com"  # LlamaRPC (reliable public endpoint)
    # Alternatives: https://rpc.ankr.com/eth, https://eth-mainnet.public.blastapi.io
fi

# Spoke Chain - Base Mainnet
if [ -z "$SPOKE_BASE_RPC_URL" ]; then
    echo -e "${BLUE}ℹ️  Using default Base Mainnet RPC...${NC}"
    SPOKE_BASE_RPC_URL="https://mainnet.base.org"  # Official Base Mainnet RPC
    # Alternative: https://base.llamarpc.com
fi

# Spoke Chain - Arc Testnet (mainnet not available yet)
if [ -z "$SPOKE_ARC_RPC_URL" ]; then
    echo -e "${BLUE}ℹ️  Using default Arc Testnet RPC...${NC}"
    SPOKE_ARC_RPC_URL="https://rpc.testnet.arc.network"  # Official Arc Testnet RPC
fi

# Arc chain is enabled by default (set START_ARC=false to disable)
START_ARC=${START_ARC:-true}  # Default: true (include Arc by default)

# Create log directory
mkdir -p logs

# Track started processes for cleanup
STARTED_PIDS=""

# Cleanup function to kill all started processes
cleanup() {
    if [ -n "$STARTED_PIDS" ]; then
        echo -e "\n${YELLOW}🧹 Cleaning up started processes...${NC}"
        for PID in $STARTED_PIDS; do
            if kill -0 $PID 2>/dev/null; then
                kill $PID 2>/dev/null || true
            fi
        done
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Function to kill processes on a port
kill_port() {
    local port=$1
    local pids=""
    
    # Try different methods to find processes using the port
    if command -v lsof &> /dev/null; then
        pids=$(lsof -ti:$port 2>/dev/null || true)
    elif command -v ss &> /dev/null; then
        pids=$(ss -ltnp 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[0-9]+' | sort -u || true)
    elif command -v netstat &> /dev/null; then
        pids=$(netstat -ltnp 2>/dev/null | grep ":$port " | grep -oP '[0-9]+/anvil' | cut -d'/' -f1 | sort -u || true)
    fi
    
    if [ -n "$pids" ]; then
        echo -e "${YELLOW}⚠️  Port $port is in use. Killing existing processes...${NC}"
        for pid in $pids; do
            kill $pid 2>/dev/null || true
        done
        sleep 1
        # Force kill if still running
        if command -v lsof &> /dev/null; then
            pids=$(lsof -ti:$port 2>/dev/null || true)
        elif command -v ss &> /dev/null; then
            pids=$(ss -ltnp 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[0-9]+' | sort -u || true)
        fi
        if [ -n "$pids" ]; then
            for pid in $pids; do
                kill -9 $pid 2>/dev/null || true
            done
            sleep 1
        fi
    fi
}

# Function to verify a chain is running
verify_chain() {
    local port=$1
    local chain_name=$2
    local max_attempts=10
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            "http://localhost:$port" > /dev/null 2>&1; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    echo -e "${RED}❌ ${chain_name} failed to respond on port $port after ${max_attempts} attempts${NC}"
    return 1
}

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
test_rpc "$HUB_RPC_URL" "Hub (Ethereum Mainnet)"
test_rpc "$SPOKE_BASE_RPC_URL" "Spoke Base (Base Mainnet)"
if [ "$START_ARC" != "false" ]; then
    test_rpc "$SPOKE_ARC_RPC_URL" "Spoke Arc (Arc Testnet)"
fi

echo ""

# Clean up any existing processes on ports
echo -e "${BLUE}🧹 Cleaning up any existing processes on ports...${NC}"
kill_port 8545
kill_port 8546
kill_port 8547

# Start Hub Chain (Ethereum Mainnet)
echo ""
echo -e "${GREEN}✓${NC} Starting Hub Chain (Ethereum Mainnet) on port 8545..."
echo "   Chain ID: 1"
echo "   RPC: $HUB_RPC_URL"
anvil \
  --port 8545 \
  --chain-id 1 \
  --fork-url "$HUB_RPC_URL" \
  --block-time 2 \
  > logs/anvil-hub.log 2>&1 &
HUB_PID=$!
STARTED_PIDS="$STARTED_PIDS $HUB_PID"
echo "   PID: $HUB_PID"

sleep 3

# Verify Hub chain started
if ! kill -0 $HUB_PID 2>/dev/null; then
    echo -e "${RED}❌ Hub chain process died immediately. Check logs/anvil-hub.log:${NC}"
    tail -20 logs/anvil-hub.log 2>/dev/null || echo "   (log file not found)"
    exit 1
fi

if ! verify_chain 8545 "Hub Chain"; then
    echo -e "${RED}❌ Hub chain failed to start. Check logs/anvil-hub.log:${NC}"
    tail -20 logs/anvil-hub.log 2>/dev/null || echo "   (log file not found)"
    exit 1
fi
echo -e "${GREEN}✓${NC} Hub chain is running and responding"

# Start Spoke Chain - Base Mainnet
echo ""
echo -e "${GREEN}✓${NC} Starting Spoke Chain (Base Mainnet) on port 8546..."
echo "   Chain ID: 8453"
echo "   RPC: $SPOKE_BASE_RPC_URL"
anvil \
  --port 8546 \
  --chain-id 8453 \
  --fork-url "$SPOKE_BASE_RPC_URL" \
  --block-time 2 \
  > logs/anvil-spoke.log 2>&1 &
SPOKE_BASE_PID=$!
STARTED_PIDS="$STARTED_PIDS $SPOKE_BASE_PID"
echo "   PID: $SPOKE_BASE_PID"

sleep 3

# Verify Spoke Base chain started
if ! kill -0 $SPOKE_BASE_PID 2>/dev/null; then
    echo -e "${RED}❌ Spoke Base chain process died immediately. Check logs/anvil-spoke.log:${NC}"
    tail -20 logs/anvil-spoke.log 2>/dev/null || echo "   (log file not found)"
    exit 1
fi

if ! verify_chain 8546 "Spoke Base Chain"; then
    echo -e "${RED}❌ Spoke Base chain failed to start. Check logs/anvil-spoke.log:${NC}"
    tail -20 logs/anvil-spoke.log 2>/dev/null || echo "   (log file not found)"
    exit 1
fi
echo -e "${GREEN}✓${NC} Spoke Base chain is running and responding"

# Start Spoke Chain - Arc Testnet (enabled by default)
if [ "$START_ARC" != "false" ]; then
    echo ""
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
    STARTED_PIDS="$STARTED_PIDS $SPOKE_ARC_PID"
    echo "   PID: $SPOKE_ARC_PID"
    sleep 3

    # Verify Spoke Arc chain started
    if ! kill -0 $SPOKE_ARC_PID 2>/dev/null; then
        echo -e "${RED}❌ Spoke Arc chain process died immediately. Check logs/anvil-arc.log:${NC}"
        tail -20 logs/anvil-arc.log 2>/dev/null || echo "   (log file not found)"
        exit 1
    fi

    if ! verify_chain 8547 "Spoke Arc Chain"; then
        echo -e "${RED}❌ Spoke Arc chain failed to start. Check logs/anvil-arc.log:${NC}"
        tail -20 logs/anvil-arc.log 2>/dev/null || echo "   (log file not found)"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Spoke Arc chain is running and responding"
else
    echo -e "${YELLOW}⚠️  Arc chain disabled (START_ARC=false)${NC}"
    SPOKE_ARC_PID=""
fi

echo ""
if [ "$START_ARC" != "false" ]; then
    echo -e "${GREEN}✓${NC} All chains are running! (Hub + Base + Arc)"
else
    echo -e "${GREEN}✓${NC} Chains are running! (Hub + Base)"
    echo -e "${BLUE}💡 Tip: Arc chain is enabled by default. Set START_ARC=false to disable${NC}"
fi
echo ""

# Deploy contracts
cd contracts

# Set private key as environment variable (scripts use vm.envUint("PRIVATE_KEY"))
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

echo -e "${GREEN}✓${NC} Deploying Hub contracts..."
echo -e "${BLUE}   This may take a minute...${NC}"
if ! forge script script/DeployHubOnly.s.sol:DeployHubOnly \
  --rpc-url http://localhost:8545 \
  --broadcast \
  2>&1 | tee ../logs/deploy-hub.log; then
    echo ""
    echo -e "${RED}❌ Hub deployment failed!${NC}"
    echo -e "${YELLOW}Last 20 lines of log:${NC}"
    tail -20 ../logs/deploy-hub.log 2>/dev/null || echo "   (log file not found)"
    kill $HUB_PID $SPOKE_BASE_PID ${SPOKE_ARC_PID:+$SPOKE_ARC_PID} 2>/dev/null || true
    exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} Deploying Spoke contracts (Base Mainnet)..."
echo -e "${BLUE}   This may take a minute...${NC}"
if ! forge script script/DeploySpokeOnly.s.sol:DeploySpokeOnly \
  --rpc-url http://localhost:8546 \
  --broadcast \
  2>&1 | tee ../logs/deploy-spoke-base.log; then
    echo ""
    echo -e "${RED}❌ Spoke Base deployment failed!${NC}"
    echo -e "${YELLOW}Last 20 lines of log:${NC}"
    tail -20 ../logs/deploy-spoke-base.log 2>/dev/null || echo "   (log file not found)"
    kill $HUB_PID $SPOKE_BASE_PID ${SPOKE_ARC_PID:+$SPOKE_ARC_PID} 2>/dev/null || true
    exit 1
fi

# Deploy Arc chain if started
if [ "$START_ARC" != "false" ] && [ -n "$SPOKE_ARC_PID" ]; then
    echo ""
    echo -e "${GREEN}✓${NC} Deploying Spoke contracts (Arc Testnet)..."
    echo -e "${BLUE}   This may take a minute...${NC}"
    if ! forge script script/DeploySpoke.s.sol:DeploySpoke \
      --rpc-url http://localhost:8547 \
      --broadcast \
      2>&1 | tee ../logs/deploy-spoke-arc.log; then
        echo ""
        echo -e "${YELLOW}⚠️  Spoke Arc deployment failed!${NC}"
        echo -e "${YELLOW}Last 20 lines of log:${NC}"
        tail -20 ../logs/deploy-spoke-arc.log 2>/dev/null || echo "   (log file not found)"
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
echo "   Hub Chain (Ethereum Mainnet):  http://localhost:8545 (Chain ID: 1)"
echo "   Spoke Chain (Base Mainnet):    http://localhost:8546 (Chain ID: 8453)"
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

# Save PIDs to file for easy cleanup (only non-empty PIDs)
echo "$STOP_PIDS" > .usdx-pids

# Disable cleanup trap on successful completion (we want processes to keep running)
trap - EXIT INT TERM

echo "💡 Run './stop-multi-chain.sh' to stop all services"
echo ""
