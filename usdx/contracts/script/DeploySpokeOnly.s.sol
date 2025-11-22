// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../contracts/USDXToken.sol";
import "../contracts/USDXSpokeMinter.sol";

contract DeploySpokeOnly is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Deploying Spoke Chain Contracts ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Spoke USDX Token
        console2.log("1. Deploying Spoke USDX Token...");
        USDXToken spokeUSDX = new USDXToken(deployer);
        console2.log("Spoke USDX Token:", address(spokeUSDX));

        // 2. Deploy Spoke Minter
        console2.log("2. Deploying Spoke Minter...");
        USDXSpokeMinter spokeMinter = new USDXSpokeMinter(
            address(spokeUSDX),
            deployer // position oracle (will be bridge in production)
        );
        console2.log("Spoke Minter:", address(spokeMinter));

        // 3. Grant roles
        console2.log("3. Granting roles...");
        bytes32 MINTER_ROLE = spokeUSDX.MINTER_ROLE();
        bytes32 BURNER_ROLE = spokeUSDX.BURNER_ROLE();
        
        spokeUSDX.grantRole(MINTER_ROLE, address(spokeMinter));
        spokeUSDX.grantRole(BURNER_ROLE, address(spokeMinter));
        console2.log("Roles granted to minter");

        vm.stopBroadcast();

        // Save deployment info
        console2.log("");
        console2.log("=== Spoke Chain Deployment Complete ===");
        console2.log("Network: Polygon (Spoke)");
        console2.log("RPC: http://localhost:8546");
        console2.log("Chain ID:", block.chainid);
        console2.log("");
        console2.log("Contracts:");
        console2.log("  SpokeUSDX:", address(spokeUSDX));
        console2.log("  SpokeMinter:", address(spokeMinter));
        console2.log("");
        console2.log("Deployer:", deployer);
    }
}
