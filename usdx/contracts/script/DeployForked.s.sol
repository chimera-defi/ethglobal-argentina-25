// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXVault} from "../contracts/USDXVault.sol";
import {USDXSpokeMinter} from "../contracts/USDXSpokeMinter.sol";
import {MockUSDC} from "../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../contracts/mocks/MockYearnVault.sol";

/**
 * @title DeployForked
 * @notice Deploys complete USDX protocol to forked mainnet for local testing
 * @dev Run with: forge script script/DeployForked.s.sol:DeployForked --fork-url $MAINNET_RPC_URL --broadcast
 */
contract DeployForked is Script {
    // Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n========================================");
        console2.log("  USDX Protocol - Forked Network Deploy");
        console2.log("========================================\n");
        
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("Block Number:", block.number);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // ============ Deploy Mock Contracts ============
        console2.log("\n--- Deploying Mock Contracts ---");
        
        MockUSDC usdc = new MockUSDC();
        console2.log("MockUSDC:", address(usdc));
        
        MockYearnVault yearnVault = new MockYearnVault(address(usdc));
        console2.log("MockYearnVault:", address(yearnVault));
        
        // Mint test USDC to deployer
        usdc.mint(deployer, 1_000_000 * 10**6); // 1M USDC
        console2.log("Minted 1,000,000 USDC to deployer");
        
        // ============ Deploy Hub Chain Contracts ============
        console2.log("\n--- Deploying Hub Chain (Ethereum) ---");
        
        USDXToken hubUSDX = new USDXToken(deployer);
        console2.log("HubUSDX:", address(hubUSDX));
        
        USDXVault vault = new USDXVault(
            address(usdc),
            address(hubUSDX),
            deployer, // Treasury = deployer for testing
            deployer
        );
        console2.log("HubVault:", address(vault));
        
        // Setup hub permissions
        hubUSDX.grantRole(MINTER_ROLE, address(vault));
        hubUSDX.grantRole(BURNER_ROLE, address(vault));
        console2.log("Granted vault roles on HubUSDX");
        
        // Set Yearn vault
        vault.setYearnVault(address(yearnVault));
        console2.log("Set Yearn vault on HubVault");
        
        // ============ Deploy Spoke Chain Contracts ============
        console2.log("\n--- Deploying Spoke Chain (Simulated) ---");
        
        USDXToken spokeUSDX = new USDXToken(deployer);
        console2.log("SpokeUSDX:", address(spokeUSDX));
        
        USDXSpokeMinter spokeMinter = new USDXSpokeMinter(
            address(spokeUSDX),
            deployer
        );
        console2.log("SpokeMinter:", address(spokeMinter));
        
        // Setup spoke permissions
        spokeUSDX.grantRole(MINTER_ROLE, address(spokeMinter));
        spokeUSDX.grantRole(BURNER_ROLE, address(spokeMinter));
        spokeMinter.grantRole(POSITION_UPDATER_ROLE, deployer);
        console2.log("Granted minter roles on SpokeUSDX");
        
        vm.stopBroadcast();
        
        // ============ Print Deployment Summary ============
        console2.log("\n========================================");
        console2.log("  Deployment Complete!");
        console2.log("========================================\n");
        
        console2.log("Mock Contracts:");
        console2.log("  USDC:", address(usdc));
        console2.log("  Yearn Vault:", address(yearnVault));
        
        console2.log("\nHub Chain (Ethereum):");
        console2.log("  USDX Token:", address(hubUSDX));
        console2.log("  USDX Vault:", address(vault));
        
        console2.log("\nSpoke Chain (Simulated):");
        console2.log("  USDX Token:", address(spokeUSDX));
        console2.log("  Spoke Minter:", address(spokeMinter));
        
        console2.log("\nTest Accounts:");
        console2.log("  Deployer/Admin:", deployer);
        console2.log("  Treasury:", deployer);
        console2.log("  Position Oracle:", deployer);
        
        console2.log("\n========================================");
        console2.log("  Ready for Frontend Development!");
        console2.log("========================================\n");
        
        // Addresses saved - use console output above for frontend config
    }
}
