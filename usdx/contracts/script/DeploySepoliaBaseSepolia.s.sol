// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXVault} from "../contracts/USDXVault.sol";
import {USDXYearnVaultWrapper} from "../contracts/USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapter} from "../contracts/USDXShareOFTAdapter.sol";
import {USDXVaultComposerSync} from "../contracts/USDXVaultComposerSync.sol";
import {USDXShareOFT} from "../contracts/USDXShareOFT.sol";
import {USDXSpokeMinter} from "../contracts/USDXSpokeMinter.sol";
import {MockUSDC} from "../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../contracts/mocks/MockYearnVault.sol";
import {LayerZeroConfig} from "./LayerZeroConfig.sol";

/**
 * @title DeploySepoliaBaseSepolia
 * @notice Deployment script for Ethereum Sepolia (hub) and Base Sepolia (spoke)
 * @dev This script deploys the complete USDX protocol across two testnets:
 *      - Ethereum Sepolia: Hub with vault and composer
 *      - Base Sepolia: Spoke with USDX token and minter
 * 
 * USAGE:
 *   1. Set environment variables:
 *      export PRIVATE_KEY="0x..."
 *      export SEPOLIA_RPC_URL="https://eth-sepolia..."
 *      export BASE_SEPOLIA_RPC_URL="https://base-sepolia..."
 *      export ETHERSCAN_API_KEY="..."
 *      export BASESCAN_API_KEY="..."
 * 
 *   2. Deploy hub (Ethereum Sepolia):
 *      forge script script/DeploySepoliaBaseSepolia.s.sol:DeploySepoliaBaseSepolia \
 *        --sig "deployHub()" \
 *        --rpc-url $SEPOLIA_RPC_URL \
 *        --broadcast --verify
 * 
 *   3. Deploy spoke (Base Sepolia):
 *      forge script script/DeploySepoliaBaseSepolia.s.sol:DeploySepoliaBaseSepolia \
 *        --sig "deploySpoke(address,address)" HUB_ADAPTER_ADDRESS HUB_COMPOSER_ADDRESS \
 *        --rpc-url $BASE_SEPOLIA_RPC_URL \
 *        --broadcast --verify
 * 
 *   4. Configure trusted remotes (both chains)
 *      forge script script/DeploySepoliaBaseSepolia.s.sol:DeploySepoliaBaseSepolia \
 *        --sig "configureTrustedRemotes(address,address,address,address,address,address)" \
 *        HUB_ADAPTER HUB_COMPOSER SPOKE_SHARE_OFT SPOKE_MINTER HUB_VAULT SPOKE_USDX \
 *        --rpc-url $SEPOLIA_RPC_URL --broadcast
 */
