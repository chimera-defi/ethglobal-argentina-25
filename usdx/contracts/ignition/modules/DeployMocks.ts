import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * @title DeployMocks Ignition Module
 * @notice Deploys mock contracts for testing (USDC, Yearn Vault, LayerZero Endpoint)
 * @dev This module should be deployed before DeployHub
 * 
 * Run with: npx hardhat ignition deploy ignition/modules/DeployMocks.ts --network hardhat
 */
export default buildModule("DeployMocks", (m) => {
  const deployer = m.getAccount(0);
  
  // Deploy MockUSDC
  const mockUSDC = m.contract("MockUSDC", [], {
    id: "MockUSDC",
  });
  
  // Deploy MockYearnVault (needs USDC address)
  const mockYearnVault = m.contract(
    "MockYearnVault",
    [mockUSDC],
    {
      id: "MockYearnVault",
      after: [mockUSDC],
    }
  );
  
  // Deploy MockLayerZeroEndpoint
  // Ethereum Local EID: 30101
  const localEid = m.getParameter("localEid", 30101);
  const mockLayerZeroEndpoint = m.contract(
    "MockLayerZeroEndpoint",
    [localEid],
    {
      id: "MockLayerZeroEndpoint",
    }
  );
  
  return {
    mockUSDC,
    mockYearnVault,
    mockLayerZeroEndpoint,
  };
});
