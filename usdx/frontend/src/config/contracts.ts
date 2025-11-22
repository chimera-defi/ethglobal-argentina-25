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
