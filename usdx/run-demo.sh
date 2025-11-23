#!/bin/bash

# USDX Protocol - Complete E2E Demo
# Single command to: start chains → deploy contracts → run verbose test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║              USDX PROTOCOL - E2E DEMONSTRATION                             ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Parse arguments
QUICK_MODE=false
if [ "$1" = "--quick" ] || [ "$1" = "-q" ]; then
    QUICK_MODE=true
fi

if [ "$QUICK_MODE" = true ]; then
    # Quick mode: Just run the test with mocks (no chains)
    echo -e "${BLUE}Quick Mode: Running E2E tests with mocks (no live chains)${NC}"
    echo ""
    
    cd contracts
    export PATH="$HOME/.foundry/bin:$PATH"
    
    if ! command -v forge &> /dev/null; then
        echo -e "${RED}Foundry not found. Installing...${NC}"
        curl -L https://foundry.paradigm.xyz | bash
        source ~/.bashrc && foundryup
        export PATH="$HOME/.foundry/bin:$PATH"
    fi
    
    echo -e "${GREEN}Running complete OVault flow (deposit → bridge → mint)...${NC}"
    echo ""
    forge test --match-test testCompleteE2EFlow -vv
    
    echo ""
    echo -e "${GREEN}Running cross-chain USDX transfer flow...${NC}"
    echo ""
    forge test --match-test testCompleteUserFlows -vv
    
else
    # Full mode: Start chains, deploy, and test
    echo -e "${YELLOW}Full Mode: Starting chains, deploying contracts, running test${NC}"
    echo -e "${YELLOW}Duration: ~2 minutes${NC}"
    echo ""
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read
    
    # Check prerequisites
    if ! command -v anvil &> /dev/null || ! command -v forge &> /dev/null; then
        echo -e "${BLUE}Installing Foundry...${NC}"
        curl -L https://foundry.paradigm.xyz | bash
        source ~/.bashrc && foundryup
    fi
    
    export PATH="$HOME/.foundry/bin:$PATH"
    
    # Clean up existing
    echo -e "${BLUE}Cleaning up...${NC}"
    ./stop-multi-chain.sh 2>/dev/null || true
    sleep 2
    
    # Start chains and deploy
    echo ""
    echo -e "${GREEN}Starting multi-chain setup...${NC}"
    if ! START_ARC=false ./start-multi-chain.sh; then
        echo -e "${RED}Failed to start chains${NC}"
        exit 1
    fi
    
    # Run E2E tests
    echo ""
    echo -e "${GREEN}Running E2E integration tests...${NC}"
    echo ""
    cd contracts
    
    echo -e "${BLUE}Test 1: Complete OVault Flow${NC}"
    if ! forge test --match-test testCompleteE2EFlow -vv; then
        echo -e "${RED}Test 1 failed${NC}"
        cd ..
        ./stop-multi-chain.sh
        exit 1
    fi
    
    echo ""
    echo -e "${BLUE}Test 2: Cross-Chain USDX Transfer${NC}"
    if ! forge test --match-test testCompleteUserFlows -vv; then
        echo -e "${RED}Test 2 failed${NC}"
        cd ..
        ./stop-multi-chain.sh
        exit 1
    fi
    cd ..
    
    # Success
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    DEMO COMPLETED SUCCESSFULLY!                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}Chains are still running for manual testing${NC}"
    echo -e "${YELLOW}Stop with: ./stop-multi-chain.sh${NC}"
    echo ""
fi
