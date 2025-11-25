#!/bin/bash

# USDX Protocol - Complete Deployment and Demo Script
# Deploys contracts on Ethereum Sepolia (Hub) and Base Sepolia (Spoke)
# Runs cross-chain minting and bridging demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRACTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOYMENT_FILE="$CONTRACTS_DIR/deployments/sepolia-base-sepolia.json"

# Build RPC URLs from Alchemy key or use defaults
build_rpc_urls() {
    # Default public RPC URLs (no API key required)
    DEFAULT_SEPOLIA_RPC="https://rpc.sepolia.org"
    DEFAULT_BASE_SEPOLIA_RPC="https://sepolia.base.org"
    
    # If Alchemy key is provided, use Alchemy endpoints
    if [ -n "$ALCHEMY_API_KEY" ]; then
        SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY"
        BASE_SEPOLIA_RPC_URL="https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY"
        echo -e "${BLUE}Using Alchemy RPC endpoints${NC}"
    else
        # Use default public RPC URLs
        SEPOLIA_RPC_URL="$DEFAULT_SEPOLIA_RPC"
        BASE_SEPOLIA_RPC_URL="$DEFAULT_BASE_SEPOLIA_RPC"
        echo -e "${YELLOW}Using default public RPC endpoints (no API key)${NC}"
        echo -e "${YELLOW}Note: For better reliability, set ALCHEMY_API_KEY environment variable${NC}"
    fi
    
    export SEPOLIA_RPC_URL
    export BASE_SEPOLIA_RPC_URL
}

# Check for required environment variables
check_env() {
    if [ -z "$PRIVATE_KEY" ]; then
        echo -e "${RED}Error: PRIVATE_KEY environment variable not set${NC}"
        exit 1
    fi
    
    # Build RPC URLs (from Alchemy key or defaults)
    build_rpc_urls
}

# Load deployment addresses from file
load_deployments() {
    if [ -f "$DEPLOYMENT_FILE" ]; then
        if command -v jq &> /dev/null; then
            echo -e "${BLUE}Loading deployment addresses from $DEPLOYMENT_FILE${NC}"
            source <(jq -r '.hub | to_entries[] | "export HUB_\(.key | ascii_upcase)=\(.value)"' "$DEPLOYMENT_FILE" 2>/dev/null)
            source <(jq -r '.spoke | to_entries[] | "export SPOKE_\(.key | ascii_upcase)=\(.value)"' "$DEPLOYMENT_FILE" 2>/dev/null)
        else
            echo -e "${YELLOW}Note: jq not found, skipping deployment file loading${NC}"
        fi
    fi
}

# Save deployment addresses to file
save_deployments() {
    echo -e "${BLUE}Saving deployment addresses to $DEPLOYMENT_FILE${NC}"
    mkdir -p "$(dirname "$DEPLOYMENT_FILE")"
    cat > "$DEPLOYMENT_FILE" <<EOF
{
  "hub": {
    "usdc": "$HUB_USDC",
    "yearnVault": "$HUB_YEARN_VAULT",
    "usdx": "$HUB_USDX",
    "vault": "$HUB_VAULT",
    "vaultWrapper": "$HUB_VAULT_WRAPPER",
    "shareAdapter": "$HUB_SHARE_ADAPTER",
    "composer": "$HUB_COMPOSER"
  },
  "spoke": {
    "usdx": "$SPOKE_USDX",
    "shareOFT": "$SPOKE_SHARE_OFT",
    "minter": "$SPOKE_MINTER"
  }
}
EOF
}

# Deploy Hub Chain (Ethereum Sepolia)
deploy_hub() {
    echo -e "\n${GREEN}=== Deploying Hub Chain (Ethereum Sepolia) ===${NC}\n"
    
    cd "$CONTRACTS_DIR"
    
    # Run deployment script
    forge script script/DeployAndDemo.s.sol:DeployAndDemo \
        --rpc-url "$SEPOLIA_RPC_URL" \
        --broadcast \
        --sig "runHub()" \
        -vvv
    
    # Extract addresses from broadcast output
    # Note: In production, you'd parse the broadcast JSON files
    echo -e "\n${YELLOW}Please save the deployed addresses shown above${NC}"
    echo -e "${YELLOW}Set them as environment variables:${NC}"
    echo -e "  export HUB_USDC=<address>"
    echo -e "  export HUB_YEARN_VAULT=<address>"
    echo -e "  export HUB_USDX=<address>"
    echo -e "  export HUB_VAULT=<address>"
    echo -e "  export HUB_VAULT_WRAPPER=<address>"
    echo -e "  export HUB_SHARE_ADAPTER=<address>"
    echo -e "  export HUB_COMPOSER=<address>"
}

