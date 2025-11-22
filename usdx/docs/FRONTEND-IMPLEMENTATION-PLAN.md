# USDX Frontend Implementation Plan

**Date**: 2025-11-22  
**Stack**: Next.js 14 + TypeScript + ethers.js + Circle Bridge Kit  
**Status**: Ready to implement

---

## 🎯 Overview

Building a modern frontend for USDX Protocol with:
- **ethers.js** for wallet connection and contract interactions (per user request)
- **Circle Bridge Kit** for USDC cross-chain transfers
- **Next.js 14** with App Router
- **TypeScript** for type safety
- **Tailwind CSS** for styling

---

## 🔧 Technical Stack

### Core Dependencies:
```json
{
  "ethers": "^6.13.0",           // Wallet & contract interactions
  "@circle-fin/bridge-kit": "latest",    // USDC bridging
  "@circle-fin/adapter-viem-v2": "latest", // Bridge Kit requires viem
  "viem": "^2.x",                 // Required by Bridge Kit
  "next": "14.2.x",               // Framework
  "react": "^18",                 // UI
  "typescript": "^5",             // Type safety
  "tailwindcss": "^3"             // Styling
}
```

### Important Notes:
1. **ethers.js** - Main library for contract interactions (user preference)
2. **Circle Bridge Kit** - Uses viem internally, we'll use both:
   - ethers.js for our contracts
   - viem for Bridge Kit (isolated)
3. **No wagmi** - Using ethers.js directly per user request

---

## 📦 Dependencies Analysis

### Circle Bridge Kit Requirements:
Based on documentation, Bridge Kit requires:
- `@circle-fin/bridge-kit` - Main SDK
- `@circle-fin/adapter-viem-v2` - Viem adapter
- `viem` - Blockchain interactions (Bridge Kit uses this)

### Our Approach:
1. **ethers.js** - For USDX contract interactions
2. **viem** - Only for Bridge Kit (isolated usage)
3. **Bridge between ethers & viem** - Convert when needed

---

## 🏗️ Architecture

### File Structure:
```
frontend/
├── src/
│   ├── app/                    # Next.js 14 App Router
│   │   ├── page.tsx            # Home page
│   │   ├── layout.tsx          # Root layout
│   │   └── globals.css         # Global styles
│   ├── components/             # React components
│   │   ├── WalletConnect.tsx   # Wallet connection (ethers)
│   │   ├── DepositFlow.tsx     # USDC deposit
│   │   ├── WithdrawFlow.tsx    # USDC withdrawal
│   │   ├── MintFlow.tsx        # Spoke minting
│   │   ├── BridgeFlow.tsx      # Circle Bridge Kit
│   │   └── Dashboard.tsx       # User dashboard
│   ├── lib/                    # Utilities
│   │   ├── ethers.ts           # Ethers setup
│   │   ├── contracts.ts        # Contract instances
│   │   ├── bridgeKit.ts        # Bridge Kit setup
│   │   └── utils.ts            # Helpers
│   ├── hooks/                  # Custom React hooks
│   │   ├── useWallet.ts        # Wallet hook (ethers)
│   │   ├── useContract.ts      # Contract hook (ethers)
│   │   └── useBridgeKit.ts     # Bridge Kit hook
│   ├── types/                  # TypeScript types
│   │   ├── contracts.ts        # Contract types
│   │   └── index.ts            # Global types
│   └── config/                 # Configuration
│       ├── contracts.ts        # Contract addresses & ABIs
│       └── chains.ts           # Chain configurations
├── public/                     # Static assets
└── package.json                # Dependencies
```

---

## 🔌 Integration Strategy

### ethers.js + Circle Bridge Kit

**Problem**: Circle Bridge Kit uses viem, user wants ethers.js

**Solution**: Use both, but isolated:

```typescript
// For USDX contracts - ethers.js
import { ethers } from 'ethers';

const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();
const vaultContract = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, signer);

// For Circle Bridge Kit - viem
import { createPublicClient, createWalletClient } from 'viem';
import { BridgeKit } from '@circle-fin/bridge-kit';

const bridgeKit = new BridgeKit({
  adapter: createViemAdapter({
    sourcePublicClient: /* viem client */,
    sourceWalletClient: /* viem wallet */,
  })
});
```

