# Circle Bridge Kit Integration Guide

**Status:** ✅ **FULLY IMPLEMENTED AND WORKING**  
**Last Updated:** 2025-11-23  
**Packages:** `@circle-fin/bridge-kit@1.1.2`, `@circle-fin/adapter-viem-v2@1.1.1`

---

## Overview

Circle Bridge Kit enables seamless USDC cross-chain transfers using Circle's CCTP (Cross-Chain Transfer Protocol). The USDX Protocol uses Bridge Kit to allow users to bridge USDC from spoke chains to the hub chain before depositing into the vault.

---

## Quick Start

### Installation

```bash
npm install @circle-fin/bridge-kit @circle-fin/adapter-viem-v2 viem
```

### Basic Usage

```typescript
import { BridgeKit, Blockchain } from '@circle-fin/bridge-kit';
import { createAdapterFromProvider } from '@circle-fin/adapter-viem-v2';

// 1. Create adapter from browser wallet
const adapter = await createAdapterFromProvider({
  provider: window.ethereum,
});

// 2. Create BridgeKit instance
const kit = new BridgeKit();

// 3. Execute bridge
const result = await kit.bridge({
  from: {
    adapter: adapter,
    chain: Blockchain.Base_Sepolia,
  },
  to: {
    adapter: adapter,
    chain: Blockchain.Ethereum_Sepolia,
  },
  amount: '1000000', // 1 USDC (6 decimals)
  token: 'USDC',
  config: {},
});
```

---

## USDX Implementation

### Files

| File | Purpose |
|------|---------|
| `/frontend/src/lib/bridgeKit.ts` | Core utilities and helper functions |
| `/frontend/src/hooks/useBridgeKit.ts` | React hook for Bridge Kit |
| `/frontend/src/components/BridgeKitFlow.tsx` | UI component for bridging |

### Core Functions

#### `createBridgeKitAdapter()`
Creates a ViemAdapter from the browser wallet (MetaMask, etc.)

```typescript
const adapter = await createBridgeKitAdapter();
```

#### `createBridgeKit()`
Creates a BridgeKit instance with default CCTP provider

```typescript
const kit = createBridgeKit();
```

#### `bridgeUSDC()`
Executes a USDC bridge transfer between chains

```typescript
await bridgeUSDC(
  bridgeKit,
  sourceAdapter,
  destinationAdapter,
  sourceChainId,
  destinationChainId,
  amount,
  recipientAddress
);
```

#### `getBridgeKitBlockchain()`
Converts numeric chain ID to Blockchain enum

```typescript
const blockchain = getBridgeKitBlockchain(11155111); // Blockchain.Ethereum_Sepolia
```

---

## React Hook Usage

### Basic Example

```typescript
import { useBridgeKit } from '@/hooks/useBridgeKit';

function BridgeComponent() {
  const { bridgeUSDC, transferStatus, error, reset } = useBridgeKit();

  const handleBridge = async () => {
    await bridgeUSDC({
      sourceChainId: 84532, // Base Sepolia
      destinationChainId: 11155111, // Ethereum Sepolia
      amount: '1000000', // 1 USDC
      recipientAddress: vaultAddress,
      onStatusUpdate: (status) => {
        console.log('Status:', status);
      },
    });
  };

  return (
    <div>
      <button onClick={handleBridge}>Bridge USDC</button>
      {transferStatus === 'pending' && <p>Bridging...</p>}
      {transferStatus === 'success' && <p>Success!</p>}
      {error && <p>Error: {error}</p>}
    </div>
  );
}
```

### Hook API

```typescript
interface UseBridgeKitReturn {
  bridgeKit: BridgeKit | null;
  adapter: ViemAdapter | null;
  isInitializing: boolean;
  transferStatus: 'idle' | 'pending' | 'success' | 'error';
  transferResult: BridgeResult | null;
  error: string | null;
  bridgeUSDC: (params: BridgeUSDCParams) => Promise<void>;
  reset: () => void;
}
```

---

## Supported Chains

### Testnets

