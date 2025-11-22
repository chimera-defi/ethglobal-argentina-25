import { ethers } from 'ethers';
import { CONTRACTS } from '@/config/contracts';
import USDXVaultABI from '@/abis/USDXVault.json';
import USDXTokenABI from '@/abis/USDXToken.json';
import USDXSpokeMinterABI from '@/abis/USDXSpokeMinter.json';
import MockUSDCABI from '@/abis/MockUSDC.json';

// Get USDC contract instance
export function getUSDCContract(signerOrProvider: ethers.Signer | ethers.Provider): ethers.Contract {
  return new ethers.Contract(
    CONTRACTS.MOCK_USDC,
    MockUSDCABI as any,
    signerOrProvider
  );
}

// Get Hub USDX token contract
export function getHubUSDXContract(signerOrProvider: ethers.Signer | ethers.Provider): ethers.Contract {
  return new ethers.Contract(
    CONTRACTS.HUB_USDX,
    USDXTokenABI as any,
    signerOrProvider
  );
}

// Get Spoke USDX token contract
export function getSpokeUSDXContract(signerOrProvider: ethers.Signer | ethers.Provider): ethers.Contract {
  return new ethers.Contract(
    CONTRACTS.SPOKE_USDX,
    USDXTokenABI as any,
    signerOrProvider
  );
}

// Get Hub Vault contract
export function getHubVaultContract(signerOrProvider: ethers.Signer | ethers.Provider): ethers.Contract {
  return new ethers.Contract(
    CONTRACTS.HUB_VAULT,
    USDXVaultABI as any,
    signerOrProvider
  );
}

// Get Spoke Minter contract
export function getSpokeMinterContract(signerOrProvider: ethers.Signer | ethers.Provider): ethers.Contract {
  return new ethers.Contract(
    CONTRACTS.SPOKE_MINTER,
    USDXSpokeMinterABI as any,
    signerOrProvider
  );
}

// Wait for transaction and return receipt
export async function waitForTransaction(
  tx: ethers.ContractTransactionResponse
): Promise<ethers.ContractTransactionReceipt | null> {
  if (!tx) return null;
  return await tx.wait();
}
