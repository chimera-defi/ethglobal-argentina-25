import { ethers } from 'ethers';
import EthereumProvider from '@walletconnect/ethereum-provider';

export type WalletType = 'metamask' | 'walletconnect' | 'coinbase' | 'injected';

export interface WalletProviderInstance {
  provider: any;
  type: WalletType;
}

// WalletConnect configuration
// Only enable WalletConnect if a valid project ID is provided
const WALLETCONNECT_PROJECT_ID = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID;
const IS_WALLETCONNECT_ENABLED = !!WALLETCONNECT_PROJECT_ID && WALLETCONNECT_PROJECT_ID.length > 0;

// Supported chains for WalletConnect
const SUPPORTED_CHAINS = [
  1, // Ethereum Mainnet
  11155111, // Sepolia
  8453, // Base
  84532, // Base Sepolia
  137, // Polygon
  5042002, // Arc Testnet
];

/**
 * Detect available wallet providers
 */
export function detectWallets() {
  const wallets: { type: WalletType; name: string; available: boolean }[] = [];

  if (typeof window === 'undefined') {
    return wallets;
  }

  // MetaMask
  wallets.push({
    type: 'metamask',
    name: 'MetaMask',
    available: !!(window as any).ethereum?.isMetaMask,
  });

  // Coinbase Wallet
  wallets.push({
    type: 'coinbase',
    name: 'Coinbase Wallet',
    available: !!(window as any).ethereum?.isCoinbaseWallet,
  });

  // Generic injected wallet
  wallets.push({
    type: 'injected',
    name: 'Browser Wallet',
    available: !!(window as any).ethereum,
  });

  // WalletConnect (only available if project ID is configured)
  wallets.push({
    type: 'walletconnect',
    name: 'WalletConnect',
    available: IS_WALLETCONNECT_ENABLED,
  });

  return wallets;
}

/**
 * Connect to MetaMask
 */
async function connectMetaMask(): Promise<WalletProviderInstance> {
  if (typeof window === 'undefined' || !(window as any).ethereum) {
    throw new Error('MetaMask not found. Please install MetaMask extension.');
  }

  const ethereum = (window as any).ethereum;

  // Request accounts
  await ethereum.request({ method: 'eth_requestAccounts' });

  return {
    provider: ethereum,
    type: 'metamask',
  };
}

/**
 * Connect to Coinbase Wallet
 */
async function connectCoinbase(): Promise<WalletProviderInstance> {
  if (typeof window === 'undefined' || !(window as any).ethereum?.isCoinbaseWallet) {
    throw new Error('Coinbase Wallet not found. Please install Coinbase Wallet extension.');
  }

  const ethereum = (window as any).ethereum;

  // Request accounts
  await ethereum.request({ method: 'eth_requestAccounts' });

  return {
    provider: ethereum,
    type: 'coinbase',
  };
}

/**
 * Connect to generic injected wallet
 */
async function connectInjected(): Promise<WalletProviderInstance> {
  if (typeof window === 'undefined' || !(window as any).ethereum) {
    throw new Error('No wallet found. Please install a Web3 wallet extension.');
  }

  const ethereum = (window as any).ethereum;

  // Request accounts
  await ethereum.request({ method: 'eth_requestAccounts' });

  return {
    provider: ethereum,
    type: 'injected',
  };
}

/**
 * Connect to WalletConnect
 */
