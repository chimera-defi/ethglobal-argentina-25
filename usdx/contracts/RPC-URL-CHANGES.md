# RPC URL Changes - Alchemy Key Support

## Summary

Updated deployment scripts to accept an Alchemy API key instead of requiring full RPC URLs. Scripts now automatically build RPC URLs from the API key if provided, or use default public RPC endpoints.

## Changes Made

### 1. Shell Script (`scripts/deploy-and-demo.sh`)
- **Added:** `build_rpc_urls()` function that:
  - Checks for `ALCHEMY_API_KEY` environment variable
  - If set: Builds Alchemy RPC URLs:
    - `https://eth-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY`
    - `https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY`
  - If not set: Uses default public RPC endpoints:
    - `https://rpc.sepolia.org` (Ethereum Sepolia)
    - `https://sepolia.base.org` (Base Sepolia)
- **Removed:** Requirement for `SEPOLIA_RPC_URL` and `BASE_SEPOLIA_RPC_URL` environment variables
- **Updated:** `check_env()` now calls `build_rpc_urls()` instead of checking for RPC URLs

### 2. Documentation Updates

#### `DEPLOYMENT-SEPOLIA-BASE.md`
- Updated environment setup section to show `ALCHEMY_API_KEY` instead of RPC URLs
- Added note explaining default public RPC endpoints
- Updated all command examples to show Alchemy key usage or defaults

#### `DEPLOYMENT-SUMMARY.md`
- Updated environment variables section
- Updated quick start commands to show both shell script (recommended) and manual options
- Added notes about RPC URL handling

## Usage

### Option 1: With Alchemy API Key (Recommended)
```bash
export ALCHEMY_API_KEY=your_alchemy_api_key
export PRIVATE_KEY=0x...
./scripts/deploy-and-demo.sh
```

### Option 2: Without API Key (Uses Public RPC)
```bash
export PRIVATE_KEY=0x...
./scripts/deploy-and-demo.sh
# Script will use default public RPC endpoints
```

### Option 3: Manual Commands
```bash
# With Alchemy key
export ALCHEMY_API_KEY=your_key
export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY"
export BASE_SEPOLIA_RPC_URL="https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY"

# Or use defaults directly
forge script script/DeployAndDemo.s.sol:DeployAndDemo \
  --rpc-url https://rpc.sepolia.org \
  --broadcast \
  --sig "runHub()" \
  -vvv
```

## Benefits

1. **Simpler Setup:** Users only need to set `ALCHEMY_API_KEY` instead of building full URLs
2. **Better Defaults:** Works out of the box with public RPC endpoints
3. **Flexibility:** Users can still provide custom RPC URLs if needed
4. **Clear Messaging:** Script informs users which RPC endpoints are being used

## Backward Compatibility

- If `SEPOLIA_RPC_URL` and `BASE_SEPOLIA_RPC_URL` are already set, they will be used (though not required)
- Shell script exports these variables after building them, so they're available for manual forge commands
- Manual forge commands can still use `--rpc-url` with any endpoint

## Testing

The shell script now:
1. Checks for `PRIVATE_KEY` (required)
2. Builds RPC URLs from `ALCHEMY_API_KEY` or uses defaults
3. Exports `SEPOLIA_RPC_URL` and `BASE_SEPOLIA_RPC_URL` for use in forge commands
4. Provides clear feedback about which endpoints are being used
