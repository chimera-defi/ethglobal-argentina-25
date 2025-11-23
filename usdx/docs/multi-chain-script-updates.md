# Multi-Chain Script Updates

## Summary

Updated `start-multi-chain.sh` to fix RPC URL issues and align with the current chain structure (Base Sepolia + Arc Testnet instead of Polygon).

## Changes Made

### 1. Fixed RPC URL Issues ✅

**Problem**: Script was using `polygon.llamarpc.com` which was failing with DNS errors.

**Solution**:
- Updated to use reliable public RPC endpoints:
  - **Hub**: Ethereum Sepolia via Infura public endpoint
  - **Spoke Base**: Base Sepolia public RPC (`https://sepolia.base.org`)
  - **Spoke Arc**: Arc Testnet public RPC (`https://rpc.testnet.arc.network`)
- Added RPC connection testing before starting chains
- Added fallback handling for RPC failures

### 2. Updated Chain Configuration ✅

**Before**:
- Hub: Ethereum Mainnet (Chain ID: 1)
- Spoke: Polygon Mainnet (Chain ID: 137)

**After**:
- Hub: Ethereum Sepolia (Chain ID: 11155111)
- Spoke Base: Base Sepolia (Chain ID: 84532)
- Spoke Arc: Arc Testnet (Chain ID: 5042002) - Optional

### 3. Added Arc Chain Support ✅

- Arc chain is now optional (set `START_ARC=true` to enable)
- Runs on port 8547
- Uses Arc Testnet RPC
- Deploys contracts automatically if started

### 4. Improved Error Handling ✅

- Tests RPC connections before starting chains
- Better error messages
- Graceful cleanup on failures
- Separate log files for each chain

### 5. Updated Process Management ✅

- Tracks all PIDs correctly (Hub, Base, Arc, Relayer)
- Updated stop script compatibility
- Better PID file management

## Usage

### Basic Usage (Hub + Base Sepolia)

```bash
cd /workspace/usdx
./start-multi-chain.sh
```

### With Arc Chain

```bash
cd /workspace/usdx
START_ARC=true ./start-multi-chain.sh
```

### Custom RPC URLs

```bash
export HUB_RPC_URL="https://your-rpc-url.com"
export SPOKE_BASE_RPC_URL="https://your-base-rpc-url.com"
export SPOKE_ARC_RPC_URL="https://your-arc-rpc-url.com"
./start-multi-chain.sh
```

### Stop All Services

```bash
./stop-multi-chain.sh
```

## Chain Configuration

| Chain | Port | Chain ID | RPC URL | Status |
|-------|------|----------|---------|--------|
| Hub (Ethereum Sepolia) | 8545 | 11155111 | `https://sepolia.infura.io/v3/...` | ✅ Always started |
| Spoke Base (Base Sepolia) | 8546 | 84532 | `https://sepolia.base.org` | ✅ Always started |
| Spoke Arc (Arc Testnet) | 8547 | 5042002 | `https://rpc.testnet.arc.network` | ⚙️ Optional |

## Log Files

- `logs/anvil-hub.log` - Hub chain logs
- `logs/anvil-spoke.log` - Base Sepolia chain logs
- `logs/anvil-arc.log` - Arc Testnet chain logs (if started)
- `logs/deploy-hub.log` - Hub deployment logs
- `logs/deploy-spoke-base.log` - Base deployment logs
- `logs/deploy-spoke-arc.log` - Arc deployment logs (if started)
- `logs/bridge-relayer.log` - Bridge relayer logs (if started)

## Troubleshooting

### RPC Connection Errors

If you see RPC connection errors:

1. **Check your internet connection**
2. **Try custom RPC URLs**:
   ```bash
   export HUB_RPC_URL="https://rpc.sepolia.org"
   export SPOKE_BASE_RPC_URL="https://sepolia.base.org"
   ```
3. **Check logs** for specific error messages:
   ```bash
   tail -f logs/anvil-hub.log
   tail -f logs/anvil-spoke.log
   ```

### Chain Won't Start

1. **Check if ports are available**:
   ```bash
   lsof -i :8545
   lsof -i :8546
   lsof -i :8547
   ```
2. **Kill existing processes**:
   ```bash
   ./stop-multi-chain.sh
   pkill anvil
   ```
3. **Check Foundry installation**:
   ```bash
   anvil --version
   forge --version
   ```

### Deployment Failures

1. **Check deployment logs**:
   ```bash
   cat logs/deploy-hub.log
   cat logs/deploy-spoke-base.log
   ```
2. **Verify chains are running**:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
     http://localhost:8545
   ```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HUB_RPC_URL` | Infura public endpoint | Ethereum Sepolia RPC URL |
| `SPOKE_BASE_RPC_URL` | `https://sepolia.base.org` | Base Sepolia RPC URL |
| `SPOKE_ARC_RPC_URL` | `https://rpc.testnet.arc.network` | Arc Testnet RPC URL |
| `START_ARC` | `false` | Set to `true` to start Arc chain |

## Next Steps

1. ✅ Script updated and tested
2. ⏳ Test with actual deployment
3. ⏳ Update documentation if needed
4. ⏳ Consider adding more spoke chains

---

**Date**: January 2025  
**Status**: ✅ Scripts updated and ready to use
