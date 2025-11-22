import { useState, useCallback } from 'react';
import { BridgeKit } from '@circle-fin/bridge-kit';
import { createViemAdapter } from '@circle-fin/adapter-viem-v2';
import { createPublicClient, createWalletClient, http, custom } from 'viem';
import { getViemChain } from '@/lib/bridgeKit';

export type TransferStatus = 'idle' | 'pending' | 'attested' | 'minting' | 'completed' | 'failed';

export interface UseBridgeKitReturn {
  bridgeKit: BridgeKit | null;
  isInitializing: boolean;
  transferStatus: TransferStatus;
  transferId: string | null;
  error: string | null;
  bridgeUSDC: (params: BridgeUSDCParams) => Promise<void>;
  reset: () => void;
}

export interface BridgeUSDCParams {
  sourceChainId: number;
  destinationChainId: number;
  amount: string; // Amount in USDC (6 decimals, e.g., "1000000" for 1 USDC)
  recipient: `0x${string}`;
  onStatusUpdate?: (status: TransferStatus) => void;
}

/**
 * Hook for Bridge Kit integration
 * Note: This requires the user's wallet to be connected via viem's browser wallet
 */
export function useBridgeKit(): UseBridgeKitReturn {
  const [bridgeKit, setBridgeKit] = useState<BridgeKit | null>(null);
  const [isInitializing, setIsInitializing] = useState(false);
  const [transferStatus, setTransferStatus] = useState<TransferStatus>('idle');
  const [transferId, setTransferId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  /**
   * Initialize Bridge Kit with browser wallet
   */
  const initializeBridgeKit = useCallback(async (
    sourceChainId: number,
    destinationChainId: number
  ) => {
    setIsInitializing(true);
    setError(null);

    try {
      // Get viem chains
      const sourceChain = getViemChain(sourceChainId);
      const destinationChain = getViemChain(destinationChainId);

      if (!sourceChain || !destinationChain) {
        throw new Error(`Unsupported chain: ${sourceChainId} or ${destinationChainId}`);
      }

      // Check if wallet is available
      if (typeof window === 'undefined' || !window.ethereum) {
        throw new Error('No wallet found. Please install MetaMask or another compatible wallet.');
      }

      // Create public clients
      const sourcePublicClient = createPublicClient({
        chain: sourceChain,
        transport: http(),
      });

      const destinationPublicClient = createPublicClient({
        chain: destinationChain,
        transport: http(),
      });

      // For browser wallets, use viem's custom transport with window.ethereum
      // Bridge Kit requires viem wallet client
      // Note: This requires the user to have their wallet connected via window.ethereum
      if (typeof window === 'undefined' || !window.ethereum) {
        throw new Error('Browser wallet not found');
      }
      
      // Create custom transport using window.ethereum
      const browserTransport = custom(window.ethereum);
      
      // Create wallet client - account will be determined from connected wallet
      const sourceWalletClient = createWalletClient({
        chain: sourceChain,
        transport: browserTransport,
      });
      
      // Create adapter
      const adapter = createViemAdapter({
        sourcePublicClient,
        sourceWalletClient,
        destinationPublicClient,
      });

      // Initialize Bridge Kit
      const kit = new BridgeKit({ adapter });
      setBridgeKit(kit);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to initialize Bridge Kit';
      setError(errorMessage);
      console.error('Bridge Kit initialization error:', err);
    } finally {
      setIsInitializing(false);
    }
  }, []);

  /**
   * Bridge USDC from source chain to destination chain
   */
  const bridgeUSDC = useCallback(async (params: BridgeUSDCParams) => {
    const { sourceChainId, destinationChainId, amount, recipient, onStatusUpdate } = params;

    setError(null);
    setTransferStatus('pending');
    setTransferId(null);

    try {
      // Initialize Bridge Kit if not already initialized or if chain changed
      let kit = bridgeKit;
      if (!kit) {
        await initializeBridgeKit(sourceChainId, destinationChainId);
        // Get the newly created instance - we need to create it fresh
        // Since state update is async, we'll create it directly here
        const sourceChain = getViemChain(sourceChainId);
        const destinationChain = getViemChain(destinationChainId);

        if (!sourceChain || !destinationChain) {
          throw new Error(`Unsupported chain: ${sourceChainId} or ${destinationChainId}`);
        }

        if (typeof window === 'undefined' || !window.ethereum) {
          throw new Error('No wallet found. Please install MetaMask or another compatible wallet.');
        }

        const sourcePublicClient = createPublicClient({
          chain: sourceChain,
          transport: http(),
        });

        const destinationPublicClient = createPublicClient({
          chain: destinationChain,
          transport: http(),
        });

        const browserTransport = custom(window.ethereum);
        
        const sourceWalletClient = createWalletClient({
          chain: sourceChain,
          transport: browserTransport,
        });

        const adapter = createViemAdapter({
          sourcePublicClient,
          sourceWalletClient,
          destinationPublicClient,
        });

        kit = new BridgeKit({ adapter });
        setBridgeKit(kit);
      }

      if (!kit) {
        throw new Error('Bridge Kit not initialized');
      }

      // Perform transfer
      const transfer = await kit.transfer({
        amount,
        recipient,
        onStatusUpdate: (status) => {
          const mappedStatus: TransferStatus = 
            status === 'pending' ? 'pending' :
            status === 'attested' ? 'attested' :
            status === 'minting' ? 'minting' :
            status === 'completed' ? 'completed' :
            status === 'failed' ? 'failed' : 'idle';
          
          setTransferStatus(mappedStatus);
          onStatusUpdate?.(mappedStatus);
        },
        onError: (err) => {
          setError(err.message || 'Transfer failed');
          setTransferStatus('failed');
        },
      });

      setTransferId(transfer.id || null);
      
      if (transfer.status === 'completed') {
        setTransferStatus('completed');
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Bridge transfer failed';
      setError(errorMessage);
      setTransferStatus('failed');
      console.error('Bridge transfer error:', err);
    }
  }, [bridgeKit, initializeBridgeKit]);

  /**
   * Reset hook state
   */
  const reset = useCallback(() => {
    setTransferStatus('idle');
    setTransferId(null);
    setError(null);
  }, []);

  return {
    bridgeKit,
    isInitializing,
    transferStatus,
    transferId,
    error,
    bridgeUSDC,
    reset,
  };
}
