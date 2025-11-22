# Circle Bridge Kit Research

## Overview

Circle Bridge Kit is a comprehensive SDK and set of tools that simplifies cross-chain USDC transfers using Circle's CCTP (Cross-Chain Transfer Protocol). It provides a higher-level abstraction over CCTP, making it easier to integrate cross-chain functionality into applications.

## Key Components

### 1. Bridge Kit SDK
- **Language**: TypeScript/JavaScript
- **Function**: High-level API for CCTP operations
- **Features**:
  - Simplified transfer functions
  - Automatic attestation polling
  - Error handling
  - Transaction status tracking

### 2. Bridge Kit SDK (No UI Components)
- **Type**: SDK/library only - no UI components provided
- **Language**: TypeScript/JavaScript
- **Package**: `@circle-fin/bridge-kit`
- **Adapter**: `@circle-fin/adapter-viem-v2` (for viem integration)
- **Note**: Custom UI must be built using the SDK

### 3. Bridge Kit API (No Backend API)
- **Type**: Direct blockchain interaction via SDK
- **No API Key Required**: Works directly with smart contracts
- **No Backend Service**: SDK handles all operations client-side

## Bridge Kit vs Direct CCTP Integration

### Advantages of Bridge Kit

1. **Simplified Integration**
   - Higher-level API vs low-level contract calls
   - Less boilerplate code
   - Built-in error handling

2. **Automatic Attestation Polling**
   - SDK handles attestation waiting
   - No need to manually poll Circle's API
   - Better UX with status updates

3. **Pre-built UI Components**
   - Ready-to-use React components
   - Consistent UI/UX
   - Faster frontend development

4. **Better Error Handling**
   - Comprehensive error types
   - Retry mechanisms
   - Clear error messages

5. **Transaction Status Tracking**
   - Built-in status tracking
   - Progress indicators
   - Webhook support for updates

### Advantages of Direct CCTP

1. **More Control**
   - Direct contract interaction
   - Custom logic implementation
   - Fine-grained control

2. **Gas Optimization**
   - Can optimize gas usage
   - Custom transaction batching
   - No SDK overhead

3. **Flexibility**
   - Custom error handling
   - Custom UI/UX
   - Integration with other protocols

## Bridge Kit Integration Flow

### Step 1: Install SDK

```bash
npm install @circle-fin/cctp-sdk
# or
npm install @circle-fin/bridge-kit
```

### Step 2: Initialize Bridge Kit

```typescript
import { BridgeKit } from '@circle-fin/bridge-kit';
import { createViemAdapter } from '@circle-fin/adapter-viem-v2';
import { createPublicClient, createWalletClient, http } from 'viem';
import { baseSepolia, sepolia } from 'viem/chains';

// No API key needed!
const bridgeKit = new BridgeKit({
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
```

### Step 3: Transfer USDC

```typescript
// Simple transfer
const transfer = await bridgeKit.transfer({
  amount: '1000000', // 1 USDC (6 decimals)
  recipient: destinationAddress,
  onStatusUpdate: (status) => {
    console.log('Transfer status:', status);
    // Update UI with status
  },
});

// Transfer with custom options
const transfer = await bridgeKit.transfer({
  amount: '1000000',
  recipient: destinationAddress,
  sourceChain: 'ethereum',
  destinationChain: 'polygon',
  onStatusUpdate: (status) => {
    // Handle status updates
  },
  onError: (error) => {
    // Handle errors
  },
});
```

### Step 4: Track Transfer Status

```typescript
// Get transfer status
const status = await bridgeKit.getTransferStatus(transferId);

// Status values:
// - 'pending': Waiting for attestation
// - 'attested': Attestation received, ready to mint
// - 'completed': Transfer completed
// - 'failed': Transfer failed
```

## Custom UI Implementation (Bridge Kit SDK Only)

**Note**: Bridge Kit does NOT provide UI components. We need to build our own UI using the SDK.

### React Integration Example

```typescript
// Bridge Kit doesn't provide React components - we build our own

import { BridgeKit } from '@circle-fin/bridge-kit';
import { useState } from 'react';

function CustomBridge() {
  const [status, setStatus] = useState<string>('idle');
  const [error, setError] = useState<Error | null>(null);
  const bridgeKit = new BridgeKit({ /* adapter config */ });
  
  const handleTransfer = async () => {
    try {
      setStatus('initiating');
      const transfer = await bridgeKit.transfer({
        amount: '1000000',
        recipient: destinationAddress,
        sourceChain: 'base',
        destinationChain: 'ethereum',
        onStatusUpdate: (newStatus) => {
          setStatus(newStatus);
        },
      });
      
      setStatus('completed');
    } catch (err) {
      setError(err as Error);
      setStatus('failed');
    }
  };
  
  return (
    <div>
      <button onClick={handleTransfer}>Transfer</button>
      <div>Status: {status}</div>
      {error && <div>Error: {error.message}</div>}
    </div>
  );
}
```

## Integration with USDX Protocol

### Option 1: Bridge Kit for User-Facing Transfers

Use Bridge Kit for user-initiated cross-chain USDC deposits:

```typescript
// User wants to deposit USDC from Chain A to Chain B vault
const bridgeKit = new BridgeKit({
  sourceChain: 'ethereum',
  destinationChain: 'polygon',
});

// Initiate transfer
const transfer = await bridgeKit.transfer({
  amount: usdcAmount,
  recipient: vaultAddress, // USDX vault on destination chain
  onStatusUpdate: (status) => {
    // Update UI
    if (status === 'completed') {
      // Notify vault to mint USDX
      vault.mintUSDX(userAddress, usdcAmount);
    }
  },
});
```

