import { ethers } from 'ethers';
import { CONTRACTS } from '@/config/contracts';

// Import ABIs
import USDXTokenABI from '@/abis/USDXToken.json';
import USDXVaultABI from '@/abis/USDXVault.json';
import USDXSpokeMinterABI from '@/abis/USDXSpokeMinter.json';
import MockUSDCABI from '@/abis/MockUSDC.json';

// Contract instances (read-only with provider, or with signer for transactions)

export function getUSDCContract(signerOrProvider: ethers.Signer | ethers.Provider) {
  return new ethers.Contract(
    CONTRACTS.MOCK_USDC,
    MockUSDCABI,
    signerOrProvider
  );
}

export function getHubUSDXContract(signerOrProvider: ethers.Signer | ethers.Provider) {
  return new ethers.Contract(
    CONTRACTS.HUB_USDX,
    USDXTokenABI,
    signerOrProvider
  );
}

export function getHubVaultContract(signerOrProvider: ethers.Signer | ethers.Provider) {
  return new ethers.Contract(
    CONTRACTS.HUB_VAULT,
    USDXVaultABI,
    signerOrProvider
  );
}

export function getSpokeUSDXContract(signerOrProvider: ethers.Signer | ethers.Provider) {
  return new ethers.Contract(
    CONTRACTS.SPOKE_USDX,
    USDXTokenABI,
    signerOrProvider
  );
}

export function getSpokeMinterContract(signerOrProvider: ethers.Signer | ethers.Provider) {
  return new ethers.Contract(
    CONTRACTS.SPOKE_MINTER,
    USDXSpokeMinterABI,
    signerOrProvider
  );
}

// Helper to wait for transaction with better error handling
export async function waitForTransaction(
  tx: ethers.ContractTransactionResponse,
  confirmations: number = 1
): Promise<ethers.ContractTransactionReceipt | null> {
  try {
    const receipt = await tx.wait(confirmations);
    return receipt;
  } catch (error) {
    console.error('Transaction failed:', error);
    throw error;
  }
}

// Helper to estimate gas with buffer
export async function estimateGasWithBuffer(
  contract: ethers.Contract,
  method: string,
  args: any[],
  bufferPercent: number = 20
): Promise<bigint> {
  const estimated = await contract[method].estimateGas(...args);
  return (estimated * BigInt(100 + bufferPercent)) / BigInt(100);
}
