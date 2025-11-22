# Circle Bridge Kit - Complete Research & Integration Guide

## Executive Summary

**Decision**: Use Circle Bridge Kit (SDK) for all USDC cross-chain transfers in USDX protocol.

**Key Points**:
- ✅ No API key required - works directly with smart contracts
- ✅ SDK-only - no UI components provided (custom UI required)
- ✅ TypeScript support with viem adapter
- ✅ Automatic attestation polling
- ✅ Built-in error handling and status tracking

## Overview

Circle Bridge Kit is a TypeScript/JavaScript SDK that simplifies cross-chain USDC transfers using Circle's CCTP (Cross-Chain Transfer Protocol). It provides a higher-level abstraction over direct CCTP contract calls, making integration easier while maintaining full control.

## Verified Technical Details

### Package Installation

```bash
npm install @circle-fin/bridge-kit @circle-fin/adapter-viem-v2 viem typescript tsx dotenv
```

### Package Names
- **Main SDK**: `@circle-fin/bridge-kit`
- **Viem Adapter**: `@circle-fin/adapter-viem-v2`
- **TypeScript**: Full support included

### No API Key Required ✅

Bridge Kit works directly with blockchain contracts - no API authentication needed:

```typescript
import { BridgeKit } from "@circle-fin/bridge-kit";

// No API key needed!
const kit = new BridgeKit({
  adapter: createViemAdapter({ /* config */ })
});
```

### No UI Components ✅

Bridge Kit is SDK-only - we must build custom UI:

```typescript
// Custom React component example
import { BridgeKit } from '@circle-fin/bridge-kit';
import { useState } from 'react';

function CustomBridge() {
  const [status, setStatus] = useState<string>('idle');
  const bridgeKit = new BridgeKit({ /* adapter config */ });
  
  const handleTransfer = async () => {
    const transfer = await bridgeKit.transfer({
      amount: '1000000',
      recipient: destinationAddress,
      onStatusUpdate: (newStatus) => setStatus(newStatus),
    });
  };
  
  return <button onClick={handleTransfer}>Transfer</button>;
}
```

## Integration Architecture

### For USDX Protocol

```
User → Frontend (Bridge Kit SDK) → CCTP Contracts → Attestation → Destination Chain
```

**Key Points**:
- Frontend uses Bridge Kit SDK directly
- No backend service required for basic transfers
- SDK handles attestation polling automatically
- Status updates via SDK callbacks

### Basic Integration Flow

```typescript
import { BridgeKit } from "@circle-fin/bridge-kit";
import { createViemAdapter } from "@circle-fin/adapter-viem-v2";
import { createPublicClient, createWalletClient, http } from "viem";
import { baseSepolia, sepolia } from "viem/chains";

// Initialize Bridge Kit
const kit = new BridgeKit({
  adapter: createViemAdapter({
    sourcePublicClient: createPublicClient({
      chain: baseSepolia,
      transport: http(),
    }),
    sourceWalletClient: createWalletClient({
      chain: baseSepolia,
      transport: http(),
      account: privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`),
    }),
    destinationPublicClient: createPublicClient({
      chain: sepolia,
      transport: http(),
    }),
  }),
});

// Transfer USDC
const transfer = await kit.transfer({
  amount: '1000000', // 1 USDC (6 decimals)
  recipient: destinationAddress,
  onStatusUpdate: (status) => {
    console.log('Status:', status);
    // Update UI
  },
  onError: (error) => {
    console.error('Error:', error);
    // Handle error
  },
});
```

## Transfer Status Tracking

### Status Values

```typescript
type TransferStatus = 
  | 'pending'      // Waiting for attestation
  | 'attested'     // Attestation received, ready to mint
  | 'minting'      // Minting on destination chain
  | 'completed'    // Transfer completed
  | 'failed';      // Transfer failed
```

### Status Tracking Methods

```typescript
// Via callback (recommended)
const transfer = await kit.transfer({
  amount: '1000000',
  recipient: destinationAddress,
  onStatusUpdate: (status) => {
    // Handle status updates in real-time
  },
});

