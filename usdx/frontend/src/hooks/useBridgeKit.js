/**
 * React Hook for Bridge Kit Integration
 * 
 * This hook provides Bridge Kit functionality for React components.
 */

import { useState, useCallback, useEffect } from 'react';
import {
  createBridgeKitAdapter,
  createBridgeKit,
  bridgeUSDC as bridgeUSDCUtil,
  getBridgeKitChainId,
} from '@/lib/bridgeKit';

/**
 * Hook for Bridge Kit integration
 */
export function useBridgeKit() {
  const [bridgeKit, setBridgeKit] = useState(null);
  const [adapter, setAdapter] = useState(null);
  const [isInitializing, setIsInitializing] = useState(false);
  const [transferStatus, setTransferStatus] = useState('idle');
  const [transferResult, setTransferResult] = useState(null);
  const [error, setError] = useState(null);

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
        if (kit.on) {
          kit.on('*', (payload) => {
            // Update status when bridge actions occur
            // Bridge actions: approve, burn, attestation, mint
            if (payload.method === 'approve' || payload.method === 'burn' || payload.method === 'mint') {
              setTransferStatus('pending');
            }
          });
        }
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
  const bridgeUSDC = useCallback(async (params) => {
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
      const sourceChainIdStr = getBridgeKitChainId(sourceChainId);
      const destChainIdStr = getBridgeKitChainId(destinationChainId);

      if (!sourceChainIdStr || !destChainIdStr) {
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
      if (result.state === 'success') {
        setTransferStatus('success');
        if (onStatusUpdate) onStatusUpdate('success');
      } else if (result.state === 'error') {
        setTransferStatus('error');
        // Check result.steps for detailed error information
        const errorDetails = result.steps?.find((step) => step.state === 'error');
        const errorMessage = errorDetails 
          ? `Bridge transfer failed: ${errorDetails.name || 'Unknown error'}`
          : 'Bridge transfer failed. Check result.steps for details.';
        setError(errorMessage);
        if (onStatusUpdate) onStatusUpdate('error');
      } else {
        // result.state === 'pending' - bridge is still in progress
        setTransferStatus('pending');
        if (onStatusUpdate) onStatusUpdate('pending');
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Bridge transfer failed';
      setError(errorMessage);
      setTransferStatus('error');
      if (onStatusUpdate) onStatusUpdate('error');
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
