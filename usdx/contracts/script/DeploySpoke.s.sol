// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXSpokeMinter} from "../contracts/USDXSpokeMinter.sol";
import {USDXShareOFT} from "../contracts/USDXShareOFT.sol";
import {ILayerZeroEndpoint} from "../contracts/interfaces/ILayerZeroEndpoint.sol";

/**
 * @title DeploySpoke
 * @notice Deployment script for USDX Spoke Chain contracts (Polygon/Mumbai)
 * @dev Run with: forge script script/DeploySpoke.s.sol:DeploySpoke --rpc-url $MUMBAI_RPC_URL --broadcast --verify
 */
contract DeploySpoke is Script {
    // Configuration
    address public POSITION_ORACLE; // Address that will update hub positions
    
    // Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    function setUp() public {
        // Set addresses based on chain
        uint256 chainId = block.chainid;
        
        if (chainId == 137) {
            // Polygon Mainnet
            POSITION_ORACLE = msg.sender; // TODO: Set actual oracle address
        } else if (chainId == 80001) {
            // Mumbai Testnet
            POSITION_ORACLE = msg.sender; // Use deployer as oracle for testing
        } else if (chainId == 5042002) {
            // Arc Testnet
            POSITION_ORACLE = msg.sender; // Use deployer as oracle for testing
            // NOTE: LayerZero not supported on Arc, so USDXShareOFT will not be deployed
        } else {
            revert("Unsupported chain");
        }
    }
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== USDX Spoke Chain Deployment ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("Position Oracle:", POSITION_ORACLE);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy USDXToken
        console2.log("\n1. Deploying USDXToken...");
        USDXToken usdx = new USDXToken(deployer);
        console2.log("   USDXToken deployed at:", address(usdx));
        
        // Configuration - Update these with actual addresses
        address LZ_ENDPOINT = address(0); // TODO: Set LayerZero endpoint address
        uint32 HUB_CHAIN_ID = 30101; // Ethereum endpoint ID
        uint32 LOCAL_EID = chainId == 137 ? 30109 : 30110; // Polygon or Mumbai
        
        // Check if LayerZero is supported (Arc doesn't support LayerZero)
        bool isLayerZeroSupported = (chainId != 5042002);
        
        // 2. Deploy USDXShareOFT (OVault shares on spoke chain) - Skip for Arc
        USDXShareOFT shareOFT;
        if (isLayerZeroSupported) {
            console2.log("\n2. Deploying USDXShareOFT...");
            shareOFT = new USDXShareOFT(
                "USDX Vault Shares",
                "USDX-SHARES",
                LZ_ENDPOINT, // TODO: Set actual LayerZero endpoint
                LOCAL_EID,
                deployer
            );
            console2.log("   USDXShareOFT deployed at:", address(shareOFT));
        } else {
            console2.log("\n2. Skipping USDXShareOFT deployment (Arc chain - LayerZero not supported)");
        }
        
        // 3. Deploy USDXSpokeMinter
        console2.log("\n3. Deploying USDXSpokeMinter...");
        USDXSpokeMinter minter = new USDXSpokeMinter(
            address(usdx),
            isLayerZeroSupported ? address(shareOFT) : address(0), // address(0) for Arc
            isLayerZeroSupported ? LZ_ENDPOINT : address(0), // address(0) for Arc
            HUB_CHAIN_ID,
            deployer
        );
        console2.log("   USDXSpokeMinter deployed at:", address(minter));
        
        // 4. Grant minter permissions on USDX token
        console2.log("\n4. Setting up permissions...");
        usdx.grantRole(MINTER_ROLE, address(minter));
        console2.log("   Granted MINTER_ROLE to minter");
        
        usdx.grantRole(BURNER_ROLE, address(minter));
        console2.log("   Granted BURNER_ROLE to minter");
        
        if (isLayerZeroSupported) {
            shareOFT.setMinter(address(minter)); // Minter can mint shares
            console2.log("   Set minter on USDXShareOFT");
        } else {
            console2.log("   Arc chain: Using verified hub positions instead of shareOFT");
            // Grant POSITION_UPDATER_ROLE to oracle for Arc chain
            minter.grantRole(POSITION_UPDATER_ROLE, POSITION_ORACLE);
            console2.log("   Granted POSITION_UPDATER_ROLE to oracle");
        }
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console2.log("\n=== Deployment Complete ===");
        console2.log("USDXToken:", address(usdx));
        console2.log("USDXSpokeMinter:", address(minter));
        if (isLayerZeroSupported) {
            console2.log("USDXShareOFT:", address(shareOFT));
        } else {
            console2.log("USDXShareOFT: Not deployed (Arc chain - LayerZero not supported)");
        }
        console2.log("Position Oracle:", POSITION_ORACLE);
        
        // Print verification commands
        console2.log("\n=== Verification Commands ===");
        console2.log("Use these commands to verify contracts on block explorer");
        console2.log("USDXToken address:", address(usdx));
        console2.log("USDXSpokeMinter address:", address(minter));
    }
}
