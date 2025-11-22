# Multi-Chain Local Setup for USDX Protocol

## Architecture

```
┌─────────────────────────────────────────┐
│  Anvil #1 - Hub Chain (Ethereum Fork)  │
│  Port: 8545                             │
│  Chain ID: 1                            │
│                                         │
│  Contracts:                             │
│  - MockUSDC                             │
│  - MockYearnVault                       │
│  - HubUSDX Token                        │
│  - HubVault                             │
│  - CrossChainMessenger (bridge sim)    │
└─────────────────────────────────────────┘
                    ↕
          (Manual bridge for MVP)
          (LayerZero/Hyperlane later)
                    ↕
┌─────────────────────────────────────────┐
│  Anvil #2 - Spoke Chain (Polygon Fork) │
│  Port: 8546                             │
│  Chain ID: 137                          │
│                                         │
│  Contracts:                             │
│  - SpokeUSDX Token                      │
│  - SpokeMinter                          │
│  - CrossChainMessenger (bridge sim)    │
└─────────────────────────────────────────┘
```

## User Flow

1. **Bridge USDC** (Circle Bridge Kit)
   - User has USDC on any chain
   - Use Bridge Kit UI to bridge to Ethereum (hub)
   
2. **Deposit on Hub** (Ethereum)
   - Deposit USDC to HubVault
   - Vault deposits to Yearn
   - Receive HubUSDX 1:1
   
3. **Mint on Spoke** (Polygon)
   - Switch to Polygon network in wallet
   - Position oracle syncs your hub balance
   - Mint SpokeUSDX based on hub position
   
4. **Use USDX** (Polygon)
   - Transfer SpokeUSDX to anyone
   - Use in DeFi protocols
   - Lower gas fees than Ethereum

## Setup Instructions

### Terminal 1: Hub Chain (Ethereum)

```bash
cd /workspace/usdx/contracts

# Start Anvil forking Ethereum mainnet
anvil \
  --port 8545 \
  --chain-id 1 \
  --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY \
  --block-time 2
```

### Terminal 2: Spoke Chain (Polygon)

```bash
cd /workspace/usdx/contracts

# Start Anvil forking Polygon mainnet
anvil \
  --port 8546 \
  --chain-id 137 \
  --fork-url https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY \
  --block-time 2
```

### Terminal 3: Deploy Hub Contracts

```bash
cd /workspace/usdx/contracts

# Deploy to hub chain (port 8545)
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Terminal 4: Deploy Spoke Contracts

```bash
cd /workspace/usdx/contracts

# Deploy to spoke chain (port 8546)
forge script script/DeploySpoke.s.sol:DeploySpoke \
  --rpc-url http://localhost:8546 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Terminal 5: Start Bridge Relayer (simulates cross-chain messaging)

```bash
cd /workspace/usdx/contracts

# Run the bridge relayer that syncs positions from hub to spoke
node script/bridge-relayer.js
```

### Terminal 6: Start Frontend

```bash
cd /workspace/usdx/frontend
npm run dev
```

## MetaMask Configuration

### Add Hub Network (Ethereum Fork)

- Network Name: `USDX Hub (Ethereum)`
- RPC URL: `http://localhost:8545`
- Chain ID: `1`
- Currency: `ETH`

### Add Spoke Network (Polygon Fork)

- Network Name: `USDX Spoke (Polygon)`
- RPC URL: `http://localhost:8546`
- Chain ID: `137`
- Currency: `MATIC`

## Testing Flow

### 1. Deposit on Hub (Ethereum)

1. Connect wallet to `USDX Hub (Ethereum)` (localhost:8545)
2. Deposit 100 USDC
3. Receive 100 HubUSDX
4. Your position is recorded in HubVault

### 2. Sync Position (Cross-Chain Message)

The bridge relayer automatically:
1. Watches for deposits on hub
2. Sends message to spoke chain
3. Updates user position in SpokeMinter

### 3. Mint on Spoke (Polygon)

1. Switch wallet to `USDX Spoke (Polygon)` (localhost:8546)
2. Click "Mint USDX on Polygon"
3. SpokeMinter checks your synced position
4. Mint SpokeUSDX (up to your hub balance)

### 4. Use USDX on Polygon

- Transfer to other users
- Low gas fees
- Fast transactions

### 5. Withdraw (Reverse Flow)

1. Burn SpokeUSDX on Polygon
2. Bridge relayer syncs burn event
3. Withdraw USDC from hub

## Bridge Relayer (MVP)

For the MVP, we use a simple Node.js script that:
- Listens to events on both chains
- Syncs positions from hub to spoke
- Simulates what LayerZero/Hyperlane will do in production

Later, this will be replaced with:
- **LayerZero OApp** for secure cross-chain messaging
- **Hyperlane ISM** for alternative cross-chain routing
- **Circle CCTP** for native USDC bridging

## Circle Bridge Kit Integration

The Bridge Kit is used **before** depositing to the hub:

```
User has USDC on Arbitrum
         ↓
Use Bridge Kit to bridge to Ethereum
         ↓
USDC arrives on Ethereum
         ↓
Deposit to HubVault
         ↓
Mint HubUSDX
         ↓
Sync position to Polygon
         ↓
Mint SpokeUSDX on Polygon
```

## Advantages of This Setup

✅ **True Multi-Chain** - Separate networks, separate state
✅ **Realistic Testing** - Mimics production architecture
✅ **Chain Switching** - Test wallet network changes
✅ **Gas Differences** - See actual gas costs per chain
✅ **Bridge Simulation** - Understand cross-chain flow
✅ **Production-Ready** - Easy to swap in real bridges later

## Limitations (MVP)

⚠️ Bridge relayer is centralized (will be replaced with LayerZero/Hyperlane)
⚠️ No actual CCTP integration yet (manual USDC bridging simulation)
⚠️ Same private key works on both chains (test key, not realistic)

## Next Steps

1. Run this multi-chain setup
2. Test deposit → sync → mint flow
3. Add Bridge Kit UI for USDC bridging
4. Replace bridge relayer with LayerZero
5. Deploy to real testnets (Sepolia + Mumbai)