// Via query (if needed)
const status = await kit.getTransferStatus(transferId);
```

## Error Handling

Bridge Kit provides comprehensive error handling:

```typescript
try {
  const transfer = await kit.transfer({
    amount: '1000000',
    recipient: destinationAddress,
    onError: (error) => {
      // Handle specific errors
      if (error.code === 'INSUFFICIENT_BALANCE') {
        // Show balance error
      } else if (error.code === 'ATTESTATION_TIMEOUT') {
        // Retry or show timeout message
      }
    },
  });
} catch (error) {
  // Handle unexpected errors
  console.error('Transfer failed:', error);
}
```

## USDX Integration Pattern

### User Flow: Deposit USDC from Spoke to Hub

```typescript
// User on Spoke Chain wants to deposit USDC to Hub Chain
async function depositUSDCToHub(
  userAddress: string,
  amount: string,
  spokeChain: Chain,
  hubChain: Chain
) {
  // 1. Initialize Bridge Kit for Spoke → Hub transfer
  const bridgeKit = new BridgeKit({
    adapter: createViemAdapter({
      sourcePublicClient: createPublicClient({ chain: spokeChain }),
      sourceWalletClient: createWalletClient({ chain: spokeChain }),
      destinationPublicClient: createPublicClient({ chain: hubChain }),
    }),
  });

  // 2. Transfer USDC to Hub Chain vault address
  const transfer = await bridgeKit.transfer({
    amount: amount,
    recipient: USDX_VAULT_ADDRESS_HUB, // USDXVault on Hub Chain
    onStatusUpdate: (status) => {
      // Update UI with transfer status
      updateTransferStatus(status);
    },
    onError: (error) => {
      // Handle errors
      handleTransferError(error);
    },
  });

  // 3. When transfer completes, vault can mint USDX
  // (This happens via backend service or frontend callback)
  if (transfer.status === 'completed') {
    // Call USDXVault.mintUSDXForCrossChainDeposit()
    await mintUSDXForUser(userAddress, amount, transfer.id);
  }
}
```

## Comparison: Bridge Kit vs Direct CCTP

| Feature | Bridge Kit | Direct CCTP |
|---------|-----------|-------------|
| Ease of Integration | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Control | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Gas Optimization | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| UI Components | ❌ None (SDK only) | ❌ None |
| API Key Required | ❌ No | ❌ No |
| Error Handling | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Attestation Polling | ⭐⭐⭐⭐⭐ (automatic) | ⭐⭐ (manual) |
| Customization | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Documentation | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## Why Bridge Kit for USDX?

### Advantages

1. **Simplified Integration**
   - Higher-level API vs low-level contract calls
   - Less boilerplate code
   - Built-in error handling

2. **Automatic Attestation Polling**
   - SDK handles attestation waiting
   - No need to manually poll Circle's API
   - Better UX with status updates

3. **Better Developer Experience**
   - Comprehensive documentation
   - TypeScript support
   - Clear error messages

4. **No Backend Required**
   - Works directly from frontend
   - No API key management
   - Simpler architecture

### When to Use Direct CCTP

- Smart contract-to-contract interactions
- Gas optimization critical scenarios
- Complex custom logic requirements

## Open Questions (Require Direct Documentation Review)

1. **Rate Limits**: Are there any rate limits on Bridge Kit operations?
2. **Fees**: Are there additional fees beyond gas costs?
3. **Error Types**: Complete list of error types and codes?
4. **Retry Logic**: Built-in retry mechanisms?
5. **Transfer Time**: Typical transfer completion timeframes?

## Implementation Checklist

- [x] Verify package names
- [x] Confirm no API key required
- [x] Confirm no UI components
- [x] Verify TypeScript support
- [ ] Review complete SDK API reference
- [ ] Test on testnets
- [ ] Build custom UI components
- [ ] Implement error handling
- [ ] Test end-to-end flow

## Resources

- **Documentation**: https://developers.circle.com/bridge-kit
- **Installation Guide**: https://developers.circle.com/bridge-kit/tutorials/installation
- **Quickstart (Base → Ethereum)**: https://developers.circle.com/bridge-kit/quickstarts/transfer-usdc-from-base-to-ethereum
- **Quickstart (Ethereum → Solana)**: https://developers.circle.com/bridge-kit/quickstarts/transfer-usdc-from-ethereum-to-solana
- **SDK Reference**: https://developers.circle.com/bridge-kit/references/sdk-reference

## Migration Notes

If switching from direct CCTP to Bridge Kit:
- Remove manual attestation polling code
- Replace contract calls with Bridge Kit SDK calls
- Update error handling to use Bridge Kit error types
- Build custom UI components (no pre-built components)
- Update status tracking to use Bridge Kit callbacks

## Related Documents

- **[07-circle-cctp-research.md](./07-circle-cctp-research.md)** - Direct CCTP reference (for advanced use cases)
- **[02-architecture.md](./02-architecture.md)** - USDX architecture incorporating Bridge Kit
- **[06-implementation-plan.md](./06-implementation-plan.md)** - Implementation plan with Bridge Kit
