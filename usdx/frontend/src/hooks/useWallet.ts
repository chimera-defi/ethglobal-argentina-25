import { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import {
  requestAccounts,
  getSigner,
  getBrowserProvider,
  onAccountsChanged,
  onChainChanged,
  switchToChain,
  isConnected as checkIsConnected,
} from '@/lib/ethers';
import { CHAIN_CONFIG } from '@/config/contracts';

export function useWallet() {
  const [address, setAddress] = useState<string | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [chainId, setChainId] = useState<number | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Connect wallet
  const connect = useCallback(async () => {
    setIsConnecting(true);
    setError(null);
    
    try {
      const accounts = await requestAccounts();
      if (accounts.length === 0) {
        throw new Error('No accounts found');
      }
      
      const browserProvider = await getBrowserProvider();
      if (!browserProvider) {
        throw new Error('Could not get provider');
      }
      
      const signer = await getSigner();
      if (!signer) {
        throw new Error('Could not get signer');
      }
      
      const signerAddress = await signer.getAddress();
      const network = await browserProvider.getNetwork();
      
      setProvider(browserProvider);
      setSigner(signer);
      setAddress(signerAddress);
      setChainId(Number(network.chainId));
      
      // Check if we're on the correct chain
      if (Number(network.chainId) !== CHAIN_CONFIG.chainId) {
        await switchToChain(CHAIN_CONFIG.chainId);
      }
    } catch (err: any) {
      console.error('Failed to connect wallet:', err);
      setError(err.message || 'Failed to connect wallet');
    } finally {
      setIsConnecting(false);
    }
  }, []);

  // Disconnect wallet
  const disconnect = useCallback(() => {
    setAddress(null);
    setSigner(null);
    setProvider(null);
    setChainId(null);
    setError(null);
  }, []);

  // Switch network
  const switchNetwork = useCallback(async (targetChainId: number) => {
    try {
      await switchToChain(targetChainId);
      setChainId(targetChainId);
    } catch (err: any) {
      setError(err.message || 'Failed to switch network');
      throw err;
    }
  }, []);

  // Check connection on mount
  useEffect(() => {
    checkIsConnected().then((connected) => {
      if (connected) {
        connect();
      }
    });
  }, [connect]);

  // Listen for account changes
  useEffect(() => {
    const cleanup = onAccountsChanged((accounts) => {
      if (accounts.length === 0) {
        disconnect();
      } else {
        connect();
      }
    });
    
    return cleanup;
  }, [connect, disconnect]);

  // Listen for chain changes
  useEffect(() => {
    const cleanup = onChainChanged((newChainId) => {
      const chainIdNum = parseInt(newChainId, 16);
      setChainId(chainIdNum);
      
      if (chainIdNum !== CHAIN_CONFIG.chainId) {
        setError(`Wrong network. Please switch to ${CHAIN_CONFIG.name}`);
      } else {
        setError(null);
      }
    });
    
    return cleanup;
  }, []);

  return {
    address,
    signer,
    provider,
    chainId,
    isConnected: !!address,
    isConnecting,
    isCorrectChain: chainId === CHAIN_CONFIG.chainId,
    error,
    connect,
    disconnect,
    switchNetwork,
  };
}
