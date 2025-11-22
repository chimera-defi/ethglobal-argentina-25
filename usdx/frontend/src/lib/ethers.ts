import { ethers } from 'ethers';
import { CHAIN_CONFIG } from '@/config/contracts';

// Get provider (read-only)
export function getProvider(): ethers.JsonRpcProvider {
  return new ethers.JsonRpcProvider(CHAIN_CONFIG.rpcUrl);
}

// Get browser provider (requires MetaMask or similar)
export async function getBrowserProvider(): Promise<ethers.BrowserProvider | null> {
  if (typeof window === 'undefined' || !window.ethereum) {
    return null;
  }
  return new ethers.BrowserProvider(window.ethereum);
}

// Get signer (requires wallet connection)
export async function getSigner(): Promise<ethers.Signer | null> {
  const provider = await getBrowserProvider();
  if (!provider) return null;
  return provider.getSigner();
}

// Request account access
export async function requestAccounts(): Promise<string[]> {
  if (typeof window === 'undefined' || !window.ethereum) {
    throw new Error('No Ethereum wallet found. Please install MetaMask.');
  }
  
  const accounts = await window.ethereum.request({
    method: 'eth_requestAccounts',
  });
  
  return accounts as string[];
}

// Switch to correct chain
export async function switchToChain(chainId: number): Promise<void> {
  if (typeof window === 'undefined' || !window.ethereum) {
    throw new Error('No Ethereum wallet found');
  }
  
  try {
    await window.ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: `0x${chainId.toString(16)}` }],
    });
  } catch (error: any) {
    // Chain doesn't exist, add it
    if (error.code === 4902) {
      await window.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [{
          chainId: `0x${chainId.toString(16)}`,
          chainName: CHAIN_CONFIG.name,
          rpcUrls: [CHAIN_CONFIG.rpcUrl],
        }],
      });
    } else {
      throw error;
    }
  }
}

// Listen for account changes
export function onAccountsChanged(callback: (accounts: string[]) => void): () => void {
  if (typeof window === 'undefined' || !window.ethereum) {
    return () => {};
  }
  
  const handler = (accounts: string[]) => callback(accounts);
  window.ethereum.on('accountsChanged', handler);
  
  return () => {
    window.ethereum?.removeListener('accountsChanged', handler);
  };
}

// Listen for chain changes
export function onChainChanged(callback: (chainId: string) => void): () => void {
  if (typeof window === 'undefined' || !window.ethereum) {
    return () => {};
  }
  
  const handler = (chainId: string) => callback(chainId);
  window.ethereum.on('chainChanged', handler);
  
  return () => {
    window.ethereum?.removeListener('chainChanged', handler);
  };
}

// Format address for display
export function formatAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

// Check if wallet is connected
export async function isConnected(): Promise<boolean> {
  if (typeof window === 'undefined' || !window.ethereum) {
    return false;
  }
  
  const accounts = await window.ethereum.request({ method: 'eth_accounts' });
  return accounts.length > 0;
}

// Declare ethereum on window
declare global {
  interface Window {
    ethereum?: any;
  }
}
