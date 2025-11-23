import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import hre from "hardhat";

/**
 * @title DeployHub Ignition Module
 * @notice Deploys USDX Hub Chain contracts (Token and Vault)
 * @dev This module handles the complete hub deployment with proper dependency management
 * 
 * Run with: npx hardhat ignition deploy ignition/modules/DeployHub.ts --network sepolia
 */
export default buildModule("DeployHub", (m) => {
  const deployer = m.getAccount(0);
  
  // Get parameters (can be overridden via --parameters)
  const usdcAddress = m.getParameter("usdcAddress", "0x0000000000000000000000000000000000000000");
  const treasuryAddress = m.getParameter("treasuryAddress", deployer);
  const yearnVaultAddress = m.getParameter("yearnVaultAddress", "0x0000000000000000000000000000000000000000");
  const localEid = m.getParameter("localEid", 30101);
  
  // Deploy USDXToken
  const usdxToken = m.contract("USDXToken", [deployer], {
    id: "USDXToken",
  });
  
  // Deploy USDXVault
  // Note: OVault components are optional and can be set to zero address for MVP
  const usdxVault = m.contract(
    "USDXVault",
    [
      usdcAddress,
      usdxToken,
      treasuryAddress,
      deployer, // admin
      "0x0000000000000000000000000000000000000000", // ovaultComposer (optional)
      "0x0000000000000000000000000000000000000000", // shareOFTAdapter (optional)
      "0x0000000000000000000000000000000000000000", // vaultWrapper (optional)
    ],
    {
      id: "USDXVault",
      after: [usdxToken],
    }
  );
  
  // Grant roles to vault
  const { ethers } = hre;
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
  
  // Set LayerZero endpoint if provided
  const lzEndpointAddress = m.getParameter("lzEndpointAddress", "0x0000000000000000000000000000000000000000");
  if (lzEndpointAddress !== "0x0000000000000000000000000000000000000000") {
    m.call(usdxToken, "setLayerZeroEndpoint", [lzEndpointAddress, localEid], {
      id: "SetLayerZeroEndpoint",
      after: [usdxToken],
    });
  }
  
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
