/**
 * Bridge Kit Utility Functions
 * 
 * Provides helper functions for Circle Bridge Kit integration.
 * These functions wrap the Bridge Kit API for easier use in React components.
 */

import { BridgeKit, Blockchain } from '@circle-fin/bridge-kit';
import type { BridgeResult, AdapterContext } from '@circle-fin/bridge-kit';
import { createAdapterFromProvider } from '@circle-fin/adapter-viem-v2';
import type { ViemAdapter } from '@circle-fin/adapter-viem-v2';

/**
 * Create a Bridge Kit adapter from the browser wallet
 * Uses the official createAdapterFromProvider function from @circle-fin/adapter-viem-v2
 */
export async function createBridgeKitAdapter(): Promise<ViemAdapter> {
  // Check if window.ethereum is available (MetaMask, etc.)
  if (typeof window === 'undefined' || !window.ethereum) {
    throw new Error('No wallet found. Please install MetaMask or another Web3 wallet.');
  }

  // Create adapter from browser provider
  // Default capabilities are user-controlled (addresses forbidden for security)
  // Type assertion is needed because window.ethereum type is slightly different
  const adapter = await createAdapterFromProvider({
    provider: window.ethereum as any,
  });
  
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
 * @param recipientAddress - Optional recipient address (defaults to user's address on destination)
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
  // Get Bridge Kit chain identifiers
  const sourceBlockchain = getBridgeKitBlockchain(sourceChainId);
  const destBlockchain = getBridgeKitBlockchain(destinationChainId);

  if (!sourceBlockchain || !destBlockchain) {
    throw new Error(`Unsupported chain: ${sourceChainId} or ${destinationChainId}`);
  }

  // Create adapter contexts for source and destination
  const fromContext: AdapterContext = {
    adapter: sourceAdapter,
    chain: sourceBlockchain,
  };

  // Destination context - with optional custom recipient
  // When recipientAddress is provided, it extends AdapterContext with that field
  const toContext: AdapterContext | (AdapterContext & { recipientAddress: string }) = recipientAddress 
    ? {
        adapter: destinationAdapter,
        chain: destBlockchain,
        recipientAddress: recipientAddress,
      }
    : {
        adapter: destinationAdapter,
        chain: destBlockchain,
      };

  // Execute bridge transfer using the correct BridgeKit API
  const result = await bridgeKit.bridge({
    from: fromContext,
    to: toContext,
    amount: amount,
    token: 'USDC',
    config: {}, // Use default config (standard speed)
  });

  return result;
}

/**
 * Convert numeric chain ID to Bridge Kit Blockchain enum value
 * Bridge Kit uses Blockchain enum for chain identification
 * 
 * @param chainId - Numeric chain ID
 * @returns Blockchain enum value or null if unsupported
 */
export function getBridgeKitBlockchain(chainId: number): Blockchain | null {
  // Map chain IDs to Blockchain enum values
  const chainIdMap: Record<number, Blockchain> = {
    // Testnets
    11155111: Blockchain.Ethereum_Sepolia, // Ethereum Sepolia
    84532: Blockchain.Base_Sepolia, // Base Sepolia
    421614: Blockchain.Arbitrum_Sepolia, // Arbitrum Sepolia
    11155420: Blockchain.Optimism_Sepolia, // Optimism Sepolia
    // Mainnets
    1: Blockchain.Ethereum, // Ethereum Mainnet
    8453: Blockchain.Base, // Base Mainnet
    42161: Blockchain.Arbitrum, // Arbitrum Mainnet
    10: Blockchain.Optimism, // Optimism Mainnet
  };

  return chainIdMap[chainId] || null;
}