async function connectWalletConnect(): Promise<WalletProviderInstance> {
  if (!IS_WALLETCONNECT_ENABLED || !WALLETCONNECT_PROJECT_ID) {
    throw new Error('WalletConnect is not configured. Please set NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID environment variable.');
  }

  try {
    // Initialize WalletConnect provider with error handling
    const provider = await EthereumProvider.init({
      projectId: WALLETCONNECT_PROJECT_ID,
      chains: [SUPPORTED_CHAINS[0]], // Start with first chain
      optionalChains: SUPPORTED_CHAINS.slice(1), // Add other chains as optional
      showQrModal: true,
      qrModalOptions: {
        themeMode: 'light',
        themeVariables: {
          '--wcm-z-index': '9999',
        },
      },
      metadata: {
        name: 'USDX Protocol',
        description: 'Omnichain Vault-Backed Stablecoin',
        url: typeof window !== 'undefined' ? window.location.origin : 'https://usdx.io',
        icons: ['https://usdx.io/icon.png'],
      },
    });

    // Enable session (triggers QR Code modal) with timeout
    const enablePromise = provider.enable();
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('WalletConnect connection timeout. Please try again.')), 30000);
    });

    await Promise.race([enablePromise, timeoutPromise]);

    return {
      provider,
      type: 'walletconnect',
    };
  } catch (error: any) {
    // Clean up on error
    if (error?.message?.includes('User rejected') || error?.message?.includes('User closed')) {
      throw new Error('Connection cancelled by user');
    }
    if (error?.message?.includes('Project not found') || error?.code === 3000) {
      throw new Error('WalletConnect project ID is invalid. Please configure a valid NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID.');
    }
    throw new Error(error?.message || 'Failed to connect with WalletConnect. Please try again.');
  }
}

/**
 * Connect to wallet by type
 */
export async function connectWallet(type: WalletType): Promise<WalletProviderInstance> {
  switch (type) {
    case 'metamask':
      return connectMetaMask();
    case 'coinbase':
      return connectCoinbase();
    case 'walletconnect':
      return connectWalletConnect();
    case 'injected':
      return connectInjected();
    default:
      throw new Error(`Unsupported wallet type: ${type}`);
  }
}

/**
 * Get ethers provider from wallet provider
 */
export function getEthersProvider(walletProvider: any): ethers.BrowserProvider {
  return new ethers.BrowserProvider(walletProvider);
}

/**
 * Get signer from wallet provider
 */
export async function getEthersSigner(walletProvider: any): Promise<ethers.Signer> {
  const provider = getEthersProvider(walletProvider);
  return provider.getSigner();
}

/**
 * Disconnect wallet
 */
export async function disconnectWallet(walletProvider: WalletProviderInstance | null): Promise<void> {
  if (!walletProvider) return;

  // For WalletConnect, we need to explicitly disconnect
  if (walletProvider.type === 'walletconnect' && walletProvider.provider?.disconnect) {
    await walletProvider.provider.disconnect();
  }

  // Clear any stored connection data
  if (typeof window !== 'undefined') {
    localStorage.removeItem('walletconnect');
    localStorage.removeItem('WALLETCONNECT_DEEPLINK_CHOICE');
  }
}

/**
 * Setup event listeners for wallet provider
 */
export function setupWalletListeners(
  walletProvider: any,
  callbacks: {
    onAccountsChanged?: (accounts: string[]) => void;
    onChainChanged?: (chainId: string) => void;
    onDisconnect?: () => void;
  }
): () => void {
  if (!walletProvider) {
    return () => {};
  }

  const cleanupFunctions: Array<() => void> = [];

  // Accounts changed
  if (callbacks.onAccountsChanged) {
    const accountsHandler = (accounts: string[]) => {
      callbacks.onAccountsChanged!(accounts);
    };
    walletProvider.on('accountsChanged', accountsHandler);
    cleanupFunctions.push(() => {
      walletProvider.removeListener('accountsChanged', accountsHandler);
    });
  }

  // Chain changed
  if (callbacks.onChainChanged) {
    const chainHandler = (chainId: string) => {
      callbacks.onChainChanged!(chainId);
    };
    walletProvider.on('chainChanged', chainHandler);
    cleanupFunctions.push(() => {
      walletProvider.removeListener('chainChanged', chainHandler);
    });
  }

  // Disconnect
  if (callbacks.onDisconnect) {
    const disconnectHandler = () => {
      callbacks.onDisconnect!();
    };
    walletProvider.on('disconnect', disconnectHandler);
    cleanupFunctions.push(() => {
      walletProvider.removeListener('disconnect', disconnectHandler);
    });
  }

  // Return cleanup function
  return () => {
    cleanupFunctions.forEach(cleanup => cleanup());
  };
}