contract DeploySepoliaBaseSepolia is Script {
    // LayerZero Endpoint IDs
    uint32 constant SEPOLIA_EID = 40161;
    uint32 constant BASE_SEPOLIA_EID = 40245;
    
    // LayerZero Endpoints (V2)
    address constant SEPOLIA_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address constant BASE_SEPOLIA_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    
    // Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    /**
     * @notice Deploy hub contracts on Ethereum Sepolia
     * @dev Deploys: USDC (mock), Yearn Vault (mock), Vault Wrapper, Share OFT Adapter, Composer, USDX Vault
     */
    function deployHub() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n========================================");
        console2.log("  ETHEREUM SEPOLIA - HUB DEPLOYMENT");
        console2.log("========================================\n");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("LayerZero Endpoint:", SEPOLIA_ENDPOINT);
        console2.log("Hub EID:", SEPOLIA_EID);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Mock USDC
        console2.log("\n--- Deploying Mock Contracts ---");
        MockUSDC usdc = new MockUSDC();
        console2.log("MockUSDC:", address(usdc));
        
        // 2. Deploy Mock Yearn Vault
        MockYearnVault yearnVault = new MockYearnVault(address(usdc));
        console2.log("MockYearnVault:", address(yearnVault));
        
        // 3. Mint test USDC to deployer
        usdc.mint(deployer, 1_000_000 * 10**6); // 1M USDC
        console2.log("Minted 1,000,000 USDC to deployer");
        
        // 4. Deploy Vault Wrapper
        console2.log("\n--- Deploying Hub Contracts ---");
        USDXYearnVaultWrapper vaultWrapper = new USDXYearnVaultWrapper(
            address(usdc),
            address(yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        console2.log("VaultWrapper:", address(vaultWrapper));
        
        // 5. Deploy Share OFT Adapter
        USDXShareOFTAdapter shareOFTAdapter = new USDXShareOFTAdapter(
            address(vaultWrapper),
            SEPOLIA_ENDPOINT,
            SEPOLIA_EID,
            deployer
        );
        console2.log("ShareOFTAdapter:", address(shareOFTAdapter));
        
        // 6. Deploy Vault Composer
        USDXVaultComposerSync composer = new USDXVaultComposerSync(
            address(vaultWrapper),
            address(shareOFTAdapter),
            address(usdc),
            SEPOLIA_ENDPOINT,
            SEPOLIA_EID,
            deployer
        );
        console2.log("VaultComposer:", address(composer));
        
        // 7. Deploy USDX Token
        USDXToken hubUSDX = new USDXToken(deployer);
        console2.log("HubUSDX:", address(hubUSDX));
        
        // 8. Deploy USDX Vault
        USDXVault vault = new USDXVault(
            address(usdc),
            address(hubUSDX),
            deployer, // Treasury
            deployer, // Admin
            address(composer),
            address(shareOFTAdapter),
            address(vaultWrapper)
        );
        console2.log("USDXVault:", address(vault));
        
        // 9. Setup hub permissions
        hubUSDX.grantRole(MINTER_ROLE, address(vault));
        hubUSDX.grantRole(BURNER_ROLE, address(vault));
        console2.log("Granted vault roles on HubUSDX");
        
        // 10. Set Yearn vault
        vault.setYearnVault(address(yearnVault));
        console2.log("Set Yearn vault on USDXVault");
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console2.log("\n========================================");
        console2.log("  HUB DEPLOYMENT COMPLETE!");
        console2.log("========================================\n");
        console2.log("COPY THESE ADDRESSES FOR SPOKE DEPLOYMENT:\n");
        console2.log("HUB_ADAPTER=", address(shareOFTAdapter));
        console2.log("HUB_COMPOSER=", address(composer));
        console2.log("HUB_VAULT=", address(vault));
        console2.log("\nAll Hub Contracts:");
        console2.log("  USDC:", address(usdc));
        console2.log("  Yearn Vault:", address(yearnVault));
        console2.log("  Vault Wrapper:", address(vaultWrapper));
        console2.log("  Share OFT Adapter:", address(shareOFTAdapter));
        console2.log("  Vault Composer:", address(composer));
        console2.log("  USDX Token:", address(hubUSDX));
        console2.log("  USDX Vault:", address(vault));
    }
    
    /**
     * @notice Deploy spoke contracts on Base Sepolia
     * @dev Deploys: USDX Token, Share OFT, Spoke Minter
     * @param hubAdapter Address of the hub's Share OFT Adapter
     * @param hubComposer Address of the hub's Vault Composer
     */
    function deploySpoke(address hubAdapter, address hubComposer) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n========================================");
        console2.log("  BASE SEPOLIA - SPOKE DEPLOYMENT");
        console2.log("========================================\n");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("LayerZero Endpoint:", BASE_SEPOLIA_ENDPOINT);
        console2.log("Spoke EID:", BASE_SEPOLIA_EID);
        console2.log("Hub Adapter:", hubAdapter);
        console2.log("Hub Composer:", hubComposer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy USDX Token
        console2.log("\n--- Deploying Spoke Contracts ---");
        USDXToken spokeUSDX = new USDXToken(deployer);
        console2.log("SpokeUSDX:", address(spokeUSDX));
        
        // 2. Deploy Share OFT (for receiving shares from hub)
        USDXShareOFT shareOFT = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            BASE_SEPOLIA_ENDPOINT,
            BASE_SEPOLIA_EID,
            deployer
        );
        console2.log("ShareOFT:", address(shareOFT));
        
        // 3. Deploy Spoke Minter
        USDXSpokeMinter spokeMinter = new USDXSpokeMinter(
            address(spokeUSDX),
            address(shareOFT),
            BASE_SEPOLIA_ENDPOINT,
            SEPOLIA_EID, // Hub chain ID
            deployer
        );
        console2.log("SpokeMinter:", address(spokeMinter));
        
        // 4. Setup spoke permissions
        spokeUSDX.grantRole(MINTER_ROLE, address(spokeMinter));
        spokeUSDX.grantRole(BURNER_ROLE, address(spokeMinter));
        shareOFT.setMinter(address(spokeMinter));
        console2.log("Granted minter roles on SpokeUSDX and ShareOFT");
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console2.log("\n========================================");
        console2.log("  SPOKE DEPLOYMENT COMPLETE!");
        console2.log("========================================\n");
        console2.log("COPY THESE ADDRESSES FOR CONFIGURATION:\n");
        console2.log("SPOKE_SHARE_OFT=", address(shareOFT));
        console2.log("SPOKE_MINTER=", address(spokeMinter));
        console2.log("SPOKE_USDX=", address(spokeUSDX));
        console2.log("\nAll Spoke Contracts:");
        console2.log("  USDX Token:", address(spokeUSDX));
        console2.log("  Share OFT:", address(shareOFT));
        console2.log("  Spoke Minter:", address(spokeMinter));
        
        console2.log("\n========================================");
        console2.log("  NEXT STEPS:");
        console2.log("  1. Configure trusted remotes (run configureTrustedRemotes)");
        console2.log("  2. Test deposit flow");
        console2.log("========================================\n");
    }
    
    /**
     * @notice Configure trusted remotes on hub contracts
     * @dev Must be run on Ethereum Sepolia
     */
    function configureTrustedRemotesHub(
        address hubAdapter,
        address hubComposer,
        address spokeShareOFT
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console2.log("\n========================================");
        console2.log("  CONFIGURING HUB TRUSTED REMOTES");
        console2.log("========================================\n");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Set trusted remote on hub adapter
        USDXShareOFTAdapter(hubAdapter).setTrustedRemote(
            BASE_SEPOLIA_EID,
            bytes32(uint256(uint160(spokeShareOFT)))
        );
        console2.log("Set trusted remote on hub adapter");
        
        // Set trusted remote on hub composer
        USDXVaultComposerSync(hubComposer).setTrustedRemote(
            BASE_SEPOLIA_EID,
            bytes32(uint256(uint160(spokeShareOFT)))
        );
        console2.log("Set trusted remote on hub composer");
        
        vm.stopBroadcast();
        
        console2.log("\n[OK] Hub trusted remotes configured!");
    }
    
    /**
     * @notice Configure trusted remotes on spoke contracts
     * @dev Must be run on Base Sepolia
     */
    function configureTrustedRemotesSpoke(
        address spokeShareOFT,
        address spokeMinter,
        address hubAdapter
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console2.log("\n========================================");
        console2.log("  CONFIGURING SPOKE TRUSTED REMOTES");
        console2.log("========================================\n");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Set trusted remote on spoke share OFT
        USDXShareOFT(spokeShareOFT).setTrustedRemote(
            SEPOLIA_EID,
            bytes32(uint256(uint160(hubAdapter)))
        );
        console2.log("Set trusted remote on spoke share OFT");
        
        vm.stopBroadcast();
        
        console2.log("\n[OK] Spoke trusted remotes configured!");
    }
}
