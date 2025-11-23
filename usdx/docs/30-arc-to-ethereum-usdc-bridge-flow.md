# Arc to Ethereum Mainnet USDC Bridge Flow - Detailed Guide

## Overview

This document provides **step-by-step instructions** for implementing the user flow that allows Arc users to bridge USDC from Arc to Ethereum mainnet using Circle Bridge Kit, then deposit that USDC into the USDXVault to mint USDX.

## User Flow Summary

```
Arc User → Bridge USDC (Arc → Ethereum) → Deposit USDC → Mint USDX
```

**Detailed Steps:**
1. User has USDC on Arc Testnet
2. User initiates Bridge Kit transfer: Arc → Ethereum Mainnet
3. Bridge Kit handles CCTP transfer (burn on Arc, mint on Ethereum)
4. User receives USDC on Ethereum Mainnet
5. User deposits USDC into USDXVault contract
6. USDXVault mints USDX 1:1 to user

## Technical Architecture

### Components Involved

1. **Circle Bridge Kit** (`@circle-fin/bridge-kit`)
   - Handles USDC cross-chain transfers via CCTP
   - Supports Arc Testnet → Ethereum Mainnet
   - Uses `ViemAdapter` for wallet integration

2. **USDXVault Contract** (`USDXVault.sol`)
   - Deployed on Ethereum Mainnet (hub chain)
   - Accepts USDC deposits
   - Mints USDX 1:1 against USDC

3. **Frontend Integration**
   - Bridge Kit hook (`useBridgeKit.ts`)
   - Bridge Kit utility functions (`bridgeKit.ts`)
   - Vault deposit component

## Implementation Guide

### Step 1: Configure Bridge Kit for Arc → Ethereum

**File**: `usdx/frontend/src/lib/bridgeKit.ts`

**Update Chain Mapping**:
```typescript
export function getBridgeKitChainId(chainId: number): string | null {
  const chainIdMap: Record<number, string> = {
    // Testnets
    11155111: 'Ethereum_Sepolia', // Ethereum Sepolia
    84532: 'Base_Sepolia', // Base Sepolia
    421614: 'Arbitrum_Sepolia', // Arbitrum Sepolia
    11155420: 'Optimism_Sepolia', // Optimism Sepolia
    5042002: 'Arc_Testnet', // ✅ Arc Testnet - VERIFY exact identifier
    
    // Mainnets
    1: 'Ethereum', // Ethereum Mainnet
    8453: 'Base', // Base Mainnet
    42161: 'Arbitrum', // Arbitrum Mainnet
    10: 'Optimism', // Optimism Mainnet
  };

  return chainIdMap[chainId] || null;
}
```

**⚠️ Important**: The exact Bridge Kit chain identifier for Arc needs verification. Check:
- Bridge Kit SDK source code
- Bridge Kit documentation
- Test with SDK initialization

**Likely values**: `'Arc_Testnet'`, `'Arc'`, or `'arc-testnet'` (case-sensitive)

### Step 2: Create Bridge Kit Transfer Function

**File**: `usdx/frontend/src/lib/bridgeKit.ts`

**Add Function**:
```typescript
import { BridgeKit } from '@circle-fin/bridge-kit';
import type { BridgeParams, BridgeResult, AdapterContext } from '@circle-fin/bridge-kit';
import { createAdapterFromProvider } from '@circle-fin/adapter-viem-v2';

/**
 * Bridge USDC from Arc to Ethereum Mainnet
 * 
 * @param bridgeKit - Bridge Kit instance
 * @param adapter - ViemAdapter instance (from user's wallet)
 * @param amount - Amount in USDC (6 decimals, e.g., "1000000" for 1 USDC)
 * @param recipientAddress - Optional recipient address (defaults to adapter address)
 * @returns Promise<BridgeResult>
 */
export async function bridgeUSDCFromArcToEthereum(
  bridgeKit: BridgeKit,
  adapter: ViemAdapter,
  amount: string,
  recipientAddress?: string
): Promise<BridgeResult> {
  // Get Bridge Kit chain identifiers
  const arcChainId = getBridgeKitChainId(5042002); // Arc Testnet
  const ethereumChainId = getBridgeKitChainId(1); // Ethereum Mainnet

  if (!arcChainId || !ethereumChainId) {
    throw new Error(`Unsupported chain: Arc (5042002) or Ethereum (1)`);
  }

  // Get recipient address (use adapter address if not provided)
  let recipient = recipientAddress;
  if (!recipient) {
    // Get address from adapter - requires chain context
    // For now, require recipientAddress to be provided explicitly
    throw new Error('Recipient address is required for bridge transfers');
  }

  // Create adapter contexts
  const fromContext: AdapterContext = {
    adapter,
    chain: arcChainId as any, // Type assertion needed for chain identifier
  };

  const toContext: AdapterContext = {
    adapter,
    chain: ethereumChainId as any,
  };

  // Execute bridge transfer
  const result = await bridgeKit.bridge({
    from: fromContext,
    to: toContext,
    amount: amount, // Amount in USDC (6 decimals)
    token: 'USDC',
  });

  return result;
}
```

