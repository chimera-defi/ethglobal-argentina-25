import hre from "hardhat";
// Import plugins explicitly to ensure they're loaded
import "@nomicfoundation/hardhat-ignition";
import "@nomicfoundation/hardhat-ignition-ethers";

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
 * 
 * Note: This script requires Hardhat3 plugins to be loaded. When run via `hardhat run`,
 * the plugins (@nomicfoundation/hardhat-ethers, @nomicfoundation/hardhat-ignition) 
 * are automatically available through hre.
 */
async function main() {
  console.log("\n=== USDX Local Testnet Setup ===\n");
  
  // Import ethers - in Hardhat3, ethers plugin provides hre.ethers when plugins are loaded
  // For Hardhat network (edr-simulated), we need to use the network's provider
  const { ethers } = await import("ethers");
  
  // Create an ethers provider wrapper for the Hardhat network
  // Hardhat3 uses EDR (Ethereum Development Runtime) which has a different provider interface
  // For local testing, we use a JsonRpcProvider that connects to Hardhat's internal network
  // When running via `hardhat run`, the network is automatically available
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  
  // Hardhat's default accounts (for local testing)
  // Account 0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  // Account 1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
  const deployerPrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  const userPrivateKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
  
  const deployer = new ethers.Wallet(deployerPrivateKey, provider);
  const user = new ethers.Wallet(userPrivateKey, provider);
  
  console.log("Deployer:", deployer.address);
  console.log("User:", user.address);
  
  // Check initial balances
  try {
    const deployerBalance = await provider.getBalance(deployer.address);
    const userBalance = await provider.getBalance(user.address);
    console.log("Deployer Balance:", ethers.formatEther(deployerBalance), "ETH");
    console.log("User Balance:", ethers.formatEther(userBalance), "ETH\n");
  } catch (error) {
    console.log("Note: Hardhat network may not be running. Starting deployment anyway...\n");
  }
  
  // Deploy using Hardhat Ignition Core API directly
  // This matches the internal task implementation
  console.log("Deploying contracts using Hardhat Ignition...\n");
  
  // Import required modules
  const { deploy } = await import("@nomicfoundation/ignition-core");
  const helpers = await import("@nomicfoundation/hardhat-ignition/helpers");
  const HardhatArtifactResolver = helpers.HardhatArtifactResolver;
  const path = await import("path");
  
  // Load module using the internal utility (we'll need to access it differently)
  // For now, use a workaround: import the module directly
  const moduleImport = await import("../ignition/modules/LocalTestnetSetup.ts");
  const userModule = moduleImport.default;
  
  // Get network connection
  const connection = await hre.network.connect();
  const chainId = Number(await connection.provider.request({ method: "eth_chainId" }));
  
  // Load the Ignition module
  const modulePath = "ignition/modules/LocalTestnetSetup.ts";
  const userModule = await loadIgnitionModule(hre.config.paths.ignition, modulePath);
  if (!userModule) {
    throw new Error(`Failed to load Ignition module: ${modulePath}`);
  }
  
  // Create artifact resolver
  const artifactResolver = new HardhatArtifactResolver(hre.artifacts);
  
  // Prepare parameters
  const parameters = {
    LocalTestnetSetup: {
      userAddress: user.address,
      ethAmount: ethers.parseEther("10").toString(),
      usdcAmount: ethers.parseUnits("100000", 6).toString(),
      usdxAmount: ethers.parseUnits("50000", 6).toString(),
      localEid: 30101,
    },
  };
  
  // Get accounts
  const accounts = (await connection.provider.request({ method: "eth_accounts" })) as string[];
  
  // Deploy using Ignition core (matching internal task implementation)
  const result = await deploy({
    config: hre.config.ignition || {},
    provider: connection.provider,
    executionEventListener: undefined, // Optional - for pretty output
    artifactResolver,
    deploymentDir: undefined, // Ephemeral for local network
    ignitionModule: userModule,
    deploymentParameters: parameters,
    accounts,
    defaultSender: deployer.address,
    strategy: "basic",
    strategyConfig: hre.config.ignition?.strategyConfig?.basic,
  });
  
  if (result.type !== "SUCCESSFUL_DEPLOYMENT") {
    throw new Error(`Deployment failed: ${result.type}`);
  }
  
  console.log("Deployment completed!\n");
  
  // Access deployed contracts from result
  // Result structure: result.contracts[moduleId][contractId]
  const moduleResult = result.contracts.LocalTestnetSetup;
  if (!moduleResult) {
    throw new Error("Deployment result structure unexpected. Expected result.LocalTestnetSetup");
  }
  
  const mockUSDCAddress = moduleResult.MockUSDC;
  const mockYearnVaultAddress = moduleResult.MockYearnVault;
  const mockLayerZeroEndpointAddress = moduleResult.MockLayerZeroEndpoint;
  const usdxTokenAddress = moduleResult.USDXToken;
  const usdxVaultAddress = moduleResult.USDXVault;
  
  if (!mockUSDCAddress || !usdxTokenAddress || !usdxVaultAddress) {
    throw new Error(`Missing contract addresses in deployment result: ${JSON.stringify(Object.keys(moduleResult))}`);
  }
  
  // Get contract ABIs from artifacts
  const MockUSDC = await hre.artifacts.readArtifact("MockUSDC");
  const MockYearnVault = await hre.artifacts.readArtifact("MockYearnVault");
  const MockLayerZeroEndpoint = await hre.artifacts.readArtifact("MockLayerZeroEndpoint");
  const USDXToken = await hre.artifacts.readArtifact("USDXToken");
  const USDXVault = await hre.artifacts.readArtifact("USDXVault");
  
  // Create contract instances for reading
  const mockUSDC = new ethers.Contract(mockUSDCAddress, MockUSDC.abi, provider);
  const mockYearnVault = new ethers.Contract(mockYearnVaultAddress, MockYearnVault.abi, provider);
  const mockLayerZeroEndpoint = new ethers.Contract(mockLayerZeroEndpointAddress, MockLayerZeroEndpoint.abi, provider);
  const usdxToken = new ethers.Contract(usdxTokenAddress, USDXToken.abi, provider);
  const usdxVault = new ethers.Contract(usdxVaultAddress, USDXVault.abi, provider);
  
  // Send ETH to user (using hardhat_setBalance RPC call)
  // This works with Hardhat's EDR network
  const ethAmount = ethers.parseEther("10");
  try {
    await provider.send("hardhat_setBalance", [
      user.address,
      ethers.toBeHex(ethAmount),
    ]);
  } catch (error) {
    console.warn("Warning: Could not set ETH balance via hardhat_setBalance:", error);
    console.warn("User may need to be funded manually or via transaction");
  }
  
  // Get balances (with error handling)
  let userEthBalance = ethers.parseEther("0");
  let userUSDCBalance = ethers.parseUnits("0", 6);
  let userUSDXBalance = ethers.parseUnits("0", 6);
  
  try {
    userEthBalance = await provider.getBalance(user.address);
    userUSDCBalance = await mockUSDC.balanceOf(user.address);
    userUSDXBalance = await usdxToken.balanceOf(user.address);
  } catch (error) {
    console.warn("Warning: Could not read balances:", error);
    console.warn("This may be normal if contracts were just deployed");
  }
  
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
  
  // Verify permissions (with error handling)
  console.log("\n=== Permissions Setup ===\n");
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("BURNER_ROLE"));
  
  try {
    const vaultHasMinterRole = await usdxToken.hasRole(MINTER_ROLE, usdxVaultAddress);
    const vaultHasBurnerRole = await usdxToken.hasRole(BURNER_ROLE, usdxVaultAddress);
    
    console.log("Vault has MINTER_ROLE:", vaultHasMinterRole ? "✓" : "✗");
    console.log("Vault has BURNER_ROLE:", vaultHasBurnerRole ? "✓" : "✗");
    
    // Verify Yearn vault setup
    const yearnVaultAddress = await usdxVault.yearnVault();
    const yearnVaultSet = yearnVaultAddress && 
      yearnVaultAddress.toLowerCase() !== "0x0000000000000000000000000000000000000000" &&
      yearnVaultAddress.toLowerCase() === mockYearnVaultAddress.toLowerCase();
    console.log("Yearn Vault set:", yearnVaultSet ? "✓" : "✗");
    
    // Verify LayerZero endpoint
    const lzEndpoint = await usdxToken.lzEndpoint();
    const lzEndpointSet = lzEndpoint && 
      lzEndpoint.toLowerCase() !== "0x0000000000000000000000000000000000000000" &&
      lzEndpoint.toLowerCase() === mockLayerZeroEndpointAddress.toLowerCase();
    console.log("LayerZero Endpoint set:", lzEndpointSet ? "✓" : "✗");
  } catch (error) {
    console.warn("Warning: Could not verify permissions:", error);
  }
  
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
