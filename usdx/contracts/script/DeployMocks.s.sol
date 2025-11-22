// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {MockUSDC} from "../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../contracts/mocks/MockYearnVault.sol";

/**
 * @title DeployMocks
 * @notice Deployment script for mock contracts on testnet
 * @dev Run this BEFORE deploying hub contracts on testnet
 * forge script script/DeployMocks.s.sol:DeployMocks --rpc-url $SEPOLIA_RPC_URL --broadcast
 */
contract DeployMocks is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== Deploying Mock Contracts ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy MockUSDC
        console2.log("\n1. Deploying MockUSDC...");
        MockUSDC usdc = new MockUSDC();
        console2.log("   MockUSDC deployed at:", address(usdc));
        
        // 2. Deploy MockYearnVault
        console2.log("\n2. Deploying MockYearnVault...");
        MockYearnVault yearn = new MockYearnVault(address(usdc));
        console2.log("   MockYearnVault deployed at:", address(yearn));
        
        // 3. Mint some USDC to deployer for testing
        console2.log("\n3. Minting test USDC...");
        usdc.mint(deployer, 1_000_000 * 10**6); // 1M USDC
        console2.log("   Minted 1,000,000 USDC to deployer");
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console2.log("\n=== Deployment Complete ===");
        console2.log("MockUSDC:", address(usdc));
        console2.log("MockYearnVault:", address(yearn));
        console2.log("\nUse these addresses when deploying Hub contracts!");
        console2.log("Update your .env or hardhat.config with:");
        console2.log("MOCK_USDC_ADDRESS=", address(usdc));
        console2.log("MOCK_YEARN_VAULT_ADDRESS=", address(yearn));
    }
}
