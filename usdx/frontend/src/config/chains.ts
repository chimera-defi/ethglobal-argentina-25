// Multi-chain configuration for USDX Protocol

export const CHAINS = {
  HUB: {
    id: 1,
    name: 'USDX Hub (Ethereum)',
    rpcUrl: 'http://localhost:8545',
    currency: 'ETH',
    blockExplorer: 'http://localhost:8545',
  },
  SPOKE: {
    id: 137,
    name: 'USDX Spoke (Polygon)',
    rpcUrl: 'http://localhost:8546',
    currency: 'MATIC',
    blockExplorer: 'http://localhost:8546',
  },
} as const;

export type ChainType = keyof typeof CHAINS;

// Contract addresses per chain
export const CONTRACTS = {
  HUB: {
    MOCK_USDC: '', // Set after deployment
    MOCK_YEARN_VAULT: '',
    USDX_TOKEN: '',
    VAULT: '',
  },
  SPOKE: {
    USDX_TOKEN: '',
    MINTER: '',
  },
};

// Load from deployment files if available
if (typeof window !== 'undefined') {
  // These will be populated from deployment JSON files
  // For now, use placeholder values
}

export function getChainById(chainId: number): ChainType | null {
  if (chainId === CHAINS.HUB.id) return 'HUB';
  if (chainId === CHAINS.SPOKE.id) return 'SPOKE';
  return null;
}

export function isHubChain(chainId: number): boolean {
  return chainId === CHAINS.HUB.id;
}

export function isSpokeChain(chainId: number): boolean {
  return chainId === CHAINS.SPOKE.id;
}
