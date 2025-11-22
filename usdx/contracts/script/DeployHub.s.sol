// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXVault} from "../contracts/USDXVault.sol";

/**
 * @title DeployHub
 * @notice Deployment script for USDX Hub Chain contracts (Ethereum/Sepolia)
 * @dev Run with: forge script script/DeployHub.s.sol:DeployHub --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeployHub is Script {
    // Configuration
    address public USDC_ADDRESS;
    address public YEARN_VAULT_ADDRESS;
    address public TREASURY_ADDRESS;
    
    // Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    function setUp() public {
        // Set addresses based on chain
        uint256 chainId = block.chainid;
        
        if (chainId == 1) {
            // Ethereum Mainnet
            USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            YEARN_VAULT_ADDRESS = 0xBe53A109B494E5c9f97b9Cd39Fe969BE68BF6204; // yUSDC v3
            TREASURY_ADDRESS = msg.sender; // TODO: Set actual treasury
        } else if (chainId == 11155111) {
            // Sepolia Testnet
            // Note: These are placeholder addresses - update with actual testnet addresses
            USDC_ADDRESS = msg.sender; // Deploy mock USDC first
            YEARN_VAULT_ADDRESS = address(0); // Will be set later
            TREASURY_ADDRESS = msg.sender;
        } else {
            revert("Unsupported chain");
        }
    }
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== USDX Hub Chain Deployment ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("USDC:", USDC_ADDRESS);
        console2.log("Treasury:", TREASURY_ADDRESS);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy USDXToken
        console2.log("\n1. Deploying USDXToken...");
        USDXToken usdx = new USDXToken(deployer);
        console2.log("   USDXToken deployed at:", address(usdx));
        
        // 2. Deploy USDXVault
        console2.log("\n2. Deploying USDXVault...");
        USDXVault vault = new USDXVault(
            USDC_ADDRESS,
            address(usdx),
            TREASURY_ADDRESS,
            deployer
        );
        console2.log("   USDXVault deployed at:", address(vault));
        
        // 3. Grant vault permissions on USDX token
        console2.log("\n3. Setting up permissions...");
        usdx.grantRole(MINTER_ROLE, address(vault));
        console2.log("   Granted MINTER_ROLE to vault");
        
        usdx.grantRole(BURNER_ROLE, address(vault));
        console2.log("   Granted BURNER_ROLE to vault");
        
        // 4. Set Yearn vault if available
        if (YEARN_VAULT_ADDRESS != address(0)) {
            console2.log("\n4. Setting Yearn vault...");
            vault.setYearnVault(YEARN_VAULT_ADDRESS);
            console2.log("   Yearn vault set to:", YEARN_VAULT_ADDRESS);
        } else {
            console2.log("\n4. Skipping Yearn vault setup (address not set)");
        }
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console2.log("\n=== Deployment Complete ===");
        console2.log("USDXToken:", address(usdx));
        console2.log("USDXVault:", address(vault));
        console2.log("\nSave these addresses for spoke chain deployment!");
        
        // Print verification commands
        console2.log("\n=== Verification Commands ===");
        console2.log("Use these commands to verify contracts on Etherscan");
        console2.log("USDXToken address:", address(usdx));
        console2.log("USDXVault address:", address(vault));
    }
}
