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
  // Spoke chains - users can mint USDX on these chains using hub positions
  SPOKE_BASE: {
    id: 84532, // Base Sepolia testnet (Bridge Kit + LayerZero supported)
    name: 'Base Sepolia',
    rpcUrl: process.env.NEXT_PUBLIC_SPOKE_RPC_URL || 'https://sepolia.base.org',
    currency: 'ETH',
    blockExplorer: 'https://sepolia-explorer.base.org',
    // Localhost fallback for development (forks Base Mainnet)
    localhost: {
      id: 8453, // Base Mainnet (matches start-multi-chain.sh fork)
      rpcUrl: 'http://localhost:8546',
      blockExplorer: 'http://localhost:8546',
    },
  },
  SPOKE_POLYGON: {
    id: 137, // Polygon Mainnet (Bridge Kit + LayerZero supported)
    name: 'Polygon',
    rpcUrl: process.env.NEXT_PUBLIC_POLYGON_RPC_URL || 'https://polygon-rpc.com',
    currency: 'MATIC',
    blockExplorer: 'https://polygonscan.com',
    // Localhost fallback for development
    localhost: {
      id: 137,
      rpcUrl: 'http://localhost:8548',
      blockExplorer: 'http://localhost:8548',
    },
  },
  SPOKE_ARC: {
    id: 5042002, // Arc Testnet (Bridge Kit supported, LayerZero NOT supported)
    name: 'Arc Testnet',
    rpcUrl: process.env.NEXT_PUBLIC_ARC_RPC_URL || 'https://rpc.testnet.arc.network',
    currency: 'USDC', // USDC is native gas token on Arc
    blockExplorer: 'https://testnet.arcscan.app',
    // Localhost fallback for development
    localhost: {
      id: 5042002,
      rpcUrl: 'http://localhost:8547',
      blockExplorer: 'http://localhost:8547',
    },
  },
} as const;

// Legacy support - map old SPOKE to SPOKE_BASE
export const SPOKE = CHAINS.SPOKE_BASE;

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
  polygon: {
    id: 137,
    name: 'Polygon',
    rpcUrl: 'https://polygon-rpc.com',
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
  arcTestnet: {
    id: 5042002,
    name: 'Arc Testnet',
    rpcUrl: 'https://rpc.testnet.arc.network',
  },
  // Mainnets (commented for now)
  // mainnet: { id: 1, name: 'Ethereum Mainnet', rpcUrl: '...' },
  // base: { id: 8453, name: 'Base', rpcUrl: '...' },
  // arbitrum: { id: 42161, name: 'Arbitrum', rpcUrl: '...' },
  // optimism: { id: 10, name: 'Optimism', rpcUrl: '...' },
} as const;

export type ChainType = keyof typeof CHAINS;

// All spoke chains - add new spoke chains here
export const SPOKE_CHAINS = [
  CHAINS.SPOKE_BASE,
  CHAINS.SPOKE_POLYGON,
  CHAINS.SPOKE_ARC,
] as const;

export function getChainById(chainId: number): ChainType | null {
  if (chainId === CHAINS.HUB.id) return 'HUB';
  if (chainId === CHAINS.SPOKE_BASE.id) return 'SPOKE_BASE';
  if (chainId === CHAINS.SPOKE_POLYGON.id) return 'SPOKE_POLYGON';
  if (chainId === CHAINS.SPOKE_ARC.id) return 'SPOKE_ARC';
  return null;
}

export function isHubChain(chainId: number): boolean {
  return chainId === CHAINS.HUB.id;
}

export function isSpokeChain(chainId: number): boolean {
  return SPOKE_CHAINS.some(spoke => spoke.id === chainId);
}
