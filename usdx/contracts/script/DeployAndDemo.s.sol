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

/**
 * @title DeployAndDemo
 * @notice Comprehensive deployment script for USDX Protocol on Base Sepolia and Ethereum Sepolia
 * @dev Deploys entire stack and runs cross-chain minting and bridging demo
 * 
 * Usage:
 *   # Deploy to Ethereum Sepolia (Hub)
 *   forge script script/DeployAndDemo.s.sol:DeployAndDemo --rpc-url $SEPOLIA_RPC_URL --broadcast --sig "runHub()"
 * 
 *   # Deploy to Base Sepolia (Spoke)
 *   forge script script/DeployAndDemo.s.sol:DeployAndDemo --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --sig "runSpoke(address,address,address)" <HUB_USDX> <HUB_SHARE_ADAPTER> <HUB_COMPOSER>
 * 
 *   # Run demo (requires both chains deployed)
 *   forge script script/DeployAndDemo.s.sol:DeployAndDemo --rpc-url $SEPOLIA_RPC_URL --broadcast --sig "runDemo()"
 */
contract DeployAndDemo is Script {
    // LayerZero Configuration
    address constant LZ_ENDPOINT_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address constant LZ_ENDPOINT_BASE_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    uint32 constant EID_SEPOLIA = 30101; // Ethereum Sepolia
    uint32 constant EID_BASE_SEPOLIA = 30110; // Base Sepolia
    
    // Chain IDs
    uint256 constant CHAIN_ID_SEPOLIA = 11155111;
    uint256 constant CHAIN_ID_BASE_SEPOLIA = 84532;
    
    // Deployment addresses (set after deployment)
    address public hubUSDX;
    address public hubVault;
    address public hubVaultWrapper;
    address public hubShareAdapter;
    address public hubComposer;
    address public hubUSDC;
    address public hubYearnVault;
    
    address public spokeUSDX;
    address public spokeShareOFT;
    address public spokeMinter;
    
    function setUp() public {
        // Load deployment addresses from environment or use defaults
        hubUSDX = vm.envOr("HUB_USDX", address(0));
        hubVault = vm.envOr("HUB_VAULT", address(0));
        hubVaultWrapper = vm.envOr("HUB_VAULT_WRAPPER", address(0));
        hubShareAdapter = vm.envOr("HUB_SHARE_ADAPTER", address(0));
        hubComposer = vm.envOr("HUB_COMPOSER", address(0));
        hubUSDC = vm.envOr("HUB_USDC", address(0));
        hubYearnVault = vm.envOr("HUB_YEARN_VAULT", address(0));
        
        spokeUSDX = vm.envOr("SPOKE_USDX", address(0));
        spokeShareOFT = vm.envOr("SPOKE_SHARE_OFT", address(0));
        spokeMinter = vm.envOr("SPOKE_MINTER", address(0));
    }
    
    /**
     * @notice Deploy hub chain contracts (Ethereum Sepolia)
     */
    function runHub() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        require(block.chainid == CHAIN_ID_SEPOLIA, "Must run on Ethereum Sepolia");
        
        console2.log("\n=== Deploying USDX Hub Chain (Ethereum Sepolia) ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("LayerZero Endpoint:", LZ_ENDPOINT_SEPOLIA);
        console2.log("LayerZero EID:", EID_SEPOLIA);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Mock USDC (if not already deployed)
        MockUSDC usdc;
        if (hubUSDC == address(0)) {
            console2.log("\n1. Deploying MockUSDC...");
            usdc = new MockUSDC();
            hubUSDC = address(usdc);
            console2.log("   MockUSDC:", hubUSDC);
            
            // Mint USDC to deployer
            usdc.mint(deployer, 1_000_000 * 10**6);
            console2.log("   Minted 1M USDC to deployer");
        } else {
            usdc = MockUSDC(hubUSDC);
            console2.log("\n1. Using existing MockUSDC:", hubUSDC);
        }
        
        // 2. Deploy Mock Yearn Vault (if not already deployed)
        MockYearnVault yearnVault;
        if (hubYearnVault == address(0)) {
            console2.log("\n2. Deploying MockYearnVault...");
            yearnVault = new MockYearnVault(hubUSDC);
            hubYearnVault = address(yearnVault);
            console2.log("   MockYearnVault:", hubYearnVault);
        } else {
            yearnVault = MockYearnVault(hubYearnVault);
            console2.log("\n2. Using existing MockYearnVault:", hubYearnVault);
        }
        
        // 3. Deploy USDX Token
        console2.log("\n3. Deploying USDXToken...");
        USDXToken usdx = new USDXToken(deployer);
        hubUSDX = address(usdx);
        console2.log("   USDXToken:", hubUSDX);
        
        // 4. Deploy OVault components
        console2.log("\n4. Deploying OVault components...");
        
        // 4a. Vault Wrapper
        USDXYearnVaultWrapper vaultWrapper = new USDXYearnVaultWrapper(
            hubUSDC,
            hubYearnVault,
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        hubVaultWrapper = address(vaultWrapper);
        console2.log("   USDXYearnVaultWrapper:", hubVaultWrapper);
        
        // 4b. Share OFT Adapter
        USDXShareOFTAdapter shareAdapter = new USDXShareOFTAdapter(
            hubVaultWrapper,
            LZ_ENDPOINT_SEPOLIA,
            EID_SEPOLIA,
            deployer
        );
        hubShareAdapter = address(shareAdapter);
        console2.log("   USDXShareOFTAdapter:", hubShareAdapter);
        
        // 4c. Vault Composer Sync
        USDXVaultComposerSync composer = new USDXVaultComposerSync(
            hubVaultWrapper,
            hubShareAdapter,
            hubUSDC,
            LZ_ENDPOINT_SEPOLIA,
            EID_SEPOLIA,
            deployer
        );
        hubComposer = address(composer);
        console2.log("   USDXVaultComposerSync:", hubComposer);
        
        // 5. Deploy USDX Vault
        console2.log("\n5. Deploying USDXVault...");
        USDXVault vault = new USDXVault(
            hubUSDC,
            hubUSDX,
            deployer, // treasury
            deployer, // admin
            hubComposer,
            hubShareAdapter,
            hubVaultWrapper
        );
        hubVault = address(vault);
        console2.log("   USDXVault:", hubVault);
        
        // 6. Grant roles
        console2.log("\n6. Setting up permissions...");
        bytes32 MINTER_ROLE = usdx.MINTER_ROLE();
        bytes32 BURNER_ROLE = usdx.BURNER_ROLE();
        
        usdx.grantRole(MINTER_ROLE, hubVault);
        usdx.grantRole(BURNER_ROLE, hubVault);
        console2.log("   Granted MINTER_ROLE and BURNER_ROLE to vault");
        
        // 7. Configure LayerZero
        console2.log("\n7. Configuring LayerZero...");
        usdx.setLayerZeroEndpoint(LZ_ENDPOINT_SEPOLIA, EID_SEPOLIA);
        console2.log("   Set LayerZero endpoint on USDXToken");
        
        // 8. Set Yearn vault
        vault.setYearnVault(hubYearnVault);
        console2.log("   Set Yearn vault on USDXVault");
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console2.log("\n=== Hub Chain Deployment Complete ===");
        console2.log("Network: Ethereum Sepolia");
        console2.log("Chain ID:", block.chainid);
        console2.log("");
        console2.log("Contracts:");
        console2.log("  MockUSDC:", hubUSDC);
        console2.log("  MockYearnVault:", hubYearnVault);
        console2.log("  USDXToken:", hubUSDX);
        console2.log("  USDXVault:", hubVault);
        console2.log("  USDXYearnVaultWrapper:", hubVaultWrapper);
        console2.log("  USDXShareOFTAdapter:", hubShareAdapter);
        console2.log("  USDXVaultComposerSync:", hubComposer);
        console2.log("");
        console2.log("Save these addresses for spoke chain deployment!");
        console2.log("Export them as environment variables:");
        console2.log("  export HUB_USDX=", hubUSDX);
        console2.log("  export HUB_SHARE_ADAPTER=", hubShareAdapter);
        console2.log("  export HUB_COMPOSER=", hubComposer);
    }
    
    /**
     * @notice Deploy spoke chain contracts (Base Sepolia)
     * @param _hubUSDX Hub chain USDX token address
     * @param _hubShareAdapter Hub chain Share OFT Adapter address
     * @param _hubComposer Hub chain Vault Composer address
     */
    function runSpoke(
        address _hubUSDX,
        address _hubShareAdapter,
        address _hubComposer
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        require(block.chainid == CHAIN_ID_BASE_SEPOLIA, "Must run on Base Sepolia");
        require(_hubUSDX != address(0), "Hub USDX address required");
        require(_hubShareAdapter != address(0), "Hub Share Adapter address required");
        require(_hubComposer != address(0), "Hub Composer address required");
        
        console2.log("\n=== Deploying USDX Spoke Chain (Base Sepolia) ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("LayerZero Endpoint:", LZ_ENDPOINT_BASE_SEPOLIA);
        console2.log("LayerZero EID:", EID_BASE_SEPOLIA);
        console2.log("Hub Chain EID:", EID_SEPOLIA);
        console2.log("Hub USDX:", _hubUSDX);
        console2.log("Hub Share Adapter:", _hubShareAdapter);
        console2.log("Hub Composer:", _hubComposer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy USDX Token
        console2.log("\n1. Deploying USDXToken...");
        USDXToken usdx = new USDXToken(deployer);
        spokeUSDX = address(usdx);
        console2.log("   USDXToken:", spokeUSDX);
        
        // 2. Deploy USDXShareOFT
        console2.log("\n2. Deploying USDXShareOFT...");
        USDXShareOFT shareOFT = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            LZ_ENDPOINT_BASE_SEPOLIA,
            EID_BASE_SEPOLIA,
            deployer
        );
        spokeShareOFT = address(shareOFT);
        console2.log("   USDXShareOFT:", spokeShareOFT);
        
        // 3. Deploy USDXSpokeMinter
        console2.log("\n3. Deploying USDXSpokeMinter...");
        USDXSpokeMinter minter = new USDXSpokeMinter(
            spokeUSDX,
            spokeShareOFT,
            LZ_ENDPOINT_BASE_SEPOLIA,
            EID_SEPOLIA, // Hub chain EID
            deployer
        );
        spokeMinter = address(minter);
        console2.log("   USDXSpokeMinter:", spokeMinter);
        
        // 4. Grant roles
        console2.log("\n4. Setting up permissions...");
        bytes32 MINTER_ROLE = usdx.MINTER_ROLE();
        bytes32 BURNER_ROLE = usdx.BURNER_ROLE();
        
        usdx.grantRole(MINTER_ROLE, spokeMinter);
        usdx.grantRole(BURNER_ROLE, spokeMinter);
        console2.log("   Granted MINTER_ROLE and BURNER_ROLE to minter");
        
        shareOFT.setMinter(_hubComposer); // Hub composer mints shares on spoke
        console2.log("   Set minter on USDXShareOFT to hub composer");
        
        // 5. Configure LayerZero
        console2.log("\n5. Configuring LayerZero...");
        usdx.setLayerZeroEndpoint(LZ_ENDPOINT_BASE_SEPOLIA, EID_BASE_SEPOLIA);
        console2.log("   Set LayerZero endpoint on USDXToken");
        
        // 6. Set trusted remotes for cross-chain communication
        console2.log("\n6. Setting trusted remotes...");
        
        // USDXToken trusted remotes
        bytes32 hubUSDXRemote = bytes32(uint256(uint160(_hubUSDX)));
        bytes32 spokeUSDXRemote = bytes32(uint256(uint160(spokeUSDX)));
        usdx.setTrustedRemote(EID_SEPOLIA, hubUSDXRemote);
        console2.log("   Set trusted remote for USDXToken (hub -> spoke)");
        
        // ShareOFT trusted remotes
        bytes32 hubShareAdapterRemote = bytes32(uint256(uint160(_hubShareAdapter)));
        bytes32 spokeShareOFTRemote = bytes32(uint256(uint160(spokeShareOFT)));
        shareOFT.setTrustedRemote(EID_SEPOLIA, hubShareAdapterRemote);
        console2.log("   Set trusted remote for USDXShareOFT (hub -> spoke)");
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console2.log("\n=== Spoke Chain Deployment Complete ===");
        console2.log("Network: Base Sepolia");
        console2.log("Chain ID:", block.chainid);
        console2.log("");
        console2.log("Contracts:");
        console2.log("  USDXToken:", spokeUSDX);
        console2.log("  USDXShareOFT:", spokeShareOFT);
        console2.log("  USDXSpokeMinter:", spokeMinter);
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Configure trusted remotes on hub chain");
        console2.log("2. Run demo to test cross-chain functionality");
    }
    
    /**
     * @notice Configure cross-chain connections (run after both chains deployed)
     * @dev Must be run on Ethereum Sepolia (hub chain)
     */
    function configureCrossChain() public {
        require(block.chainid == CHAIN_ID_SEPOLIA, "Must run on Ethereum Sepolia");
        require(hubUSDX != address(0), "Hub USDX not set");
        require(spokeUSDX != address(0), "Spoke USDX not set");
        require(hubShareAdapter != address(0), "Hub Share Adapter not set");
        require(spokeShareOFT != address(0), "Spoke Share OFT not set");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== Configuring Cross-Chain Connections ===");
        console2.log("Chain ID:", block.chainid);
        console2.log("Hub USDX:", hubUSDX);
        console2.log("Spoke USDX:", spokeUSDX);
        console2.log("Hub Share Adapter:", hubShareAdapter);
        console2.log("Spoke Share OFT:", spokeShareOFT);
        
        vm.startBroadcast(deployerPrivateKey);
        
        USDXToken hubUSDXToken = USDXToken(hubUSDX);
        USDXShareOFTAdapter hubAdapter = USDXShareOFTAdapter(hubShareAdapter);
        
        bytes32 spokeUSDXRemote = bytes32(uint256(uint160(spokeUSDX)));
        bytes32 spokeShareOFTRemote = bytes32(uint256(uint160(spokeShareOFT)));
        
        hubUSDXToken.setTrustedRemote(EID_BASE_SEPOLIA, spokeUSDXRemote);
        hubAdapter.setTrustedRemote(EID_BASE_SEPOLIA, spokeShareOFTRemote);
        
        vm.stopBroadcast();
        
        console2.log("✓ Hub chain configured");
        console2.log("✓ Cross-chain connections established");
        console2.log("\nNote: Trusted remotes on spoke chain should already be set during deployment");
    }
    
    /**
     * @notice Run cross-chain demo
     * @dev Must be run on Ethereum Sepolia (hub chain)
     */
    function runDemo() public {
        require(block.chainid == CHAIN_ID_SEPOLIA, "Must run on Ethereum Sepolia");
        require(hubUSDX != address(0), "Hub USDX not set");
        require(hubVault != address(0), "Hub Vault not set");
        require(hubUSDC != address(0), "Hub USDC not set");
        require(spokeUSDX != address(0), "Spoke USDX not set");
        require(spokeMinter != address(0), "Spoke Minter not set");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== USDX Cross-Chain Demo ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Load contracts
        USDXToken hubUSDXToken = USDXToken(hubUSDX);
        USDXVault vault = USDXVault(hubVault);
        MockUSDC usdc = MockUSDC(hubUSDC);
        
        // Demo: Deposit USDC on hub chain
        console2.log("\n=== Step 1: Deposit USDC on Hub Chain ===");
        uint256 depositAmount = 1000 * 10**6; // 1000 USDC
        
        uint256 usdcBalance = usdc.balanceOf(deployer);
        console2.log("Deployer USDC balance:", usdcBalance);
        
        if (usdcBalance < depositAmount) {
            console2.log("Minting additional USDC...");
            usdc.mint(deployer, depositAmount);
        }
        
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        
        uint256 hubUSDXBalance = hubUSDXToken.balanceOf(deployer);
        console2.log("✓ Deposited", depositAmount / 10**6, "USDC");
        console2.log("✓ Received", hubUSDXBalance / 10**6, "USDX on hub chain");
        
        vm.stopBroadcast();
        
        console2.log("\n=== Demo Complete ===");
        console2.log("To continue the demo:");
        console2.log("1. Bridge shares to Base Sepolia using USDXShareOFTAdapter");
        console2.log("2. Mint USDX on Base Sepolia using USDXSpokeMinter");
        console2.log("3. Transfer USDX cross-chain using USDXToken.sendCrossChain()");
        console2.log("4. Burn USDX and redeem shares");
    }
}