### Bridge Between ethers & viem

```typescript
// Helper to convert ethers signer to viem account
function ethersSignerToViemAccount(signer: Signer) {
  return {
    address: await signer.getAddress(),
    signMessage: async ({ message }) => signer.signMessage(message),
    signTransaction: async (tx) => signer.signTransaction(tx),
  };
}
```

---

## 📋 Implementation Phases

### Phase 1: Basic Setup ✅ (We'll do this now)
- [x] Initialize project structure
- [ ] Install dependencies (ethers + Bridge Kit + viem)
- [ ] Setup TypeScript config
- [ ] Configure Tailwind CSS
- [ ] Create basic layout

### Phase 2: Wallet Integration (ethers.js)
- [ ] Build wallet connection component
- [ ] Implement ethers.js provider setup
- [ ] Add network switching
- [ ] Create wallet context/hooks
- [ ] Add account display

### Phase 3: Contract Integration (ethers.js)
- [ ] Import contract ABIs
- [ ] Setup contract instances
- [ ] Create contract hooks
- [ ] Add balance displays
- [ ] Implement allowance checks

### Phase 4: Core Flows
- [ ] **Deposit Flow**: USDC → Hub Vault
- [ ] **Withdraw Flow**: Burn USDX → Get USDC
- [ ] **Mint Flow**: Hub position → Spoke USDX
- [ ] **Bridge Flow**: Circle Bridge Kit integration

### Phase 5: Circle Bridge Kit Integration
- [ ] Setup viem clients (isolated)
- [ ] Initialize Bridge Kit
- [ ] Build bridge UI
- [ ] Handle transfer status
- [ ] Error handling

### Phase 6: UI/UX Polish
- [ ] Loading states
- [ ] Error messages
- [ ] Transaction confirmations
- [ ] Success notifications
- [ ] Responsive design

---

## 🔑 Key Components

### 1. Wallet Connection (ethers.js)

```typescript
// components/WalletConnect.tsx
import { ethers } from 'ethers';

export function WalletConnect() {
  const [address, setAddress] = useState<string>();
  const [provider, setProvider] = useState<ethers.BrowserProvider>();

  const connect = async () => {
    if (!window.ethereum) throw new Error('No wallet found');
    
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const address = await signer.getAddress();
    
    setProvider(provider);
    setAddress(address);
  };

  return (
    <button onClick={connect}>
      {address ? `Connected: ${address.slice(0,6)}...` : 'Connect Wallet'}
    </button>
  );
}
```

### 2. Contract Interaction (ethers.js)

```typescript
// lib/contracts.ts
import { ethers } from 'ethers';
import VaultABI from './abis/USDXVault.json';

export function getVaultContract(
  provider: ethers.Provider | ethers.Signer
) {
  return new ethers.Contract(
    VAULT_ADDRESS,
    VaultABI.abi,
    provider
  );
}

// Usage
const vault = getVaultContract(signer);
const tx = await vault.deposit(amount);
await tx.wait();
```

### 3. Circle Bridge Kit (viem)

```typescript
// lib/bridgeKit.ts
import { BridgeKit } from '@circle-fin/bridge-kit';
import { createViemAdapter } from '@circle-fin/adapter-viem-v2';
import { createPublicClient, createWalletClient, http } from 'viem';
import { mainnet, polygon } from 'viem/chains';

export function createBridgeKit(walletClient: WalletClient) {
  return new BridgeKit({
    adapter: createViemAdapter({
      sourcePublicClient: createPublicClient({
        chain: mainnet,
        transport: http(),
      }),
      sourceWalletClient: walletClient,
      destinationPublicClient: createPublicClient({
        chain: polygon,
        transport: http(),
      }),
    }),
  });
}
```

### 4. Deposit Flow

```typescript
// components/DepositFlow.tsx
export function DepositFlow() {
  const { signer } = useWallet();
  
  const deposit = async (amount: string) => {
    // 1. Get contracts
    const usdc = getUSDCContract(signer);
    const vault = getVaultContract(signer);
    
    // 2. Approve USDC
    const approveTx = await usdc.approve(vault.address, amount);
    await approveTx.wait();
    
    // 3. Deposit
    const depositTx = await vault.deposit(amount);
    await depositTx.wait();
    
    // 4. Success!
  };
  
  return <form onSubmit={() => deposit(amount)}>...</form>;
}
```

