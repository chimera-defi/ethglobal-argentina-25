// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXVault} from "../contracts/USDXVault.sol";
import {USDXSpokeMinter} from "../contracts/USDXSpokeMinter.sol";
import {USDXShareOFT} from "../contracts/USDXShareOFT.sol";
import {USDXShareOFTAdapter} from "../contracts/USDXShareOFTAdapter.sol";
import {USDXVaultComposerSync} from "../contracts/USDXVaultComposerSync.sol";
import {USDXYearnVaultWrapper} from "../contracts/USDXYearnVaultWrapper.sol";
import {MockUSDC} from "../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../contracts/mocks/MockYearnVault.sol";
import {LayerZeroConfig} from "./LayerZeroConfig.sol";

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
        
        // Get LayerZero endpoint for current chain
        address lzEndpoint = LayerZeroConfig.getEndpoint(block.chainid);
        uint32 hubEid = LayerZeroConfig.getEid(block.chainid);
        console2.log("LayerZero Endpoint:", lzEndpoint);
        console2.log("Hub EID:", hubEid);
        
        USDXToken hubUSDX = new USDXToken(deployer);
        console2.log("HubUSDX:", address(hubUSDX));
        
        // Deploy vault wrapper
        USDXYearnVaultWrapper vaultWrapper = new USDXYearnVaultWrapper(
            address(usdc),
            address(yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        console2.log("VaultWrapper:", address(vaultWrapper));
        
        // Deploy share OFT adapter
        USDXShareOFTAdapter shareOFTAdapter = new USDXShareOFTAdapter(
            address(vaultWrapper),
            lzEndpoint,
            hubEid,
            deployer
        );
        console2.log("ShareOFTAdapter:", address(shareOFTAdapter));
        
        // Deploy vault composer
        USDXVaultComposerSync composer = new USDXVaultComposerSync(
            address(vaultWrapper),
            address(shareOFTAdapter),
            address(usdc),
            lzEndpoint,
            hubEid,
            deployer
        );
        console2.log("VaultComposer:", address(composer));
        
        USDXVault vault = new USDXVault(
            address(usdc),
            address(hubUSDX),
            deployer, // Treasury = deployer for testing
            deployer, // Admin
            address(composer),
            address(shareOFTAdapter),
            address(vaultWrapper)
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
        console2.log("\n--- NOTE: Deploy spoke contracts on each L2 separately ---");
        console2.log("This script deploys hub contracts only.");
        console2.log("For spoke deployment, use DeploySpoke.s.sol on each L2 chain.");
        console2.log("\nExample spoke deployment commands:");
        console2.log("  forge script script/DeploySpoke.s.sol:DeploySpoke \\");
        console2.log("    --rpc-url $POLYGON_RPC_URL --broadcast --verify");
        console2.log("  forge script script/DeploySpoke.s.sol:DeploySpoke \\");
        console2.log("    --rpc-url $BASE_RPC_URL --broadcast --verify");
        console2.log("  forge script script/DeploySpoke.s.sol:DeploySpoke \\");
        console2.log("    --rpc-url $ARBITRUM_RPC_URL --broadcast --verify");
        
        vm.stopBroadcast();
        
        // ============ Print Deployment Summary ============
        console2.log("\n========================================");
        console2.log("  Hub Deployment Complete!");
        console2.log("========================================\n");
        
        console2.log("Mock Contracts:");
        console2.log("  USDC:", address(usdc));
        console2.log("  Yearn Vault:", address(yearnVault));
        
        console2.log("\nHub Chain Contracts:");
        console2.log("  USDX Token:", address(hubUSDX));
        console2.log("  Vault Wrapper:", address(vaultWrapper));
        console2.log("  Share OFT Adapter:", address(shareOFTAdapter));
        console2.log("  Vault Composer:", address(composer));
        console2.log("  USDX Vault:", address(vault));
        
        console2.log("\nLayerZero Config:");
        console2.log("  Endpoint:", lzEndpoint);
        console2.log("  Hub EID:", hubEid);
        
        console2.log("\nConfiguration:");
        console2.log("  Deployer/Admin:", deployer);
        console2.log("  Treasury:", deployer);
        
        console2.log("\n========================================");
        console2.log("  Next Steps:");
        console2.log("  1. Deploy spoke contracts on each L2");
        console2.log("  2. Configure trusted remotes");
        console2.log("  3. Fund vault with USDC for testing");
        console2.log("========================================\n");
    }
}
