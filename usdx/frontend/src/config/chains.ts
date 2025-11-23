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
  ARC: {
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

export function getChainById(chainId: number): ChainType | null {
  if (chainId === CHAINS.HUB.id) return 'HUB';
  if (chainId === CHAINS.SPOKE.id) return 'SPOKE';
  if (chainId === CHAINS.ARC.id) return 'ARC';
  return null;
}

export function isHubChain(chainId: number): boolean {
  return chainId === CHAINS.HUB.id;
}

export function isSpokeChain(chainId: number): boolean {
  return chainId === CHAINS.SPOKE.id || chainId === CHAINS.ARC.id;
}
