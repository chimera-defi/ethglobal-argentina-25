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
  
  // Verify connection with retry logic
  let connected = false;
  for (let i = 0; i < 5; i++) {
    try {
      const network = await provider.getNetwork();
      console.log(`Connected to network: ${network.name} (chainId: ${network.chainId})\n`);
      connected = true;
      break;
    } catch (error: unknown) {
      if (i < 4) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        continue;
      }
      console.error("\n❌ Error: Could not connect to Hardhat node.");
      console.error("Please start Hardhat node first:");
      console.error("  npx hardhat node\n");
      console.error("Then run this script again.\n");
      throw new Error("Hardhat node not running. Start it with 'npx hardhat node'");
    }
  }
  
  if (!connected) {
    throw new Error("Failed to connect to Hardhat node after retries");
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
  
  // Helper function to advance chain after transaction
  const advanceChain = async () => {
    await provider.send("evm_mine", []);
  };
  
  // Deploy contracts using getDeployTransaction and manual nonce management
  // This ensures we have full control over transaction sending
  let currentNonce = await provider.getTransactionCount(deployer.address, "latest");
  
  const deployContract = async (factory: ethers.ContractFactory, ...args: unknown[]) => {
    // Use tracked nonce
    const nonce = currentNonce;
    
    // Get deployment transaction (this doesn't send it)
    const deployTx = await factory.getDeployTransaction(...args);
    
    // Create a new transaction object with explicit nonce
    const txWithNonce = {
      ...deployTx,
      nonce: nonce,
    };
    
    // Send transaction with explicit nonce
    const txResponse = await deployer.sendTransaction(txWithNonce);
    
    // Wait for receipt - this ensures transaction is mined
    const receipt = await txResponse.wait();
    
    // Advance chain to ensure state is updated
    await advanceChain();
    
    // Increment nonce manually - each successful transaction increments nonce by 1
    currentNonce++;
    
    // Get contract address from receipt
    if (!receipt.contractAddress) {
      throw new Error("Contract deployment failed - no contract address in receipt");
    }
    return new ethers.Contract(receipt.contractAddress, factory.interface, deployer);
  };
  
  // Helper to send a transaction with proper nonce management
  const sendTx = async (contract: ethers.Contract, method: string, ...args: unknown[]) => {
    // Use our tracked nonce
    const nonce = currentNonce;
    const tx = await contract[method].populateTransaction(...args);
    tx.nonce = nonce;
    const txResponse = await deployer.sendTransaction(tx);
    const receipt = await txResponse.wait();
    await advanceChain();
    // Increment nonce manually - each successful transaction increments nonce by 1
    currentNonce++;
    return receipt;
  };
  
  // Deploy mock contracts sequentially
  const MockUSDCFactory = new ethers.ContractFactory(MockUSDC.abi, MockUSDC.bytecode, deployer);
  const mockUSDC = await deployContract(MockUSDCFactory);
  const mockUSDCAddress = await mockUSDC.getAddress();
  console.log("✓ MockUSDC deployed:", mockUSDCAddress);
  
  const MockYearnVaultFactory = new ethers.ContractFactory(MockYearnVault.abi, MockYearnVault.bytecode, deployer);
  const mockYearnVault = await deployContract(MockYearnVaultFactory, mockUSDCAddress);
  const mockYearnVaultAddress = await mockYearnVault.getAddress();
  console.log("✓ MockYearnVault deployed:", mockYearnVaultAddress);
  
  const MockLayerZeroFactory = new ethers.ContractFactory(MockLayerZeroEndpoint.abi, MockLayerZeroEndpoint.bytecode, deployer);
  const mockLayerZero = await deployContract(MockLayerZeroFactory, 30101);
  const mockLayerZeroAddress = await mockLayerZero.getAddress();
  console.log("✓ MockLayerZeroEndpoint deployed:", mockLayerZeroAddress);
  
  // Deploy USDX contracts
  const USDXTokenFactory = new ethers.ContractFactory(USDXToken.abi, USDXToken.bytecode, deployer);
  const usdxToken = await deployContract(USDXTokenFactory, deployer.address);
  const usdxTokenAddress = await usdxToken.getAddress();
  console.log("✓ USDXToken deployed:", usdxTokenAddress);
  
  const USDXVaultFactory = new ethers.ContractFactory(USDXVault.abi, USDXVault.bytecode, deployer);
  const usdxVault = await deployContract(
    USDXVaultFactory,
    mockUSDCAddress,
    usdxTokenAddress,
    deployer.address, // treasury
    deployer.address, // admin
    "0x0000000000000000000000000000000000000000", // ovaultComposer
    "0x0000000000000000000000000000000000000000", // shareOFTAdapter
    "0x0000000000000000000000000000000000000000"  // vaultWrapper
  );
  const usdxVaultAddress = await usdxVault.getAddress();
  console.log("✓ USDXVault deployed:", usdxVaultAddress);
  
  // Set up permissions
  console.log("\nSetting up permissions...\n");
  const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  const BURNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("BURNER_ROLE"));
  
  await sendTx(usdxToken, "grantRole", MINTER_ROLE, usdxVaultAddress);
  console.log("✓ Granted MINTER_ROLE to vault");
  
  await sendTx(usdxToken, "grantRole", BURNER_ROLE, usdxVaultAddress);
  console.log("✓ Granted BURNER_ROLE to vault");
  
  await sendTx(usdxToken, "setLayerZeroEndpoint", mockLayerZeroAddress, 30101);
  console.log("✓ Set LayerZero endpoint");
  
  await sendTx(usdxVault, "setYearnVault", mockYearnVaultAddress);
  console.log("✓ Set Yearn vault");
  
  // Fund user account
  console.log("\nFunding user account...\n");
  
  // Send ETH
  await provider.send("hardhat_setBalance", [user.address, ethers.toBeHex(ethers.parseEther("10"))]);
  await advanceChain();
  console.log("✓ Sent 10 ETH to user");
  
  // Mint USDC
  await sendTx(mockUSDC, "mint", user.address, ethers.parseUnits("100000", 6));
  console.log("✓ Minted 100,000 USDC to user");
  
  // Mint USDX
  await sendTx(usdxToken, "mint", user.address, ethers.parseUnits("50000", 6));
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
