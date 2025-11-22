# USDX Frontend Setup & Running Guide

Complete guide to getting the USDX frontend running locally with forked mainnet.

## Architecture Overview

```
Frontend (Next.js + ethers.js)
    ↓
Anvil (Forked Ethereum Mainnet on localhost:8545)
    ↓
Deployed Contracts:
- MockUSDC: 0x1687d4BDE380019748605231C956335a473Fd3dc
- HubVault: 0x18903fF6E49c98615Ab741aE33b5CD202Ccc0158
- HubUSDX: 0xF1a7a5060f22edA40b1A94a858995fa2bcf5E75A
- SpokeUSDX: 0xFb314854baCb329200778B82cb816CFB6500De9D
- SpokeMinter: 0x18eed2c26276A42c70E064D25d4f773c3626478e
```

## Step-by-Step Setup

### Step 1: Start Anvil (Forked Mainnet)

Open a terminal and start Anvil with a forked Ethereum mainnet:

```bash
cd /workspace/usdx/contracts

# Start Anvil forking Ethereum mainnet
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY

# OR use Infura:
# anvil --fork-url https://mainnet.infura.io/v3/YOUR_API_KEY

# OR use any other Ethereum RPC
```

**Expected Output:**
```
Available Accounts:
==================
(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.000000000000000000 ETH)
(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000.000000000000000000 ETH)
...

Private Keys:
==================
(0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
...

Listening on 127.0.0.1:8545
```

**Keep this terminal running!**

### Step 2: Deploy Contracts

Open a **new terminal** and deploy contracts to the local network:

```bash
cd /workspace/usdx/contracts

# Make sure .env has the test private key
source .env

# Deploy all contracts
forge script script/DeployForked.s.sol:DeployForked \
  --fork-url http://localhost:8545 \
  --broadcast
```

**Expected Output:**
```
== Logs ==
=== USDX Deployment to Forked Network ===

1. Deploying Mock Contracts...
Mock USDC deployed: 0x1687d4BDE380019748605231C956335a473Fd3dc
Mock Yearn Vault deployed: 0x9f3F78951bBf68fc3cBA976f1370a87B0Fc13cd4

2. Deploying Hub Chain Contracts...
Hub USDX Token deployed: 0xF1a7a5060f22edA40b1A94a858995fa2bcf5E75A
Hub Vault deployed: 0x18903fF6E49c98615Ab741aE33b5CD202Ccc0158

3. Deploying Spoke Chain Contracts...
Spoke USDX Token deployed: 0xFb314854baCb329200778B82cb816CFB6500De9D
Spoke Minter deployed: 0x18eed2c26276A42c70E064D25d4f773c3626478e

4. Minting 1,000,000 USDC to deployer...
Done!
```

**Contract addresses are also saved to:** `/workspace/usdx/contracts/deployments/forked-local.json`

### Step 3: Configure MetaMask

Add a custom network to MetaMask:

1. Open MetaMask
2. Click network dropdown → "Add Network" → "Add a network manually"
3. Enter the following:
   - **Network Name**: `Localhost 8545`
   - **New RPC URL**: `http://localhost:8545`
   - **Chain ID**: `1` (or `31337` if Anvil uses that)
   - **Currency Symbol**: `ETH`
4. Click "Save"

### Step 4: Import Test Account

Import the Foundry test account (which has 1M USDC minted):

1. Open MetaMask
2. Click account icon → "Import Account"
3. Select "Private Key"
4. Paste: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
5. Click "Import"

**Account Address:** `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`

### Step 5: Start Frontend

Open a **new terminal** and start the Next.js dev server:

```bash
cd /workspace/usdx/frontend

# Install dependencies (if not already done)
npm install

# Start dev server
npm run dev
```

**Expected Output:**
```
  ▲ Next.js 14.2.33
  - Local:        http://localhost:3000
  - Environments: .env.local

 ✓ Ready in 2.3s
```

### Step 6: Open in Browser

1. Navigate to: **http://localhost:3000**
2. Click **"Connect Wallet"**
3. Approve MetaMask connection
4. You should see your balances:
   - **USDC**: 1,000,000.000000
   - **USDX (Hub)**: 0.000000
   - **USDX (Spoke)**: 0.000000

## Testing the Flows

### Test 1: Deposit USDC → Mint USDX

1. In the "Deposit USDC → Mint USDX" card:
2. Enter amount: `100`
3. Click **"Deposit & Mint"**
4. Approve USDC spending (MetaMask transaction 1)
5. Confirm deposit (MetaMask transaction 2)
6. Wait for transactions to complete
7. **Expected Result**: 
   - USDC balance decreases by 100
   - USDX (Hub) balance increases by 100

### Test 2: Withdraw USDX → Get USDC

1. In the "Burn USDX → Withdraw USDC" card:
2. Enter amount: `50`
3. Click **"Burn & Withdraw"**
4. Approve USDX burning (MetaMask transaction 1)
5. Confirm withdrawal (MetaMask transaction 2)
6. Wait for transactions to complete
7. **Expected Result**:
   - USDX (Hub) balance decreases by 50
   - USDC balance increases by ~50 (plus any yield)