### Step 3: Update React Hook for Arc → Ethereum Flow

**File**: `usdx/frontend/src/hooks/useBridgeKit.ts`

**Add Method**:
```typescript
export interface BridgeArcToEthereumParams {
  amount: string; // Amount in USDC (6 decimals, e.g., "1000000" for 1 USDC)
  recipientAddress?: string; // Optional recipient address
  onStatusUpdate?: (status: TransferStatus) => void;
}

/**
 * Bridge USDC from Arc to Ethereum Mainnet
 */
const bridgeArcToEthereum = useCallback(async (params: BridgeArcToEthereumParams) => {
  const { amount, recipientAddress, onStatusUpdate } = params;

  setError(null);
  setTransferStatus('pending');
  setTransferResult(null);

  try {
    // Verify we have required instances
    if (!bridgeKit || !adapter) {
      throw new Error('Bridge Kit not initialized. Please wait for initialization to complete.');
    }

    // Execute bridge
    const result = await bridgeUSDCFromArcToEthereum(
      bridgeKit,
      adapter,
      amount,
      recipientAddress
    );

    setTransferResult(result);

    // Update status based on result
    if (result.state === 'success') {
      setTransferStatus('success');
      onStatusUpdate?.('success');
    } else if (result.state === 'error') {
      setTransferStatus('error');
      const errorDetails = result.steps?.find(step => step.state === 'error');
      const errorMessage = errorDetails 
        ? `Bridge transfer failed: ${errorDetails.name || 'Unknown error'}`
        : 'Bridge transfer failed. Check result.steps for details.';
      setError(errorMessage);
      onStatusUpdate?.('error');
    } else {
      // result.state === 'pending' - bridge is still in progress
      setTransferStatus('pending');
      onStatusUpdate?.('pending');
    }
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'Bridge transfer failed';
    setError(errorMessage);
    setTransferStatus('error');
    onStatusUpdate?.('error');
    console.error('Bridge transfer error:', err);
  }
}, [bridgeKit, adapter]);

// Add to return object
return {
  // ... existing returns
  bridgeArcToEthereum,
};
```

### Step 4: Create Vault Deposit Function

**File**: `usdx/frontend/src/lib/vault.ts` (new file or existing)

