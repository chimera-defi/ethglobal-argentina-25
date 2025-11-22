// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../contracts/USDXToken.sol";
import "../contracts/USDXVault.sol";
import "../contracts/mocks/MockUSDC.sol";
import "../contracts/mocks/MockYearnVault.sol";

contract DeployHubOnly is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Deploying Hub Chain Contracts ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Mock USDC
        console2.log("1. Deploying Mock USDC...");
        MockUSDC usdc = new MockUSDC();
        console2.log("Mock USDC:", address(usdc));

        // 2. Deploy Mock Yearn Vault
        console2.log("2. Deploying Mock Yearn Vault...");
        MockYearnVault yearnVault = new MockYearnVault(address(usdc));
        console2.log("Mock Yearn Vault:", address(yearnVault));

        // 3. Deploy Hub USDX Token
        console2.log("3. Deploying Hub USDX Token...");
        USDXToken hubUSDX = new USDXToken(deployer);
        console2.log("Hub USDX Token:", address(hubUSDX));

        // 4. Deploy Hub Vault
        console2.log("4. Deploying Hub Vault...");
        USDXVault hubVault = new USDXVault(
            address(usdc),
            address(hubUSDX),
            address(yearnVault),
            deployer // treasury
        );
        console2.log("Hub Vault:", address(hubVault));

        // 5. Grant roles
        console2.log("5. Granting roles...");
        bytes32 MINTER_ROLE = hubUSDX.MINTER_ROLE();
        bytes32 BURNER_ROLE = hubUSDX.BURNER_ROLE();
        
        hubUSDX.grantRole(MINTER_ROLE, address(hubVault));
        hubUSDX.grantRole(BURNER_ROLE, address(hubVault));
        console2.log("Roles granted to vault");

        // 6. Mint test USDC
        console2.log("6. Minting 1,000,000 USDC to deployer...");
        usdc.mint(deployer, 1_000_000e6);
        console2.log("Done!");

        vm.stopBroadcast();

        // Save deployment info
        console2.log("");
        console2.log("=== Hub Chain Deployment Complete ===");
        console2.log("Network: Ethereum (Hub)");
        console2.log("RPC: http://localhost:8545");
        console2.log("Chain ID:", block.chainid);
        console2.log("");
        console2.log("Contracts:");
        console2.log("  MockUSDC:", address(usdc));
        console2.log("  MockYearnVault:", address(yearnVault));
        console2.log("  HubUSDX:", address(hubUSDX));
        console2.log("  HubVault:", address(hubVault));
        console2.log("");
        console2.log("Deployer:", deployer);
        console2.log("USDC Balance:", usdc.balanceOf(deployer));
    }
}
