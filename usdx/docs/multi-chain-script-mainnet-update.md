# Multi-Chain Script - Mainnet Fork Update

## Summary

Updated `start-multi-chain.sh` to fork **mainnet chains** instead of testnets, with Arc enabled by default and reliable default RPC URLs included.

## Key Changes

### 1. Mainnet Chains ✅

**Before**:
- Hub: Ethereum Sepolia (Chain ID: 11155111)
- Spoke Base: Base Sepolia (Chain ID: 84532)

**After**:
- Hub: Ethereum Mainnet (Chain ID: 1)
- Spoke Base: Base Mainnet (Chain ID: 8453)
- Spoke Arc: Arc Testnet (Chain ID: 5042002) - *Mainnet not available yet*

### 2. Arc Enabled by Default ✅

**Before**: `START_ARC=false` (opt-in)

**After**: `START_ARC=true` (default, opt-out with `START_ARC=false`)

### 3. Batteries Included RPC URLs ✅

All chains now have reliable default RPC URLs:

| Chain | Default RPC URL | Alternative |
|-------|----------------|-------------|
| Ethereum Mainnet | `https://eth.llamarpc.com` | `https://rpc.ankr.com/eth` |
| Base Mainnet | `https://mainnet.base.org` | `https://base.llamarpc.com` |
| Arc Testnet | `https://rpc.testnet.arc.network` | N/A |

### 4. Better User Experience ✅

- **No configuration needed** - just run `./start-multi-chain.sh`
- **All chains start by default** - Hub + Base + Arc
- **Reliable RPCs** - tested public endpoints
- **Clear messaging** - informative output about what's happening

## Usage

### Basic Usage (All Chains)

```bash
cd /workspace/usdx
./start-multi-chain.sh
```

This will start:
- ✅ Hub Chain (Ethereum Mainnet) on port 8545
- ✅ Spoke Base (Base Mainnet) on port 8546
- ✅ Spoke Arc (Arc Testnet) on port 8547

### Disable Arc Chain

```bash
START_ARC=false ./start-multi-chain.sh
```

### Custom RPC URLs

```bash
export HUB_RPC_URL="https://your-rpc-url.com"
export SPOKE_BASE_RPC_URL="https://your-base-rpc-url.com"
export SPOKE_ARC_RPC_URL="https://your-arc-rpc-url.com"
./start-multi-chain.sh
```

## Chain Configuration

| Chain | Port | Chain ID | Network | Default RPC |
|-------|------|----------|---------|-------------|
| Hub | 8545 | 1 | Ethereum Mainnet | `https://eth.llamarpc.com` |
| Spoke Base | 8546 | 8453 | Base Mainnet | `https://mainnet.base.org` |
| Spoke Arc | 8547 | 5042002 | Arc Testnet | `https://rpc.testnet.arc.network` |

## Why Mainnet Forks?

### Advantages

1. **Real Data**: Access to real mainnet contracts and state
2. **Better Testing**: Test against production-like environment
3. **Real Tokens**: Interact with real USDC, real contracts
4. **Production Ready**: Same environment as production

### Considerations

- **Slower Initial Sync**: First fork takes longer (downloading state)
- **Larger State**: Mainnet has more data than testnets
- **Rate Limits**: Some RPC providers have rate limits

## Default RPC Providers

### Ethereum Mainnet
- **Primary**: LlamaRPC (`https://eth.llamarpc.com`)
  - Reliable public endpoint
  - Good rate limits
  - Fast response times

### Base Mainnet
- **Primary**: Official Base RPC (`https://mainnet.base.org`)
  - Official endpoint
  - Reliable and fast
  - No API key needed

### Arc Testnet
- **Primary**: Official Arc RPC (`https://rpc.testnet.arc.network`)
  - Official endpoint
  - Testnet only (mainnet not available)

## Troubleshooting

### RPC Connection Issues

If default RPCs fail, try alternatives:

```bash
# Ethereum Mainnet alternatives
export HUB_RPC_URL="https://rpc.ankr.com/eth"
# or
export HUB_RPC_URL="https://eth-mainnet.public.blastapi.io"

# Base Mainnet alternatives
export SPOKE_BASE_RPC_URL="https://base.llamarpc.com"
```

### Slow Forking

If forking is slow:
1. Use a faster RPC provider (Alchemy, Infura with API key)
2. Fork from a specific block number (add `--fork-block-number` to anvil)
3. Use a local node if available

### Arc Chain Issues

If Arc chain fails:
- Set `START_ARC=false` to disable it
- Check Arc Testnet status
- Verify RPC endpoint is accessible

## Next Steps

1. ✅ Script updated to use mainnet forks
2. ✅ Arc enabled by default
3. ✅ Default RPCs configured
4. ⏳ Test with actual deployment
5. ⏳ Update documentation

---

**Date**: January 2025  
**Status**: ✅ Script updated - ready to use with mainnet forks