```typescript
import { createPublicClient, createWalletClient, custom, http, parseUnits, formatUnits } from 'viem';
import { mainnet } from 'viem/chains';
import { ERC20_ABI } from '@/lib/abis/erc20';
import { USDX_VAULT_ABI } from '@/lib/abis/usdxVault';

/**
 * Deposit USDC into USDXVault and mint USDX
 * 
 * @param vaultAddress - USDXVault contract address on Ethereum Mainnet
 * @param usdcAddress - USDC token address on Ethereum Mainnet
 * @param amount - Amount in USDC (human-readable, e.g., "100" for 100 USDC)
 * @returns Transaction hash
 */
export async function depositUSDCToVault(
  vaultAddress: string,
  usdcAddress: string,
  amount: string
): Promise<`0x${string}`> {
  if (typeof window === 'undefined' || !window.ethereum) {
    throw new Error('No wallet found. Please install MetaMask or another Web3 wallet.');
  }

  // Create clients
  const publicClient = createPublicClient({
    chain: mainnet,
    transport: http(),
  });

  const walletClient = createWalletClient({
    chain: mainnet,
    transport: custom(window.ethereum),
  });

  const [account] = await walletClient.getAddresses();
  if (!account) {
    throw new Error('No account connected');
  }

  // Parse amount (USDC has 6 decimals)
  const amountWei = parseUnits(amount, 6);

  // Step 1: Approve USDC spending
  const approveHash = await walletClient.writeContract({
    address: usdcAddress as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'approve',
    args: [vaultAddress as `0x${string}`, amountWei],
    account,
  });

  // Wait for approval
  await publicClient.waitForTransactionReceipt({ hash: approveHash });

  // Step 2: Deposit USDC into vault
  const depositHash = await walletClient.writeContract({
    address: vaultAddress as `0x${string}`,
    abi: USDX_VAULT_ABI,
    functionName: 'deposit',
    args: [amountWei],
    account,
  });

  return depositHash;
}
```

**Required ABI Files**:

**File**: `usdx/frontend/src/lib/abis/usdxVault.ts`
```typescript
export const USDX_VAULT_ABI = [
  {
    name: 'deposit',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [
      { name: 'usdxMinted', type: 'uint256' },
    ],
  },
  {
    name: 'withdraw',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'usdxAmount', type: 'uint256' },
    ],
    outputs: [
      { name: 'usdcReturned', type: 'uint256' },
    ],
  },
  // Add other vault functions as needed
] as const;
```

### Step 5: Create Complete Flow Component

**File**: `usdx/frontend/src/components/ArcToEthereumFlow.tsx` (new file)

```typescript
'use client';

import { useState, useCallback } from 'react';
import { useBridgeKit } from '@/hooks/useBridgeKit';
import { depositUSDCToVault } from '@/lib/vault';
import { useAccount, useSwitchChain } from 'wagmi';
import { mainnet } from 'viem/chains';

interface ArcToEthereumFlowProps {
  vaultAddress: string;
  usdcAddress: string;
}

export function ArcToEthereumFlow({ vaultAddress, usdcAddress }: ArcToEthereumFlowProps) {
  const [amount, setAmount] = useState('');
  const [step, setStep] = useState<'input' | 'bridging' | 'depositing' | 'complete' | 'error'>('input');
  const [error, setError] = useState<string | null>(null);
  const [bridgeTxHash, setBridgeTxHash] = useState<string | null>(null);
  const [depositTxHash, setDepositTxHash] = useState<string | null>(null);

  const { bridgeArcToEthereum, transferStatus, transferResult } = useBridgeKit();
  const { address } = useAccount();
  const { switchChain } = useSwitchChain();

  const handleBridge = useCallback(async () => {
    if (!amount || !address) {
      setError('Please enter an amount and connect your wallet');
      return;
    }

    try {
      setStep('bridging');
      setError(null);

      // Convert amount to USDC units (6 decimals)
      const amountInUSDC = (parseFloat(amount) * 1_000_000).toString();

      // Bridge USDC from Arc to Ethereum
      await bridgeArcToEthereum({
        amount: amountInUSDC,
        recipientAddress: address,
        onStatusUpdate: (status) => {
          if (status === 'success') {
            setBridgeTxHash(transferResult?.steps?.find(s => s.name === 'mint')?.txHash || null);
            setStep('depositing');
            handleDeposit();
          } else if (status === 'error') {
            setStep('error');
          }
        },
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Bridge failed');
      setStep('error');
    }
  }, [amount, address, bridgeArcToEthereum, transferResult]);

  const handleDeposit = useCallback(async () => {
    if (!address) {
      setError('No wallet connected');
      return;
    }

    try {
      // Switch to Ethereum Mainnet if needed
      await switchChain({ chainId: mainnet.id });

      // Wait a moment for chain switch
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Deposit USDC into vault
      const txHash = await depositUSDCToVault(vaultAddress, usdcAddress, amount);
      setDepositTxHash(txHash);

      setStep('complete');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Deposit failed');
      setStep('error');
    }
  }, [amount, address, vaultAddress, usdcAddress, switchChain]);

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Bridge USDC from Arc to Ethereum</h2>

      {step === 'input' && (
        <div className="space-y-4">
          <div>
            <label htmlFor="amount" className="block text-sm font-medium mb-2">
              Amount (USDC)
            </label>
            <input
              id="amount"
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="100"
              className="w-full px-4 py-2 border rounded-lg"
            />
          </div>
          <button
            onClick={handleBridge}
            disabled={!amount || !address}
            className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            Bridge & Mint USDX
          </button>
        </div>
      )}

      {step === 'bridging' && (
        <div className="space-y-4">
          <p className="text-lg">Bridging USDC from Arc to Ethereum...</p>
          <p className="text-sm text-gray-600">
            Status: {transferStatus}
          </p>
          {transferResult && (
            <div className="text-sm">
              <p>Steps:</p>
              <ul className="list-disc list-inside">
                {transferResult.steps?.map((step, i) => (
                  <li key={i}>
                    {step.name}: {step.state}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

      {step === 'depositing' && (
        <div className="space-y-4">
          <p className="text-lg">Depositing USDC into vault...</p>
          <p className="text-sm text-gray-600">
            Please confirm the transaction in your wallet.
          </p>
        </div>
      )}

      {step === 'complete' && (
        <div className="space-y-4">
          <p className="text-lg font-bold text-green-600">Success!</p>
          <p className="text-sm">Bridge Transaction: {bridgeTxHash}</p>
          <p className="text-sm">Deposit Transaction: {depositTxHash}</p>
          <button
            onClick={() => {
              setStep('input');
              setAmount('');
              setBridgeTxHash(null);
              setDepositTxHash(null);
            }}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Start New Transfer
          </button>
        </div>
      )}

      {step === 'error' && error && (
        <div className="space-y-4">
          <p className="text-lg font-bold text-red-600">Error</p>
          <p className="text-sm">{error}</p>
          <button
            onClick={() => {
              setStep('input');
              setError(null);
            }}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Try Again
          </button>
        </div>
      )}
    </div>
  );
}
```

