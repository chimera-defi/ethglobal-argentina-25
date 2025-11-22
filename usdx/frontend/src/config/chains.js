// Multi-chain configuration for USDX Protocol
// Supports both localhost (for development) and testnet/mainnet chains

export const CHAINS = {
  HUB: {
    id: 11155111, // Sepolia testnet (Bridge Kit supported)
    name: 'USDX Hub (Ethereum Sepolia)',
    rpcUrl: process.env.NEXT_PUBLIC_HUB_RPC_URL || 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY',
    currency: 'ETH',
    blockExplorer: 'https://sepolia.etherscan.io',
    // Localhost fallback for development
    localhost: {
      id: 1,
      rpcUrl: 'http://localhost:8545',
      blockExplorer: 'http://localhost:8545',
    },
  },
  SPOKE: {
    id: 84532, // Base Sepolia testnet (Bridge Kit supported)
    name: 'USDX Spoke (Base Sepolia)',
    rpcUrl: process.env.NEXT_PUBLIC_SPOKE_RPC_URL || 'https://sepolia.base.org',
    currency: 'ETH',
    blockExplorer: 'https://sepolia-explorer.base.org',
    // Localhost fallback for development
    localhost: {
      id: 137,
      rpcUrl: 'http://localhost:8546',
      blockExplorer: 'http://localhost:8546',
    },
  },
};

// Bridge Kit supported chains
export const BRIDGE_KIT_CHAINS = {
  // Testnets
  sepolia: {
    id: 11155111,
    name: 'Ethereum Sepolia',
    rpcUrl: 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY',
  },
  baseSepolia: {
    id: 84532,
    name: 'Base Sepolia',
    rpcUrl: 'https://sepolia.base.org',
  },
  arbitrumSepolia: {
    id: 421614,
    name: 'Arbitrum Sepolia',
    rpcUrl: 'https://sepolia-rollup.arbitrum.io/rpc',
  },
  optimismSepolia: {
    id: 11155420,
    name: 'Optimism Sepolia',
    rpcUrl: 'https://sepolia.optimism.io',
  },
};

export function getChainById(chainId) {
  if (chainId === CHAINS.HUB.id) return 'HUB';
  if (chainId === CHAINS.SPOKE.id) return 'SPOKE';
  return null;
}

export function isHubChain(chainId) {
  return chainId === CHAINS.HUB.id;
}

export function isSpokeChain(chainId) {
  return chainId === CHAINS.SPOKE.id;
}
