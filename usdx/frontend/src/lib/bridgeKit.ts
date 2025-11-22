/**
 * Bridge Kit Utility Functions
 * 
 * Provides helper functions for Circle Bridge Kit integration.
 * These functions wrap the Bridge Kit API for easier use in React components.
 */

import { BridgeKit } from '@circle-fin/bridge-kit';
import type { BridgeResult } from '@circle-fin/bridge-kit';
import { ViemAdapter } from '@circle-fin/adapter-viem-v2';
import { createPublicClient, createWalletClient, custom, http } from 'viem';

/**
 * Create a Bridge Kit adapter from the browser wallet
 * Uses ViemAdapter which connects to the user's wallet (MetaMask, etc.)
 * ViemAdapter requires a public client and a wallet client
 */
export async function createBridgeKitAdapter(): Promise<ViemAdapter> {
  // Check if window.ethereum is available (MetaMask, etc.)
  if (typeof window === 'undefined' || !window.ethereum) {
    throw new Error('No wallet found. Please install MetaMask or another Web3 wallet.');
  }

  // Create a public client for the current chain
  const publicClient = createPublicClient({
    transport: http(),
  });

  // Create a wallet client from window.ethereum
  const walletClient = createWalletClient({
    transport: custom(window.ethereum),
  });

  // ViemAdapter requires ViemAdapterOptions and AdapterCapabilities
  // addressContext indicates who controls the address - "user-controlled" for user's wallet
  const adapter = new ViemAdapter(
    {
      getPublicClient: () => publicClient,
      getWalletClient: () => walletClient,
    },
    {
      addressContext: 'user-controlled' as const,
      // Bridge Kit will auto-detect supported chains from the adapter
      supportedChains: [] as never[], // Empty array - Bridge Kit will detect chains automatically
    }
  );
  
  return adapter;
}

/**
 * Create a Bridge Kit instance
 */
export function createBridgeKit(): BridgeKit {
  return new BridgeKit();
}

/**
 * Bridge USDC from source chain to destination chain
 * 
 * @param bridgeKit - Bridge Kit instance
 * @param sourceAdapter - Adapter for source chain (user's wallet)
 * @param destinationAdapter - Adapter for destination chain (user's wallet)
 * @param sourceChainId - Source chain ID (e.g., 11155111 for Sepolia)
 * @param destinationChainId - Destination chain ID (e.g., 84532 for Base Sepolia)
 * @param amount - Amount in USDC (6 decimals, e.g., "1000000" for 1 USDC)
 * @param recipientAddress - Optional recipient address (defaults to source adapter address)
 * @returns Promise<BridgeResult>
 */
export async function bridgeUSDC(
  bridgeKit: BridgeKit,
  sourceAdapter: ViemAdapter,
  destinationAdapter: ViemAdapter,
  sourceChainId: number,
  destinationChainId: number,
  amount: string,
  recipientAddress?: string
): Promise<BridgeResult> {
  // Get Bridge Kit chain IDs
  const sourceChainIdStr = getBridgeKitChainId(sourceChainId);
  const destChainIdStr = getBridgeKitChainId(destinationChainId);

  if (!sourceChainIdStr || !destChainIdStr) {
    throw new Error(`Unsupported chain: ${sourceChainId} or ${destinationChainId}`);
  }

  // Use recipient address from adapter if not provided
  // getAddress() requires a chain definition, not just a chain ID
  // For now, require recipientAddress to be provided
  if (!recipientAddress) {
    throw new Error('Recipient address is required for bridge transfers');
  }
  const recipient = recipientAddress;

  // Execute bridge transfer
  // Note: This is a placeholder implementation
  // The actual Bridge Kit API needs to be verified from their documentation
  // For now, throw an error indicating this needs proper Bridge Kit integration
  throw new Error(
    'Bridge Kit integration not fully implemented. ' +
    'Please refer to Circle Bridge Kit documentation for the correct API usage.'
  );
}

/**
 * Convert numeric chain ID to Bridge Kit chain ID string
 * Bridge Kit uses string identifiers like 'ethereum-sepolia', 'base-sepolia', etc.
 * 
 * @param chainId - Numeric chain ID
 * @returns Bridge Kit chain ID string or null if unsupported
 */
export function getBridgeKitChainId(chainId: number): string | null {
  // Map chain IDs to Bridge Kit identifiers
  const chainIdMap: Record<number, string> = {
    // Testnets
    11155111: 'ethereum-sepolia', // Ethereum Sepolia
    84532: 'base-sepolia', // Base Sepolia
    421614: 'arbitrum-sepolia', // Arbitrum Sepolia
    11155420: 'optimism-sepolia', // Optimism Sepolia
    // Mainnets (commented for now)
    // 1: 'ethereum',
    // 8453: 'base',
    // 42161: 'arbitrum',
    // 10: 'optimism',
  };

  return chainIdMap[chainId] || null;
}