## Bridge Kit Transfer Process Details

### How Bridge Kit Works

Bridge Kit uses Circle's CCTP (Cross-Chain Transfer Protocol) under the hood:

1. **Burn Phase** (on Arc):
   - User approves USDC spending
   - Bridge Kit burns USDC on Arc via CCTP TokenMessenger
   - CCTP MessageTransmitter creates attestation

2. **Attestation Phase** (off-chain):
   - Circle's attestation service validates the burn
   - Attestation is generated (takes ~15-30 seconds)

3. **Mint Phase** (on Ethereum):
   - Bridge Kit submits attestation to CCTP MessageTransmitter on Ethereum
   - CCTP TokenMessenger mints USDC to recipient address
   - Transfer completes

### Bridge Kit Event Flow

```typescript
// Set up event handlers
bridgeKit.on('approve', (payload) => {
  console.log('Approving USDC spending...');
  // Update UI: "Step 1/3: Approving..."
});

bridgeKit.on('burn', (payload) => {
  console.log('Burning USDC on Arc...');
  // Update UI: "Step 2/3: Burning USDC..."
});

bridgeKit.on('attestation', (payload) => {
  console.log('Waiting for attestation...');
  // Update UI: "Step 2.5/3: Waiting for attestation..."
});

bridgeKit.on('mint', (payload) => {
  console.log('Minting USDC on Ethereum...');
  // Update UI: "Step 3/3: Minting USDC..."
});
```

### Bridge Kit Result Structure

```typescript
interface BridgeResult {
  state: 'pending' | 'success' | 'error';
  steps: Array<{
    name: string; // 'approve', 'burn', 'attestation', 'mint'
    state: 'pending' | 'success' | 'error';
    txHash?: string;
    error?: string;
  }>;
}
```

## Vault Deposit Process

### USDXVault.deposit() Flow

1. **User Approval**:
   - User must approve USDXVault to spend USDC
   - Approval amount should be >= deposit amount

2. **Deposit Call**:
   - User calls `USDXVault.deposit(amount)`
   - Contract transfers USDC from user to vault
   - Contract mints USDX 1:1 to user
   - Contract deposits USDC into Yearn vault (if configured)