### Test 3: Check Balances

- Balances auto-refresh every 10 seconds
- Manual refresh: reload the page
- All balances are displayed with 6 decimals (matching USDC/USDX)

## Troubleshooting

### Issue: "No Ethereum wallet found"
**Solution**: Install MetaMask browser extension

### Issue: "Wrong network"
**Solution**: 
- Click "Switch Network" button in app
- Or manually switch to "Localhost 8545" in MetaMask

### Issue: "Transaction failed"
**Solutions**:
1. Check Anvil is still running
2. Check contracts were deployed successfully
3. Reset MetaMask account: Settings → Advanced → Reset Account
4. Check you have enough USDC balance

### Issue: "Cannot connect to localhost:8545"
**Solutions**:
1. Verify Anvil is running: `curl http://localhost:8545`
2. Restart Anvil
3. Redeploy contracts

### Issue: "Balance is 0"
**Solutions**:
1. Make sure you imported the correct test account
2. Check deployment logs show "Minting 1,000,000 USDC"
3. Redeploy contracts

### Issue: Build errors
**Solutions**:
```bash
cd /workspace/usdx/frontend
rm -rf .next node_modules
npm install
npm run build
```

## Architecture Details

### Frontend Stack

- **Next.js 14**: App Router, React Server Components
- **ethers.js v6**: Contract interactions, wallet connection
- **Tailwind CSS**: Styling
- **TypeScript**: Type safety

### Key Files

```
frontend/src/
├── app/
│   ├── page.tsx              # Main UI
│   ├── layout.tsx            # Root layout
│   └── globals.css           # Global styles
├── components/
│   ├── WalletConnect.tsx     # Wallet connection button
│   ├── BalanceCard.tsx       # Balance display
│   ├── DepositFlow.tsx       # Deposit UI + logic
│   └── WithdrawFlow.tsx      # Withdraw UI + logic
├── hooks/
│   ├── useWallet.ts          # Wallet state management
│   └── useBalances.ts        # Balance fetching
├── lib/
│   ├── ethers.ts             # ethers.js utilities
│   └── contracts.ts          # Contract instances
├── config/
│   └── contracts.ts          # Contract addresses
└── abis/
    ├── USDXToken.json        # USDX ABI
    ├── USDXVault.json        # Vault ABI
    ├── USDXSpokeMinter.json  # SpokeMinter ABI
    └── MockUSDC.json         # USDC ABI
```

### Contract Interactions

**Deposit Flow:**
```typescript
1. usdc.approve(VAULT_ADDRESS, amount)
2. vault.deposit(amount)
   → Vault transfers USDC from user
   → Vault deposits to Yearn
   → Vault mints USDX to user
```

**Withdraw Flow:**
```typescript
1. usdx.approve(VAULT_ADDRESS, amount)
2. vault.withdraw(amount)
   → Vault burns USDX from user
   → Vault withdraws from Yearn
   → Vault transfers USDC to user
```

## Development Notes

### Hot Reload
- Frontend: Automatic with Next.js dev server
- Contracts: Need to redeploy after changes

### Redeploying Contracts
```bash
# Stop Anvil (Ctrl+C)
# Restart Anvil
anvil --fork-url YOUR_RPC

# Redeploy
forge script script/DeployForked.s.sol:DeployForked \
  --fork-url http://localhost:8545 \
  --broadcast

# Refresh browser (frontend will reconnect)
```

### Debugging

**Contract events:**
```bash
# Watch Anvil logs for emitted events
# Deposits show: Deposited(user, amount)
# Withdrawals show: Withdrawn(user, amount)
```

**Frontend console:**
```javascript
// Open browser DevTools → Console
// Logs show transaction hashes and contract calls
```

**MetaMask:**
- View transaction history
- Check pending transactions
- Inspect transaction details

## Next Features to Build

1. **Spoke Chain Minting**: Allow minting USDX on "Polygon" (simulated)
2. **Circle Bridge Kit**: Integrate USDC bridging UI
3. **Yield Dashboard**: Show APY, total yield earned, vault stats
4. **Transaction History**: Show past deposits/withdrawals
5. **Admin Panel**: Manage yield distribution, pause contracts
6. **Multi-chain Support**: Real LayerZero/Hyperlane integration

## Security Notes

⚠️ **IMPORTANT**: 
- The private key used is a **well-known Foundry test key**
- **NEVER** use this key on real networks
- This setup is **for local development only**
- Do not commit private keys to git (already in .gitignore)

## Success Criteria

✅ **Everything is working if:**
- Anvil runs without errors
- Contracts deploy successfully
- Frontend builds without errors
- Wallet connects to localhost:8545
- Balances show correctly
- Deposit transaction completes
- Withdraw transaction completes
- Balance updates reflect changes

## Support

If you encounter issues:
1. Check all 3 terminals are running (Anvil, deployment done, frontend)
2. Check MetaMask is on correct network
3. Check transaction history in MetaMask
4. Check Anvil logs for errors
5. Check browser console for errors
6. Try resetting MetaMask account

---

**Congratulations!** 🎉 You now have a fully functional USDX Protocol frontend running locally!
