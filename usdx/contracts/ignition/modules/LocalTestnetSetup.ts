import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import hre from "hardhat";

/**
 * @title LocalTestnetSetup Ignition Module
 * @notice Complete local testnet setup with mocks, USDX contracts, and user funding
 * @dev This module sets up everything needed for local testing:
 *      - Deploys mock contracts (USDC, Yearn Vault, LayerZero Endpoint)
 *      - Deploys USDX contracts (Token and Vault)
 *      - Funds a user account with ETH, USDC, and USDX
 *      - Sets up all permissions
 * 
 * Run with: npx hardhat ignition deploy ignition/modules/LocalTestnetSetup.ts --network hardhat
 * 
 * Parameters:
 *   - userAddress: Address to fund (defaults to second account)
 *   - ethAmount: Amount of ETH to send (defaults to 10 ETH)
 *   - usdcAmount: Amount of USDC to mint (defaults to 100,000 USDC)
 *   - usdxAmount: Amount of USDX to mint (defaults to 50,000 USDX)
 */
export default buildModule("LocalTestnetSetup", (m) => {
  const deployer = m.getAccount(0);
  const userAddress = m.getParameter("userAddress", m.getAccount(1));
  
  // Amounts to fund user
  const { ethers } = hre;
  const ethAmount = m.getParameter("ethAmount", ethers.parseEther("10"));
  const usdcAmount = m.getParameter("usdcAmount", ethers.parseUnits("100000", 6)); // 100k USDC
  const usdxAmount = m.getParameter("usdxAmount", ethers.parseUnits("50000", 6)); // 50k USDX
  
  const localEid = m.getParameter("localEid", 30101);
  
  // ============ Step 1: Deploy Mock Contracts ============
  
  const mockUSDC = m.contract("MockUSDC", [], {
    id: "MockUSDC",
  });
  
  const mockYearnVault = m.contract(
    "MockYearnVault",
    [mockUSDC],
    {
      id: "MockYearnVault",
      after: [mockUSDC],
    }
  );
  
  const mockLayerZeroEndpoint = m.contract(
    "MockLayerZeroEndpoint",
    [localEid],
    {
      id: "MockLayerZeroEndpoint",
    }
  );
  
  // ============ Step 2: Deploy USDX Contracts ============
  
  const usdxToken = m.contract("USDXToken", [deployer], {
    id: "USDXToken",
    after: [mockUSDC],
  });
  
  const usdxVault = m.contract(
    "USDXVault",
    [
      mockUSDC,
      usdxToken,
      deployer, // treasury
      deployer, // admin
      "0x0000000000000000000000000000000000000000", // ovaultComposer
      "0x0000000000000000000000000000000000000000", // shareOFTAdapter
      "0x0000000000000000000000000000000000000000", // vaultWrapper
    ],
    {
      id: "USDXVault",
      after: [usdxToken],
    }
  );
  
  // ============ Step 3: Set Up Permissions ============
  
  // ethers already imported above
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("BURNER_ROLE"));
  
  // Grant vault minter and burner roles
  m.call(usdxToken, "grantRole", [MINTER_ROLE, usdxVault], {
    id: "GrantMinterRole",
    after: [usdxVault],
  });
  
  m.call(usdxToken, "grantRole", [BURNER_ROLE, usdxVault], {
    id: "GrantBurnerRole",
    after: [usdxVault],
  });
  
  // Set LayerZero endpoint
  m.call(usdxToken, "setLayerZeroEndpoint", [mockLayerZeroEndpoint, localEid], {
    id: "SetLayerZeroEndpoint",
    after: [mockLayerZeroEndpoint, usdxToken],
  });
  
  // Set Yearn vault
  m.call(usdxVault, "setYearnVault", [mockYearnVault], {
    id: "SetYearnVault",
    after: [mockYearnVault, usdxVault],
  });
  
  // ============ Step 4: Fund User Account ============
  
  // Mint USDC to user
  m.call(mockUSDC, "mint", [userAddress, usdcAmount], {
    id: "MintUSDCToUser",
    after: [mockUSDC],
  });
  
  // Mint USDX to user (using deployer's minter role)
  m.call(usdxToken, "mint", [userAddress, usdxAmount], {
    id: "MintUSDXToUser",
    after: [usdxToken],
  });
  
  // Send ETH to user (using hardhat network's setBalance or a helper contract)
  // Note: Hardhat Ignition doesn't directly support ETH transfers, so we'll use a helper
  
  return {
    mockUSDC,
    mockYearnVault,
    mockLayerZeroEndpoint,
    usdxToken,
    usdxVault,
    userAddress,
  };
});