---

## 🔄 User Flows

### Flow 1: Deposit USDC on Hub
```
User → Connect Wallet (ethers) 
     → Approve USDC (ethers contract call)
     → Deposit to Vault (ethers contract call)
     → Receive USDX (auto-minted)
```

### Flow 2: Bridge USDC (Circle Bridge Kit)
```
User → Select source/destination chains
     → Enter amount
     → Bridge Kit transfer (viem internally)
     → Track status
     → Complete!
```

### Flow 3: Mint on Spoke
```
User → Check hub position (ethers view call)
     → Enter mint amount
     → Mint USDX on spoke (ethers contract call)
     → Receive spoke USDX
```

### Flow 4: Withdraw
```
User → Approve USDX burning (ethers)
     → Withdraw from vault (ethers contract call)
     → Receive USDC back
```

---

## 📊 Contract Addresses (from forked deployment)

```typescript
// config/contracts.ts
export const CONTRACTS = {
  // Forked Mainnet (localhost:8545)
  MOCK_USDC: '0x1687d4BDE380019748605231C956335a473Fd3dc',
  HUB_USDX: '0xF1a7a5060f22edA40b1A94a858995fa2bcf5E75A',
  HUB_VAULT: '0x18903fF6E49c98615Ab741aE33b5CD202Ccc0158',
  SPOKE_USDX: '0xFb314854baCb329200778B82cb816CFB6500De9D',
  SPOKE_MINTER: '0x18eed2c26276A42c70E064D25d4f773c3626478e',
};

export const DEPLOYER = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
```

---

## 🧪 Testing Strategy

### Local Testing (Forked Network):
1. Start Anvil: `anvil --fork-url <RPC>`
2. Deploy contracts: `forge script script/DeployForked.s.sol --broadcast`
3. Start frontend: `npm run dev`
4. Connect to `http://localhost:8545`

### Test Scenarios:
- ✅ Connect wallet
- ✅ Display balances
- ✅ Approve USDC
- ✅ Deposit USDC
- ✅ Withdraw USDC
- ✅ Mint on spoke
- ✅ Bridge USDC (Bridge Kit)

---

## 🎨 UI/UX Considerations

### Design Principles:
1. **Simple & Clean** - Focus on core flows
2. **Clear Status** - Always show what's happening
3. **Error Handling** - Friendly error messages
4. **Loading States** - Visual feedback for transactions
5. **Responsive** - Works on mobile

### Component Library:
- Custom components (no heavy UI library for MVP)
- Tailwind CSS for styling
- Headless UI for modals/dropdowns (if needed)

---

## 📝 Next Steps (Immediate)

1. **Install Dependencies**
   ```bash
   cd frontend
   npm install ethers@6 @circle-fin/bridge-kit @circle-fin/adapter-viem-v2 viem@2
   ```

2. **Extract ABIs**
   ```bash
   # Copy from contracts/out/
   ```

3. **Create Basic Components**
   - WalletConnect
   - Dashboard
   - DepositFlow

4. **Test Locally**
   - Connect to forked network
   - Test deposit flow

---

## ⚠️ Important Notes

### ethers.js + viem Coexistence:
- **ethers.js**: Primary library for our contracts
- **viem**: Only for Bridge Kit (isolated usage)
- **No conflict**: They can coexist, just keep separate

### Circle Bridge Kit:
- Uses viem internally (can't change)
- We wrap it in our own hooks
- Convert ethers signer to viem account when needed

### Forked Network:
- Chain ID: 1 (Ethereum)
- RPC: http://localhost:8545
- Test account with 1M USDC pre-minted

---

## 🚀 Success Criteria

- [ ] Wallet connects with ethers.js
- [ ] Can see USDC and USDX balances
- [ ] Can deposit USDC → mint USDX
- [ ] Can withdraw USDX → get USDC
- [ ] Can mint USDX on spoke
- [ ] Circle Bridge Kit integration works
- [ ] All flows tested end-to-end
- [ ] Error handling works
- [ ] UI is responsive

---

**Ready to build!** 🚀

Let's start with installing dependencies and setting up the basic structure.
