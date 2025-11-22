// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/core/USDXToken.sol";
import "../contracts/core/MockUSDC.sol";
import "../contracts/core/MockYieldVault.sol";
import "../contracts/core/USDXVault.sol";
import "../contracts/core/USDXSpokeMinter.sol";
import "../contracts/core/CrossChainBridge.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        
        // Deploy MockUSDC
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));
        
        // Deploy USDXToken
        USDXToken usdxToken = new USDXToken(deployer);
        console.log("USDXToken deployed at:", address(usdxToken));
        
        // Deploy MockYieldVault
        MockYieldVault yieldVault = new MockYieldVault(address(usdc));
        console.log("MockYieldVault deployed at:", address(yieldVault));
        
        // Deploy USDXVault (Hub Chain)
        USDXVault vault = new USDXVault(
            address(usdc),
            address(usdxToken),
            address(yieldVault)
        );
        console.log("USDXVault deployed at:", address(vault));
        
        // Grant vault role to mint USDX
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(vault));
        console.log("Granted VAULT_ROLE to vault");
        
        // Deploy USDXSpokeMinter (for spoke chains)
        USDXSpokeMinter spokeMinter = new USDXSpokeMinter(
            address(usdxToken),
            address(vault),
            1 // Hub chain ID (Ethereum)
        );
        console.log("USDXSpokeMinter deployed at:", address(spokeMinter));
        
        // Grant roles
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(spokeMinter));
        console.log("Granted VAULT_ROLE to spokeMinter");
        
        // Deploy CrossChainBridge
        CrossChainBridge bridge = new CrossChainBridge(
            address(usdxToken),
            137 // Chain ID (Polygon for example)
        );
        console.log("CrossChainBridge deployed at:", address(bridge));
        
        // Grant roles
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(bridge));
        bridge.setSupportedChain(42161, true); // Arbitrum
        console.log("Granted VAULT_ROLE to bridge and set supported chains");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("USDC:", address(usdc));
        console.log("USDXToken:", address(usdxToken));
        console.log("YieldVault:", address(yieldVault));
        console.log("USDXVault:", address(vault));
        console.log("USDXSpokeMinter:", address(spokeMinter));
        console.log("CrossChainBridge:", address(bridge));
    }
}