# Deploy Spoke Chain (Base Sepolia)
deploy_spoke() {
    if [ -z "$HUB_USDX" ] || [ -z "$HUB_SHARE_ADAPTER" ] || [ -z "$HUB_COMPOSER" ]; then
        echo -e "${RED}Error: Hub chain addresses not set${NC}"
        echo -e "${YELLOW}Please set HUB_USDX, HUB_SHARE_ADAPTER, and HUB_COMPOSER environment variables${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}=== Deploying Spoke Chain (Base Sepolia) ===${NC}\n"
    echo -e "Hub USDX: $HUB_USDX"
    echo -e "Hub Share Adapter: $HUB_SHARE_ADAPTER"
    echo -e "Hub Composer: $HUB_COMPOSER\n"
    
    cd "$CONTRACTS_DIR"
    
    # Run deployment script
    forge script script/DeployAndDemo.s.sol:DeployAndDemo \
        --rpc-url "$BASE_SEPOLIA_RPC_URL" \
        --broadcast \
        --sig "runSpoke(address,address,address)" \
        "$HUB_USDX" "$HUB_SHARE_ADAPTER" "$HUB_COMPOSER" \
        -vvv
    
    # Extract addresses from broadcast output
    echo -e "\n${YELLOW}Please save the deployed addresses shown above${NC}"
    echo -e "${YELLOW}Set them as environment variables:${NC}"
    echo -e "  export SPOKE_USDX=<address>"
    echo -e "  export SPOKE_SHARE_OFT=<address>"
    echo -e "  export SPOKE_MINTER=<address>"
}

# Configure cross-chain connections
configure_crosschain() {
    echo -e "\n${GREEN}=== Configuring Cross-Chain Connections ===${NC}\n"
    
    if [ -z "$HUB_USDX" ] || [ -z "$SPOKE_USDX" ] || [ -z "$HUB_SHARE_ADAPTER" ] || [ -z "$SPOKE_SHARE_OFT" ]; then
        echo -e "${RED}Error: Required addresses not set${NC}"
        exit 1
    fi
    
    cd "$CONTRACTS_DIR"
    
    # Configure hub chain
    echo -e "${BLUE}Configuring Hub Chain...${NC}"
    forge script script/DeployAndDemo.s.sol:DeployAndDemo \
        --rpc-url "$SEPOLIA_RPC_URL" \
        --broadcast \
        --sig "configureCrossChain()" \
        -vvv
    
    echo -e "\n${GREEN}✓ Cross-chain configuration complete${NC}"
}

# Run demo
run_demo() {
    echo -e "\n${GREEN}=== Running Cross-Chain Demo ===${NC}\n"
    
    if [ -z "$HUB_USDX" ] || [ -z "$HUB_VAULT" ] || [ -z "$SPOKE_USDX" ] || [ -z "$SPOKE_MINTER" ]; then
        echo -e "${RED}Error: Required addresses not set${NC}"
        exit 1
    fi
    
    cd "$CONTRACTS_DIR"
    
    # Run demo on hub chain
    forge script script/DeployAndDemo.s.sol:DeployAndDemo \
        --rpc-url "$SEPOLIA_RPC_URL" \
        --broadcast \
        --sig "runDemo()" \
        -vvv
    
    echo -e "\n${GREEN}✓ Demo complete${NC}"
}

# Main menu
main() {
    check_env
    load_deployments
    
    echo -e "${BLUE}USDX Protocol - Deployment and Demo Script${NC}"
    echo -e "${BLUE}===========================================${NC}\n"
    
    echo "Select an option:"
    echo "1) Deploy Hub Chain (Ethereum Sepolia)"
    echo "2) Deploy Spoke Chain (Base Sepolia)"
    echo "3) Configure Cross-Chain Connections"
    echo "4) Run Demo"
    echo "5) Full Deployment (Hub + Spoke + Configure + Demo)"
    echo "6) Exit"
    
    read -p "Enter choice [1-6]: " choice
    
    case $choice in
        1)
            deploy_hub
            ;;
        2)
            deploy_spoke
            ;;
        3)
            configure_crosschain
            ;;
        4)
            run_demo
            ;;
        5)
            deploy_hub
            echo -e "\n${YELLOW}Press Enter to continue to spoke deployment...${NC}"
            read
            deploy_spoke
            echo -e "\n${YELLOW}Press Enter to configure cross-chain connections...${NC}"
            read
            configure_crosschain
            echo -e "\n${YELLOW}Press Enter to run demo...${NC}"
            read
            run_demo
            save_deployments
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
