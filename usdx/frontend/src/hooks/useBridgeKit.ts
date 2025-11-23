/**
 * React Hook for Bridge Kit Integration
 * 
 * This hook provides Bridge Kit functionality for React components.
 * Uses the ACTUAL Bridge Kit API verified from type definitions.
 */

import { useState, useCallback, useEffect } from 'react';
import { BridgeKit } from '@circle-fin/bridge-kit';
import type { BridgeResult } from '@circle-fin/bridge-kit';
import type { ViemAdapter } from '@circle-fin/adapter-viem-v2';
import {
  createBridgeKitAdapter,
  createBridgeKit,
  bridgeUSDC as bridgeUSDCUtil,
  getBridgeKitBlockchain,
} from '@/lib/bridgeKit';

export type TransferStatus = 'idle' | 'pending' | 'success' | 'error';

export interface UseBridgeKitReturn {
  bridgeKit: BridgeKit | null;
  adapter: ViemAdapter | null;
  isInitializing: boolean;
  transferStatus: TransferStatus;
  transferResult: BridgeResult | null;
  error: string | null;
  bridgeUSDC: (params: BridgeUSDCParams) => Promise<void>;
  reset: () => void;
}

export interface BridgeUSDCParams {
  sourceChainId: number;
  destinationChainId: number;
  amount: string; // Amount in USDC (6 decimals, e.g., "1000000" for 1 USDC)
  recipientAddress?: string; // Optional recipient address
  onStatusUpdate?: (status: TransferStatus) => void;
}

/**
 * Hook for Bridge Kit integration
 */
export function useBridgeKit(): UseBridgeKitReturn {
  const [bridgeKit, setBridgeKit] = useState<BridgeKit | null>(null);
  const [adapter, setAdapter] = useState<ViemAdapter | null>(null);
  const [isInitializing, setIsInitializing] = useState(false);
  const [transferStatus, setTransferStatus] = useState<TransferStatus>('idle');
  const [transferResult, setTransferResult] = useState<BridgeResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Initialize Bridge Kit and adapter on mount
  useEffect(() => {
    const initialize = async () => {
      setIsInitializing(true);
      setError(null);

      try {
        // Create adapter from browser wallet
        const newAdapter = await createBridgeKitAdapter();
        setAdapter(newAdapter);

        // Create Bridge Kit instance
        const kit = createBridgeKit();
        setBridgeKit(kit);

        // Set up event handlers for status updates
        // Listen for all bridge actions to track progress
        kit.on('*', (payload) => {
          // Update status when bridge actions occur
          // Bridge actions: approve, burn, attestation, mint
          if (payload.method === 'approve' || payload.method === 'burn' || payload.method === 'mint') {
            setTransferStatus('pending');
          }
        });
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to initialize Bridge Kit';
        setError(errorMessage);
        console.error('Bridge Kit initialization error:', err);
      } finally {
        setIsInitializing(false);
      }
    };

    initialize();
  }, []);

  /**
   * Bridge USDC from source chain to destination chain
   */
  const bridgeUSDC = useCallback(async (params: BridgeUSDCParams) => {
    const { sourceChainId, destinationChainId, amount, recipientAddress, onStatusUpdate } = params;

    setError(null);
    setTransferStatus('pending');
    setTransferResult(null);

    try {
      // Verify we have required instances
      if (!bridgeKit || !adapter) {
        throw new Error('Bridge Kit not initialized. Please wait for initialization to complete.');
      }

      // Verify chain support
      const sourceBlockchain = getBridgeKitBlockchain(sourceChainId);
      const destBlockchain = getBridgeKitBlockchain(destinationChainId);

      if (!sourceBlockchain || !destBlockchain) {
        throw new Error(`Unsupported chain: ${sourceChainId} or ${destinationChainId}`);
      }

      // Execute bridge
      const result = await bridgeUSDCUtil(
        bridgeKit,
        adapter,
        adapter, // Using same adapter for both source and dest (user's wallet)
        sourceChainId,
        destinationChainId,
        amount,
        recipientAddress
      );

      setTransferResult(result);

      // Update status based on result state
      // BridgeResult.state: 'pending' | 'success' | 'error'
      // 'pending' means bridge is in progress (steps still executing)
      // 'success' means bridge completed successfully
      // 'error' means bridge failed
      if (result.state === 'success') {
        setTransferStatus('success');
        onStatusUpdate?.('success');
      } else if (result.state === 'error') {
        setTransferStatus('error');
        // Comprehensive error handling based on result.steps
        const errorSteps = result.steps?.filter(step => step.state === 'error') || [];
        let errorMessage = 'Bridge transfer failed';
        
        if (errorSteps.length > 0) {
          // Get the first error step for the message
          const firstError = errorSteps[0];
          const stepName = firstError.name || 'Unknown step';
          errorMessage = `Bridge failed at ${stepName}`;
          
          // Add transaction hash if available
          if (firstError.txHash) {
            errorMessage += ` (tx: ${firstError.txHash.slice(0, 10)}...)`;
          }
        } else {
          errorMessage = 'Bridge transfer failed. Please try again.';
        }
        
        setError(errorMessage);
        onStatusUpdate?.('error');
      } else {
        // result.state === 'pending' - bridge is still in progress
        // Event handlers will update status as steps complete
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

  /**
   * Reset hook state
   */
  const reset = useCallback(() => {
    setTransferStatus('idle');
    setTransferResult(null);
    setError(null);
  }, []);

  return {
    bridgeKit,
    adapter,
    isInitializing,
    transferStatus,
    transferResult,
    error,
    bridgeUSDC,
    reset,
  };
}
