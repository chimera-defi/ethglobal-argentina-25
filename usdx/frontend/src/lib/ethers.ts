import { ethers } from 'ethers';
import { CHAIN_CONFIG } from '@/config/contracts';

// Get browser provider (MetaMask, etc.)
export async function getBrowserProvider(): Promise<ethers.BrowserProvider | null> {
  if (typeof window === 'undefined' || !window.ethereum) {
    return null;
  }
  return new ethers.BrowserProvider(window.ethereum);
}

// Get provider for read-only operations
export function getProvider(): ethers.JsonRpcProvider {
  return new ethers.JsonRpcProvider(CHAIN_CONFIG.rpcUrl);
}

// Get signer from browser provider
export async function getSigner(): Promise<ethers.Signer | null> {
  const provider = await getBrowserProvider();
  if (!provider) return null;
  return provider.getSigner();
}

// Request accounts from wallet
export async function requestAccounts(): Promise<string[]> {
  if (typeof window === 'undefined' || !window.ethereum) {
    throw new Error('No wallet found');
  }
  return await window.ethereum.request({ method: 'eth_requestAccounts' });
}

// Check if wallet is connected
export async function isConnected(): Promise<boolean> {
  if (typeof window === 'undefined' || !window.ethereum) {
    return false;
  }
  const accounts = await window.ethereum.request({ method: 'eth_accounts' });
  return accounts.length > 0;
}

// Switch to a specific chain
export async function switchToChain(chainId: number): Promise<void> {
  if (typeof window === 'undefined' || !window.ethereum) {
    throw new Error('No wallet found');
  }
  
  try {
    await window.ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: `0x${chainId.toString(16)}` }],
    });
  } catch (error: any) {
    // If chain doesn't exist, try to add it
    if (error.code === 4902) {
      throw new Error(`Chain ${chainId} not found. Please add it to your wallet.`);
    }
    throw error;
  }
}

// Listen for account changes
export function onAccountsChanged(callback: (accounts: string[]) => void): () => void {
  if (typeof window === 'undefined' || !window.ethereum) {
    return () => {};
  }
  
  window.ethereum.on('accountsChanged', callback);
  
  return () => {
    if (window.ethereum) {
      window.ethereum.removeListener('accountsChanged', callback);
    }
  };
}

// Listen for chain changes
export function onChainChanged(callback: (chainId: string) => void): () => void {
  if (typeof window === 'undefined' || !window.ethereum) {
    return () => {};
  }
  
  window.ethereum.on('chainChanged', callback);
  
  return () => {
    if (window.ethereum) {
      window.ethereum.removeListener('chainChanged', callback);
    }
  };
}

// Format address for display
export function formatAddress(address: string): string {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

// Declare window.ethereum type
declare global {
  interface Window {
    ethereum?: {
      request: (args: { method: string; params?: any[] }) => Promise<any>;
      on: (event: string, callback: (...args: any[]) => void) => void;
      removeListener: (event: string, callback: (...args: any[]) => void) => void;
    };
  }
}