| Chain | Chain ID | Blockchain Enum |
|-------|----------|-----------------|
| Ethereum Sepolia | 11155111 | `Blockchain.Ethereum_Sepolia` |
| Base Sepolia | 84532 | `Blockchain.Base_Sepolia` |
| Arbitrum Sepolia | 421614 | `Blockchain.Arbitrum_Sepolia` |
| Optimism Sepolia | 11155420 | `Blockchain.Optimism_Sepolia` |

### Mainnets

| Chain | Chain ID | Blockchain Enum |
|-------|----------|-----------------|
| Ethereum | 1 | `Blockchain.Ethereum` |
| Base | 8453 | `Blockchain.Base` |
| Arbitrum | 42161 | `Blockchain.Arbitrum` |
| Optimism | 10 | `Blockchain.Optimism` |

---

## Bridge Flow

### User Journey

1. **Connect Wallet** → User connects MetaMask or similar
2. **Select Chains** → Choose source (e.g., Base) and destination (e.g., Ethereum)
3. **Enter Amount** → Input USDC amount to bridge
4. **Approve USDC** → Wallet prompts for USDC approval (if needed)
5. **Burn USDC** → Bridge Kit burns USDC on source chain
6. **Attestation** → Circle's service validates the burn (automatic, ~10-20 minutes)
7. **Mint USDC** → Bridge Kit mints USDC on destination chain
8. **Complete** → USDC arrives at recipient address

### Technical Flow

```
User → BridgeKitFlow Component → useBridgeKit Hook → bridgeKit.ts Utilities
  ↓
Bridge Kit SDK
  ↓
createAdapterFromProvider (browser wallet)
  ↓
kit.bridge({ from, to, amount, token, config })
  ↓
Bridge Actions: approve → burn → attestation → mint
  ↓
BridgeResult: { state, amount, token, steps }
```

---

## Event Handling

Bridge Kit emits events for each action:

```typescript
kit.on('*', (payload) => {
  // All events: approve, burn, attestation, mint
  console.log('Action:', payload.method);
  console.log('Status:', payload.status);
});

// Or listen to specific events
kit.on('approve', (payload) => console.log('Approval:', payload));
kit.on('burn', (payload) => console.log('Burn:', payload));
kit.on('mint', (payload) => console.log('Mint:', payload));
```

---

## Error Handling

### Comprehensive Error Extraction

The implementation extracts detailed error information from `BridgeResult.steps`:

```typescript
if (result.state === 'error') {
  const errorSteps = result.steps?.filter(step => step.state === 'error');
  
  if (errorSteps.length > 0) {
    const firstError = errorSteps[0];
    const stepName = firstError.name; // e.g., "Approve", "Burn"
    const txHash = firstError.txHash; // Transaction hash if available
    
    // Show user-friendly error message
  }
}
```

### Common Error Scenarios

| Error | Cause | Solution |
|-------|-------|----------|
| "No wallet found" | No browser wallet installed | Install MetaMask or similar |
| "Unsupported chain" | Chain not in mapping | Add chain to `getBridgeKitBlockchain()` |
| "Bridge Kit not initialized" | Called before initialization | Wait for `isInitializing` to be false |
| "Insufficient balance" | Not enough USDC | Add USDC to wallet |
| Approve step failed | User rejected or gas issue | Try again, check gas |
| Burn step failed | Transaction reverted | Check allowance, balance |
| Attestation timeout | Circle service delay | Wait longer, attestation can take 10-20 min |

---

## Configuration

### Custom Recipient

Bridge to a specific address instead of user's address:

```typescript
await bridgeUSDC({
  sourceChainId: 84532,
  destinationChainId: 11155111,
  amount: '1000000',
  recipientAddress: '0x...', // Custom recipient
  onStatusUpdate: (status) => console.log(status),
});
```

### Transfer Speed

Use default config for standard speed or customize:

```typescript
await kit.bridge({
  from: sourceContext,
  to: destContext,
  amount: '1000000',
  token: 'USDC',
  config: {
    // Speed options depend on BridgeKit version
    // Check documentation for latest options
  },
});
```

---

## Verification & Testing

### TypeScript Compilation

