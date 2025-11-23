// Contract addresses for forked mainnet (localhost:8545)
export const CONTRACTS = {
  // Mock contracts
  MOCK_USDC: '0x1687d4BDE380019748605231C956335a473Fd3dc',
  MOCK_YEARN_VAULT: '0x9f3F78951bBf68fc3cBA976f1370a87B0Fc13cd4',
  
  // Hub chain (Ethereum)
  HUB_USDX: '0xF1a7a5060f22edA40b1A94a858995fa2bcf5E75A',
  HUB_VAULT: '0x18903fF6E49c98615Ab741aE33b5CD202Ccc0158',
  
  // Spoke chain (simulated Polygon on same network for MVP)
  SPOKE_USDX: '0xFb314854baCb329200778B82cb816CFB6500De9D',
  SPOKE_MINTER: '0x18eed2c26276A42c70E064D25d4f773c3626478e',
} as const;

// Chain-specific USDC addresses (Official Circle USDC contracts)
export const USDC_ADDRESSES: Record<number, string> = {
  // Testnet USDC addresses
  11155111: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238', // Ethereum Sepolia
  84532: '0x036CbD53842c5426634e7929541eC2318f3dCF7e',    // Base Sepolia
  421614: '0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d',   // Arbitrum Sepolia
  11155420: '0x5fd84259d66Cd46123540766Be93DFE6D43130D7', // Optimism Sepolia
  5042002: '0x0000000000000000000000000000000000000000', // Arc Testnet (USDC is native, placeholder)
  
  // Mainnet USDC addresses
  1: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',      // Ethereum Mainnet
  137: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359',    // Polygon Mainnet (USDC - bridged)
  8453: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',   // Base Mainnet
  42161: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',  // Arbitrum One
  10: '0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85',     // Optimism Mainnet
  
  // Localhost fallback (uses mock USDC)
  31337: '0x1687d4BDE380019748605231C956335a473Fd3dc',  // Localhost/Hardhat
};

/**
 * Get USDC contract address for a specific chain
 * @param chainId - The chain ID to get USDC address for
 * @returns USDC contract address or null if not supported
 */
export function getUSDCAddressForChain(chainId: number): string | null {
  return USDC_ADDRESSES[chainId] || null;
}

// Test account with pre-minted USDC
export const TEST_ACCOUNT = {
  address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
  // Note: This is Foundry's well-known test private key - ONLY for local testing
  privateKey: '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
};

// Chain configuration
export const CHAIN_CONFIG = {
  chainId: 1, // Ethereum mainnet (forked)
  name: 'Ethereum (Forked)',
  rpcUrl: 'http://localhost:8545',
};

// Contract decimals
export const DECIMALS = {
  USDC: 6,
  USDX: 6,
};

// Format amounts for display
export function formatAmount(amount: bigint, decimals: number = 6): string {
  const divisor = BigInt(10 ** decimals);
  const whole = amount / divisor;
  const fraction = amount % divisor;
  return `${whole}.${fraction.toString().padStart(decimals, '0')}`;
}

// Parse amounts from user input
export function parseAmount(amount: string, decimals: number = 6): bigint {
  const [whole, fraction = '0'] = amount.split('.');
  const paddedFraction = fraction.padEnd(decimals, '0').slice(0, decimals);
  return BigInt(whole) * BigInt(10 ** decimals) + BigInt(paddedFraction);
}
