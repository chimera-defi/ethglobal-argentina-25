import hre from "hardhat";
import { ethers } from "hardhat";

/**
 * @title Local Testnet Setup Script
 * @notice Complete setup script for local testing with Hardhat Ignition
 * @dev This script:
 *      1. Deploys all mock contracts and USDX contracts
 *      2. Sets up permissions
 *      3. Funds a user account with ETH, USDC, and USDX
 *      4. Reports all addresses and balances
 * 
 * Run with: npx hardhat run scripts/setup-local-testnet.ts --network hardhat
 */
async function main() {
  console.log("\n=== USDX Local Testnet Setup ===\n");
  
  // Get signers
  const [deployer, user] = await ethers.getSigners();
  
  console.log("Deployer:", deployer.address);
  console.log("User:", user.address);
  console.log("Deployer Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");
  console.log("User Balance:", ethers.formatEther(await ethers.provider.getBalance(user.address)), "ETH\n");
  
  // Deploy using Hardhat Ignition
  const result = await hre.ignition.deploy("ignition/modules/LocalTestnetSetup.ts", {
    parameters: {
      LocalTestnetSetup: {
        userAddress: user.address,
        ethAmount: ethers.parseEther("10").toString(),
        usdcAmount: ethers.parseUnits("100000", 6).toString(), // 100k USDC
        usdxAmount: ethers.parseUnits("50000", 6).toString(), // 50k USDX
        localEid: 30101,
      },
    },
  });
  
  // Access deployed contracts from result
  const mockUSDCAddress = result.LocalTestnetSetup.MockUSDC;
  const mockYearnVaultAddress = result.LocalTestnetSetup.MockYearnVault;
  const mockLayerZeroEndpointAddress = result.LocalTestnetSetup.MockLayerZeroEndpoint;
  const usdxTokenAddress = result.LocalTestnetSetup.USDXToken;
  const usdxVaultAddress = result.LocalTestnetSetup.USDXVault;
  
  const mockUSDC = await ethers.getContractAt("MockUSDC", mockUSDCAddress);
  const mockYearnVault = await ethers.getContractAt("MockYearnVault", mockYearnVaultAddress);
  const mockLayerZeroEndpoint = await ethers.getContractAt(
    "MockLayerZeroEndpoint",
    mockLayerZeroEndpointAddress
  );
  const usdxToken = await ethers.getContractAt("USDXToken", usdxTokenAddress);
  const usdxVault = await ethers.getContractAt("USDXVault", usdxVaultAddress);
  
  // Send ETH to user (using hardhat_setBalance)
  const ethAmount = ethers.parseEther("10");
  await ethers.provider.send("hardhat_setBalance", [
    user.address,
    ethAmount.toHexString(),
  ]);
  
  // Get balances
  const userEthBalance = await ethers.provider.getBalance(user.address);
  const userUSDCBalance = await mockUSDC.balanceOf(user.address);
  const userUSDXBalance = await usdxToken.balanceOf(user.address);
  
  // Print deployment summary
  console.log("\n=== Deployment Summary ===\n");
  console.log("Mock Contracts:");
  console.log("  MockUSDC:", mockUSDCAddress);
  console.log("  MockYearnVault:", mockYearnVaultAddress);
  console.log("  MockLayerZeroEndpoint:", mockLayerZeroEndpointAddress);
  console.log("\nUSDX Contracts:");
  console.log("  USDXToken:", usdxTokenAddress);
  console.log("  USDXVault:", usdxVaultAddress);
  
  console.log("\n=== User Account Funding ===\n");
  console.log("User Address:", user.address);
  console.log("  ETH Balance:", ethers.formatEther(userEthBalance), "ETH");
  console.log("  USDC Balance:", ethers.formatUnits(userUSDCBalance, 6), "USDC");
  console.log("  USDX Balance:", ethers.formatUnits(userUSDXBalance, 6), "USDX");
  
  // Verify permissions
  console.log("\n=== Permissions Setup ===\n");
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("BURNER_ROLE"));
  
  const vaultHasMinterRole = await usdxToken.hasRole(MINTER_ROLE, usdxVaultAddress);
  const vaultHasBurnerRole = await usdxToken.hasRole(BURNER_ROLE, usdxVaultAddress);
  
  console.log("Vault has MINTER_ROLE:", vaultHasMinterRole);
  console.log("Vault has BURNER_ROLE:", vaultHasBurnerRole);
  
  // Verify Yearn vault setup
  const yearnVaultAddress = await usdxVault.yearnVault();
  console.log("Yearn Vault set:", yearnVaultAddress === mockYearnVaultAddress ? "✓" : "✗");
  
  // Verify LayerZero endpoint
  const lzEndpoint = await usdxToken.lzEndpoint();
  console.log("LayerZero Endpoint set:", lzEndpoint === mockLayerZeroEndpointAddress ? "✓" : "✗");
  
  console.log("\n=== Setup Complete! ===\n");
  console.log("You can now use these contracts for testing:");
  console.log(`  - USDC: ${mockUSDCAddress}`);
  console.log(`  - USDX: ${usdxTokenAddress}`);
  console.log(`  - Vault: ${usdxVaultAddress}`);
  console.log(`\nUser account (${user.address}) is funded and ready to use.\n`);
  
  // Save addresses to a file for easy reference
  const addresses = {
    deployer: deployer.address,
    user: user.address,
    contracts: {
      mockUSDC: mockUSDCAddress,
      mockYearnVault: mockYearnVaultAddress,
      mockLayerZeroEndpoint: mockLayerZeroEndpointAddress,
      usdxToken: usdxTokenAddress,
      usdxVault: usdxVaultAddress,
    },
    balances: {
      user: {
        eth: ethers.formatEther(userEthBalance),
        usdc: ethers.formatUnits(userUSDCBalance, 6),
        usdx: ethers.formatUnits(userUSDXBalance, 6),
      },
    },
  };
  
  console.log("=== Addresses JSON ===");
  console.log(JSON.stringify(addresses, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
