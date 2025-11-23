import hre from "hardhat";

/**
 * @title Direct Local Testnet Setup
 * @notice Direct contract deployment using ethers (works reliably with Hardhat3)
 * @dev This script deploys contracts directly using ethers
 * 
 * Prerequisites:
 * 1. Start Hardhat node: npx hardhat node (in a separate terminal)
 * 2. Then run: npx hardhat run scripts/setup-local-direct.ts --network hardhat
 * 
 * Or use the automated version that starts the node:
 * npm run setup:local
 */
async function main() {
  const { ethers } = await import("ethers");
  
  console.log("\n=== USDX Local Testnet Setup (Direct Deployment) ===\n");
  
  // Use JsonRpcProvider to connect to Hardhat node
  // Note: Hardhat node must be running on localhost:8545
  // Start it with: npx hardhat node
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  
  // Verify connection
  try {
    const network = await provider.getNetwork();
    console.log(`Connected to network: ${network.name} (chainId: ${network.chainId})\n`);
  } catch (error: any) {
    console.error("\n❌ Error: Could not connect to Hardhat node.");
    console.error("Please start Hardhat node first:");
    console.error("  npx hardhat node\n");
    console.error("Then run this script again.\n");
    throw new Error("Hardhat node not running. Start it with 'npx hardhat node'");
  }
  
  // Hardhat default accounts
  const deployerPrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  const userPrivateKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
  
  const deployer = new ethers.Wallet(deployerPrivateKey, provider);
  const user = new ethers.Wallet(userPrivateKey, provider);
  
  console.log("Deployer:", deployer.address);
  console.log("User:", user.address);
  
  // Get contract factories from artifacts
  const MockUSDC = await hre.artifacts.readArtifact("MockUSDC");
  const MockYearnVault = await hre.artifacts.readArtifact("MockYearnVault");
  const MockLayerZeroEndpoint = await hre.artifacts.readArtifact("MockLayerZeroEndpoint");
  const USDXToken = await hre.artifacts.readArtifact("USDXToken");
  const USDXVault = await hre.artifacts.readArtifact("USDXVault");
  
  console.log("\nDeploying contracts...\n");
  
  // Deploy mock contracts sequentially using factory.deploy() which handles nonces properly
  const MockUSDCFactory = new ethers.ContractFactory(MockUSDC.abi, MockUSDC.bytecode, deployer);
  const mockUSDCContract = await MockUSDCFactory.deploy();
  await mockUSDCContract.waitForDeployment();
  const mockUSDCAddress = await mockUSDCContract.getAddress();
  const mockUSDC = new ethers.Contract(mockUSDCAddress, MockUSDC.abi, deployer);
  console.log("✓ MockUSDC deployed:", mockUSDCAddress);
  
  const MockYearnVaultFactory = new ethers.ContractFactory(MockYearnVault.abi, MockYearnVault.bytecode, deployer);
  const mockYearnVaultContract = await MockYearnVaultFactory.deploy(mockUSDCAddress);
  await mockYearnVaultContract.waitForDeployment();
  const mockYearnVaultAddress = await mockYearnVaultContract.getAddress();
  const mockYearnVault = new ethers.Contract(mockYearnVaultAddress, MockYearnVault.abi, deployer);
  console.log("✓ MockYearnVault deployed:", mockYearnVaultAddress);
  
  const MockLayerZeroFactory = new ethers.ContractFactory(MockLayerZeroEndpoint.abi, MockLayerZeroEndpoint.bytecode, deployer);
  const mockLayerZeroContract = await MockLayerZeroFactory.deploy(30101);
  await mockLayerZeroContract.waitForDeployment();
  const mockLayerZeroAddress = await mockLayerZeroContract.getAddress();
  const mockLayerZero = new ethers.Contract(mockLayerZeroAddress, MockLayerZeroEndpoint.abi, deployer);
  console.log("✓ MockLayerZeroEndpoint deployed:", mockLayerZeroAddress);
  
  // Deploy USDX contracts
  const USDXTokenFactory = new ethers.ContractFactory(USDXToken.abi, USDXToken.bytecode, deployer);
  const usdxTokenContract = await USDXTokenFactory.deploy(deployer.address);
  await usdxTokenContract.waitForDeployment();
  const usdxTokenAddress = await usdxTokenContract.getAddress();
  const usdxToken = new ethers.Contract(usdxTokenAddress, USDXToken.abi, deployer);
  console.log("✓ USDXToken deployed:", usdxTokenAddress);
  
  const USDXVaultFactory = new ethers.ContractFactory(USDXVault.abi, USDXVault.bytecode, deployer);
  const usdxVaultContract = await USDXVaultFactory.deploy(
    mockUSDCAddress,
    usdxTokenAddress,
    deployer.address, // treasury
    deployer.address, // admin
    "0x0000000000000000000000000000000000000000", // ovaultComposer
    "0x0000000000000000000000000000000000000000", // shareOFTAdapter
    "0x0000000000000000000000000000000000000000"  // vaultWrapper
  );
  await usdxVaultContract.waitForDeployment();
  const usdxVaultAddress = await usdxVaultContract.getAddress();
  const usdxVault = new ethers.Contract(usdxVaultAddress, USDXVault.abi, deployer);
  console.log("✓ USDXVault deployed:", usdxVaultAddress);
  
  // Set up permissions
  console.log("\nSetting up permissions...\n");
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("BURNER_ROLE"));
  
  await usdxToken.grantRole(MINTER_ROLE, usdxVaultAddress);
  console.log("✓ Granted MINTER_ROLE to vault");
  
  await usdxToken.grantRole(BURNER_ROLE, usdxVaultAddress);
  console.log("✓ Granted BURNER_ROLE to vault");
  
  await usdxToken.setLayerZeroEndpoint(mockLayerZeroAddress, 30101);
  console.log("✓ Set LayerZero endpoint");
  
  await usdxVault.setYearnVault(mockYearnVaultAddress);
  console.log("✓ Set Yearn vault");
  
  // Fund user account
  console.log("\nFunding user account...\n");
  
  // Send ETH
  await provider.send("hardhat_setBalance", [user.address, ethers.toBeHex(ethers.parseEther("10"))]);
  console.log("✓ Sent 10 ETH to user");
  
  // Mint USDC
  await mockUSDC.mint(user.address, ethers.parseUnits("100000", 6));
  console.log("✓ Minted 100,000 USDC to user");
  
  // Mint USDX
  await usdxToken.mint(user.address, ethers.parseUnits("50000", 6));
  console.log("✓ Minted 50,000 USDX to user");
  
  // Get balances
  const userEthBalance = await provider.getBalance(user.address);
  const userUSDCBalance = await mockUSDC.balanceOf(user.address);
  const userUSDXBalance = await usdxToken.balanceOf(user.address);
  
  // Print summary
  console.log("\n=== Deployment Summary ===\n");
  console.log("Mock Contracts:");
  console.log("  MockUSDC:", mockUSDCAddress);
  console.log("  MockYearnVault:", mockYearnVaultAddress);
  console.log("  MockLayerZeroEndpoint:", mockLayerZeroAddress);
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
  const vaultHasMinterRole = await usdxToken.hasRole(MINTER_ROLE, usdxVaultAddress);
  const vaultHasBurnerRole = await usdxToken.hasRole(BURNER_ROLE, usdxVaultAddress);
  console.log("Vault has MINTER_ROLE:", vaultHasMinterRole ? "✓" : "✗");
  console.log("Vault has BURNER_ROLE:", vaultHasBurnerRole ? "✓" : "✗");
  
  console.log("\n=== Setup Complete! ===\n");
  console.log("You can now use these contracts for testing:");
  console.log(`  - USDC: ${mockUSDCAddress}`);
  console.log(`  - USDX: ${usdxTokenAddress}`);
  console.log(`  - Vault: ${usdxVaultAddress}`);
  console.log(`\nUser account (${user.address}) is funded and ready to use.\n`);
  
  // Save addresses
  const addresses = {
    deployer: deployer.address,
    user: user.address,
    contracts: {
      mockUSDC: mockUSDCAddress,
      mockYearnVault: mockYearnVaultAddress,
      mockLayerZeroEndpoint: mockLayerZeroAddress,
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
