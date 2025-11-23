import { useState, useEffect, useCallback, useRef } from 'react';
import { ethers } from 'ethers';
import { CHAIN_CONFIG } from '@/config/contracts';
import {
  WalletType,
  WalletProviderInstance,
  connectWallet,
  disconnectWallet,
  getEthersProvider,
  getEthersSigner,
  setupWalletListeners,
} from '@/lib/walletProvider';

export function useWallet() {
  const [address, setAddress] = useState<string | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [chainId, setChainId] = useState<number | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [walletType, setWalletType] = useState<WalletType | null>(null);
  
  const walletProviderRef = useRef<WalletProviderInstance | null>(null);
  const cleanupRef = useRef<(() => void) | null>(null);

  // Disconnect wallet
  const disconnect = useCallback(async () => {
    // Cleanup listeners
    if (cleanupRef.current) {
      cleanupRef.current();
      cleanupRef.current = null;
    }

    // Disconnect wallet provider
    if (walletProviderRef.current) {
      await disconnectWallet(walletProviderRef.current);
      walletProviderRef.current = null;
    }

    // Clear state
    setAddress(null);
    setSigner(null);
    setProvider(null);
    setChainId(null);
    setError(null);
    setWalletType(null);

    // Clear localStorage
    if (typeof window !== 'undefined') {
      localStorage.removeItem('usdx_wallet_type');
    }
  }, []);

  // Connect wallet by type
  const connectByType = useCallback(async (type: WalletType) => {
    setIsConnecting(true);
    setError(null);
    
    try {
      // Connect to wallet
      const walletProvider = await connectWallet(type);
      walletProviderRef.current = walletProvider;
      setWalletType(type);

      // Get ethers provider and signer
      const ethersProvider = getEthersProvider(walletProvider.provider);
      const ethersSigner = await getEthersSigner(walletProvider.provider);
      
      // Get address and network
      const signerAddress = await ethersSigner.getAddress();
      const network = await ethersProvider.getNetwork();
      
      setProvider(ethersProvider);
      setSigner(ethersSigner);
      setAddress(signerAddress);
      setChainId(Number(network.chainId));

      // Setup event listeners
      cleanupRef.current = setupWalletListeners(walletProvider.provider, {
        onAccountsChanged: async (accounts) => {
          if (accounts.length === 0) {
            disconnect();
          } else {
            // Update address
            const newSigner = await getEthersSigner(walletProvider.provider);
            const newAddress = await newSigner.getAddress();
            setAddress(newAddress);
            setSigner(newSigner);
          }
        },
        onChainChanged: async (newChainId) => {
          const chainIdNum = typeof newChainId === 'string' 
            ? parseInt(newChainId, 16) 
            : newChainId;
          setChainId(chainIdNum);
          
          if (chainIdNum !== CHAIN_CONFIG.chainId) {
            setError(`Wrong network. Please switch to ${CHAIN_CONFIG.name}`);
          } else {
            setError(null);
          }
        },
        onDisconnect: () => {
          disconnect();
        },
      });

      // Store connection info in localStorage
      if (typeof window !== 'undefined') {
        localStorage.setItem('usdx_wallet_type', type);
      }
    } catch (err: any) {
      console.error('Failed to connect wallet:', err);
      setError(err.message || 'Failed to connect wallet');
      setIsConnecting(false);
      throw err;
    } finally {
      setIsConnecting(false);
    }
  }, [disconnect]);

  // Switch network
  const switchNetwork = useCallback(async (targetChainId: number) => {
    if (!walletProviderRef.current) {
      throw new Error('No wallet connected');
    }

    try {
      const walletProvider = walletProviderRef.current.provider;
      
      await walletProvider.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: `0x${targetChainId.toString(16)}` }],
      });
      
      setChainId(targetChainId);
      setError(null);
    } catch (err: any) {
      // If chain doesn't exist, try to add it
      if (err.code === 4902) {
        setError(`Chain ${targetChainId} not found. Please add it to your wallet.`);
      } else {
        setError(err.message || 'Failed to switch network');
      }
      throw err;
    }
  }, []);

  // Auto-reconnect on mount if previously connected
  useEffect(() => {
    if (typeof window === 'undefined') return;

    const savedWalletType = localStorage.getItem('usdx_wallet_type') as WalletType | null;
    
    if (savedWalletType) {
      // Try to reconnect
      connectByType(savedWalletType).catch((err) => {
        console.error('Auto-reconnect failed:', err);
        // Clear saved wallet type if reconnect fails
        localStorage.removeItem('usdx_wallet_type');
      });
    }
  }, [connectByType]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (cleanupRef.current) {
        cleanupRef.current();
      }
    };
  }, []);

  return {
    address,
    signer,
    provider,
    chainId,
    walletType,
    isConnected: !!address,
    isConnecting,
    isCorrectChain: chainId === CHAIN_CONFIG.chainId,
    error,
    connectByType,
    disconnect,
    switchNetwork,
  };
}