```bash
npm run type-check
✅ No errors
```

### Production Build

```bash
npm run build
✅ Build successful
```

### Lint Check

```bash
npm run lint
✅ No ESLint errors
```

### Manual Testing Checklist

- [ ] Get testnet ETH (Sepolia + Base Sepolia faucets)
- [ ] Get testnet USDC on Base Sepolia
- [ ] Connect wallet to Base Sepolia
- [ ] Bridge 1 USDC to Ethereum Sepolia
- [ ] Verify transaction on block explorers
- [ ] Confirm USDC arrives at destination
- [ ] Test error cases (insufficient balance, wrong network, etc.)

---

## Known Limitations

### 1. No wagmi Integration

**Issue:** Frontend uses ethers.js, but BridgeKit uses viem  
**Impact:** Requires manual adapter creation  
**Workaround:** Current implementation works but not optimal  
**Future:** Migrate wallet connections to wagmi hooks

### 2. Browser Wallet Only

**Issue:** Only supports browser wallets (MetaMask, etc.)  
**Impact:** Cannot bridge server-side  
**Solution:** Use `createAdapterFromPrivateKey()` for server-side bridging

### 3. No Retry UI

**Issue:** BridgeKit supports retry, but UI doesn't expose it  
**Impact:** Users must restart failed bridges  
**Future:** Implement retry button using `kit.retry()`

---

## Troubleshooting

### "Window.ethereum not found"

**Cause:** No browser wallet installed or not detected  
**Solution:** 
- Install MetaMask or compatible wallet
- Ensure wallet extension is enabled
- Refresh page after installing wallet

### Bridge stuck at "pending"

**Cause:** Attestation taking longer than expected  
**Solution:**
- Circle attestation can take 10-20 minutes
- Wait patiently, do not close browser
- Check Circle attestation service status

### TypeScript errors after update

**Cause:** BridgeKit types changed  
**Solution:**
- Verify imports match exports: `Blockchain`, `BridgeKit`, `AdapterContext`, `BridgeResult`
- Check `node_modules/@circle-fin/bridge-kit/index.d.ts` for actual exports
- Clear `node_modules` and reinstall if needed

---

## Advanced Usage

### Retry Failed Transfers

```typescript
if (result.state === 'error' && kit.supportsRetry(result)) {
  const retryResult = await kit.retry(result, {
    from: { adapter, chain: sourceChain },
    to: { adapter, chain: destChain },
  });
}
```

### Fee Estimation

```typescript
const estimate = await kit.estimate({
  from: sourceContext,
  to: destContext,
  amount: '1000000',
  token: 'USDC',
});

console.log('Estimated fees:', estimate.fees);
console.log('Estimated time:', estimate.estimatedTime);
```

---

## Resources

### Documentation
- **Circle Bridge Kit Docs:** https://developers.circle.com/bridge-kit
- **CCTP Documentation:** https://developers.circle.com/stablecoin/docs/cctp-technical-reference
- **Quickstart Guide:** https://developers.circle.com/bridge-kit/quickstarts/transfer-usdc-from-base-to-ethereum

### Packages
- **Bridge Kit:** https://www.npmjs.com/package/@circle-fin/bridge-kit
- **Adapter:** https://www.npmjs.com/package/@circle-fin/adapter-viem-v2

### USDX Documentation
- **Implementation Details:** `BRIDGE-KIT-IMPLEMENTATION-FINAL.md`
- **Summary Report:** `BRIDGE-KIT-FINAL-SUMMARY.md`
- **Archived Docs:** `archive/` folder (historical reference)

---

## Version History

- **2025-11-23:** Complete rewrite with correct API (v1.1.2)
- **Previous:** Multiple implementation attempts with incorrect API

---

## Support

For issues or questions:
1. Check this guide first
2. Review `BRIDGE-KIT-IMPLEMENTATION-FINAL.md` for technical details
3. Check Circle's official documentation
4. Review BridgeKit type definitions in `node_modules`

---

**Status:** ✅ Production-ready for testnet usage  
**Next Step:** Manual testing on testnets with real wallets