### Option 2: Bridge Kit SDK in Smart Contracts (via Off-Chain Service)

Use Bridge Kit in an off-chain service that interacts with smart contracts:

```typescript
// Off-chain service
class USDXBridgeService {
  async handleCrossChainDeposit(
    sourceChain: string,
    destinationChain: string,
    userAddress: string,
    amount: string
  ) {
    // Use Bridge Kit to transfer USDC
    const transfer = await bridgeKit.transfer({
      amount,
      recipient: vaultAddress,
      sourceChain,
      destinationChain,
    });
    
    // Wait for completion
    await this.waitForTransfer(transfer.id);
    
    // Call vault contract to mint USDX
    await vaultContract.mintUSDX(userAddress, amount);
  }
}
```

### Option 3: Hybrid Approach

- **Bridge Kit**: For user-facing UI and initial transfers
- **Direct CCTP**: For smart contract logic and automated operations

## Bridge Kit API Reference

### Transfer Options

```typescript
interface TransferOptions {
  amount: string; // Amount in smallest unit (6 decimals for USDC)
  recipient: string; // Destination address
  sourceChain?: string; // Optional, defaults to current chain
  destinationChain?: string; // Optional, defaults to selected chain
  onStatusUpdate?: (status: TransferStatus) => void;
  onError?: (error: Error) => void;
  gasLimit?: number; // Custom gas limit
}
```

### Transfer Status

```typescript
type TransferStatus = 
  | 'pending'      // Waiting for attestation
  | 'attested'      // Attestation received
  | 'minting'       // Minting on destination
  | 'completed'     // Transfer completed
  | 'failed';       // Transfer failed

interface Transfer {
  id: string;
  status: TransferStatus;
  sourceChain: string;
  destinationChain: string;
  amount: string;
  recipient: string;
  transactionHash?: string;
  error?: string;
}
```

## Error Handling

```typescript
try {
  const transfer = await bridgeKit.transfer({
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

## Webhook Integration

Bridge Kit supports webhooks for transfer status updates:

```typescript
// Backend webhook handler
app.post('/webhook/bridge-kit', async (req, res) => {
  const { transferId, status, data } = req.body;
  
  if (status === 'completed') {
    // Notify vault to mint USDX
    await vaultContract.mintUSDX(data.recipient, data.amount);
  }
  
  res.status(200).send('OK');
});
```

## Comparison Table

| Feature | Bridge Kit | Direct CCTP |
|---------|-----------|--------------|
| Ease of Integration | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Control | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Gas Optimization | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| UI Components | ❌ None (SDK only) | ❌ None |
| API Key Required | ❌ No | ❌ No |
| Error Handling | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Attestation Polling | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Customization | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Documentation | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## Recommendation for USDX

### Use Bridge Kit For:
1. **Frontend Integration**: SDK for React/Next.js apps (custom UI required)
2. **Status Tracking**: Built-in status updates via callbacks
3. **Error Handling**: Comprehensive error handling and retry logic
4. **Simplified Integration**: No API key, no backend API needed

### Use Direct CCTP For:
1. **Smart Contract Logic**: Contract-to-contract interactions
2. **Gas Optimization**: When gas costs are critical
3. **Custom Logic**: Complex integration requirements

### Recommended Approach:
- **Frontend**: Bridge Kit SDK for user interactions (custom UI)
- **Backend (Optional)**: Bridge Kit SDK for automated operations
- **Smart Contracts**: Direct CCTP for protocol logic if needed
- **Best of Both**: Bridge Kit simplicity for user flows, direct CCTP for advanced cases

## Integration Checklist

- [ ] Review Bridge Kit documentation
- [ ] Test Bridge Kit SDK on testnets
- [ ] Evaluate UI components
- [ ] Test webhook integration
- [ ] Compare gas costs vs direct CCTP
- [ ] Decide on integration approach
- [ ] Update architecture documents
- [ ] Update implementation plan

## Resources

- **Bridge Kit Documentation**: https://developers.circle.com/bridge-kit
- **Bridge Kit SDK**: https://github.com/circlefin/bridge-kit (verify GitHub URL)
- **SDK Reference**: https://developers.circle.com/bridge-kit/references/sdk-reference
- **Quickstart**: https://developers.circle.com/bridge-kit/quickstarts/transfer-usdc-from-base-to-ethereum

## Questions Resolved

1. **API Key**: ✅ No API key required - Bridge Kit works directly with contracts
2. **UI Components**: ✅ No UI components - SDK only, custom UI required
3. **Package Name**: ✅ `@circle-fin/bridge-kit` and `@circle-fin/adapter-viem-v2`
4. **TypeScript**: ✅ Full TypeScript support

## Questions Still Open

1. **Rate Limits**: ⏳ Are there any rate limits on Bridge Kit operations?
2. **Fees**: ⏳ Are there additional fees beyond gas costs?
3. **Webhooks**: ⏳ Does Bridge Kit support webhooks? (Likely not, since it's SDK-only)
4. **Error Types**: ⏳ What are all possible error types?
5. **Retry Logic**: ⏳ Built-in retry mechanisms?
6. **Status Tracking**: ⏳ How to track transfer status programmatically?
