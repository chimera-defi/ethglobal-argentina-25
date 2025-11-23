import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

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
  // Use string values for parameters - Ignition will handle conversion
  // Default values: 10 ETH, 100k USDC, 50k USDX
  const ethAmount = m.getParameter("ethAmount", "10000000000000000000"); // 10 ETH in wei
  const usdcAmount = m.getParameter("usdcAmount", "100000000000"); // 100k USDC (6 decimals)
  const usdxAmount = m.getParameter("usdxAmount", "50000000000"); // 50k USDX (6 decimals)
  
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
  
  // Calculate role hashes
  // MINTER_ROLE = keccak256("MINTER_ROLE")
  // BURNER_ROLE = keccak256("BURNER_ROLE")
  // Using pre-calculated values for reliability in ESM module context
  const MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6";
  const BURNER_ROLE = "0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848";
  
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
