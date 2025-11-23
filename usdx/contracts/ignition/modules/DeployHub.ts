import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";

/**
 * @title DeployHub Ignition Module
 * @notice Hardhat Ignition deployment module for USDX Hub Chain contracts
 * @dev This complements Foundry Scripts with Hardhat Ignition's deployment orchestration
 * 
 * Run with: npx hardhat ignition deploy ignition/modules/DeployHub.ts --network sepolia
 */
export default buildModule("DeployHub", (m) => {
  // Get deployer account
  const deployer = m.getAccount(0);
  
  // Configuration - can be overridden via parameters
  const usdcAddress = m.getParameter("usdcAddress", "0x0000000000000000000000000000000000000000");
  const treasuryAddress = m.getParameter("treasuryAddress", deployer);
  const yearnVaultAddress = m.getParameter("yearnVaultAddress", "0x0000000000000000000000000000000000000000");
  
  // Deploy USDXToken
  const usdxToken = m.contract("USDXToken", [deployer], {
    id: "USDXToken",
  });
  
  // Deploy USDXVault
  const usdxVault = m.contract(
    "USDXVault",
    [
      usdcAddress,
      usdxToken,
      treasuryAddress,
      deployer,
      "0x0000000000000000000000000000000000000000", // ovaultComposer (set later)
      "0x0000000000000000000000000000000000000000", // shareOFTAdapter (set later)
      "0x0000000000000000000000000000000000000000", // vaultWrapper (set later)
    ],
    {
      id: "USDXVault",
    }
  );
  
  // Grant roles to vault
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("BURNER_ROLE"));
  
  m.call(usdxToken, "grantRole", [MINTER_ROLE, usdxVault], {
    id: "GrantMinterRole",
    after: [usdxVault],
  });
  
  m.call(usdxToken, "grantRole", [BURNER_ROLE, usdxVault], {
    id: "GrantBurnerRole",
    after: [usdxVault],
  });
  
  // Set Yearn vault if provided
  if (yearnVaultAddress !== "0x0000000000000000000000000000000000000000") {
    m.call(usdxVault, "setYearnVault", [yearnVaultAddress], {
      id: "SetYearnVault",
      after: [usdxVault],
    });
  }
  
  return {
    usdxToken,
    usdxVault,
  };
});