3. **Result**:
   - User receives USDX tokens
   - User's USDC is locked in vault
   - User earns yield (if Yearn vault is configured)

## Error Handling

### Common Bridge Kit Errors

1. **Insufficient Balance**:
   - User doesn't have enough USDC on Arc
   - **Solution**: Check balance before bridging

2. **Chain Not Supported**:
   - Bridge Kit doesn't recognize Arc chain ID
   - **Solution**: Verify chain identifier mapping

3. **Attestation Timeout**:
   - Attestation takes longer than expected
   - **Solution**: Show progress indicator, allow retry

4. **User Rejection**:
   - User rejects transaction in wallet
   - **Solution**: Handle rejection gracefully

### Common Vault Deposit Errors

1. **Insufficient Allowance**:
   - User hasn't approved enough USDC
   - **Solution**: Request approval before deposit

2. **Insufficient Balance**:
   - User doesn't have USDC on Ethereum Mainnet
   - **Solution**: Verify bridge completed successfully

3. **Wrong Chain**:
   - User is on wrong network
   - **Solution**: Prompt user to switch to Ethereum Mainnet

## Testing Checklist

### Unit Tests

- [ ] `getBridgeKitChainId()` returns correct identifier for Arc
- [ ] `bridgeUSDCFromArcToEthereum()` handles errors correctly
- [ ] `depositUSDCToVault()` approves and deposits correctly

### Integration Tests

- [ ] Bridge Kit recognizes Arc Testnet chain ID
- [ ] Bridge transfer completes successfully
- [ ] USDC appears on Ethereum Mainnet after bridge
- [ ] Vault deposit works after bridge
- [ ] USDX is minted correctly

### E2E Tests

- [ ] User can bridge USDC from Arc to Ethereum
- [ ] User can deposit USDC into vault after bridge
- [ ] User receives USDX after deposit
- [ ] Error states are handled gracefully
- [ ] UI updates correctly during bridge process

## Configuration Requirements

### Environment Variables

```env
# Ethereum Mainnet
NEXT_PUBLIC_ETHEREUM_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
NEXT_PUBLIC_USDX_VAULT_ADDRESS=0x...
NEXT_PUBLIC_USDC_ADDRESS=0xA0b86991c6218b36c1d19D4a2e9Eb0c3606eB48

# Arc Testnet
NEXT_PUBLIC_ARC_RPC_URL=https://rpc.testnet.arc.network
```

### Contract Addresses

**Ethereum Mainnet**:
- USDC: `0xA0b86991c6218b36c1d19D4a2e9Eb0c3606eB48`
- USDXVault: `<DEPLOYED_ADDRESS>` (to be deployed)

**Arc Testnet**:
- USDC: `<CCTP_USDC_ADDRESS>` (from Arc contract addresses docs)

## Security Considerations

1. **Amount Validation**:
   - Always validate user input amounts
   - Check for minimum/maximum limits
   - Prevent integer overflow

2. **Transaction Verification**:
   - Verify bridge completed before allowing deposit
   - Check USDC balance on Ethereum before deposit
   - Verify vault contract address

3. **Error Recovery**:
   - Allow users to retry failed bridges
   - Provide clear error messages
   - Log errors for debugging

4. **Gas Estimation**:
   - Estimate gas costs before transactions
   - Warn users about high gas costs
   - Provide gas optimization tips

## Next Steps

1. **Verify Bridge Kit Chain Identifier**:
   - Test Bridge Kit initialization with Arc chain ID
   - Confirm exact identifier string

2. **Deploy USDXVault**:
   - Deploy to Ethereum Mainnet
   - Verify contract addresses
   - Update frontend configuration

3. **Test End-to-End**:
   - Test bridge from Arc Testnet
   - Test deposit on Ethereum Mainnet
   - Verify USDX minting

4. **UI/UX Improvements**:
   - Add progress indicators
   - Show estimated completion times
   - Add transaction history

5. **Documentation**:
   - Update user-facing docs
   - Add troubleshooting guide
   - Document gas costs

---

**Last Updated**: January 2025  
**Status**: Ready for implementation - Requires Bridge Kit chain identifier verification
