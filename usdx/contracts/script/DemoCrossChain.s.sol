// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXVault} from "../contracts/USDXVault.sol";
import {USDXShareOFTAdapter} from "../contracts/USDXShareOFTAdapter.sol";
import {USDXShareOFT} from "../contracts/USDXShareOFT.sol";
import {USDXSpokeMinter} from "../contracts/USDXSpokeMinter.sol";
import {USDXYearnVaultWrapper} from "../contracts/USDXYearnVaultWrapper.sol";
import {MockUSDC} from "../contracts/mocks/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DemoCrossChain
 * @notice Comprehensive demo script showing cross-chain minting and bridging
 * @dev Demonstrates the complete USDX Protocol flow:
 * 1. Deposit USDC on hub chain (Ethereum Sepolia)
 * 2. Lock shares and bridge to spoke chain (Base Sepolia)
 * 3. Mint USDX on spoke chain using bridged shares
 * 4. Transfer USDX cross-chain
 * 5. Burn USDX and redeem shares
 * 
 * Usage:
 *   # Run on Hub Chain (Ethereum Sepolia)
 *   forge script script/DemoCrossChain.s.sol:DemoCrossChain --rpc-url $SEPOLIA_RPC_URL --broadcast --sig "runHubDemo()"
 * 
 *   # Run on Spoke Chain (Base Sepolia)
 *   forge script script/DemoCrossChain.s.sol:DemoCrossChain --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --sig "runSpokeDemo()"
 */
contract DemoCrossChain is Script {
    // LayerZero Configuration
    uint32 constant EID_SEPOLIA = 30101; // Ethereum Sepolia
    uint32 constant EID_BASE_SEPOLIA = 30110; // Base Sepolia
    
    // Contract addresses (set via environment variables)
    address public hubUSDX;
    address public hubVault;
    address public hubVaultWrapper;
    address public hubShareAdapter;
    address public hubUSDC;
    
    address public spokeUSDX;
    address public spokeShareOFT;
    address public spokeMinter;
    
    function setUp() public {
        hubUSDX = vm.envOr("HUB_USDX", address(0));
        hubVault = vm.envOr("HUB_VAULT", address(0));
        hubVaultWrapper = vm.envOr("HUB_VAULT_WRAPPER", address(0));
        hubShareAdapter = vm.envOr("HUB_SHARE_ADAPTER", address(0));
        hubUSDC = vm.envOr("HUB_USDC", address(0));
        
        spokeUSDX = vm.envOr("SPOKE_USDX", address(0));
        spokeShareOFT = vm.envOr("SPOKE_SHARE_OFT", address(0));
        spokeMinter = vm.envOr("SPOKE_MINTER", address(0));
    }
    
    /**
     * @notice Demo on Hub Chain: Deposit and bridge shares
     */
    function runHubDemo() public {
        require(hubUSDX != address(0), "HUB_USDX not set");
        require(hubVault != address(0), "HUB_VAULT not set");
        require(hubShareAdapter != address(0), "HUB_SHARE_ADAPTER not set");
        require(hubUSDC != address(0), "HUB_USDC not set");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== USDX Hub Chain Demo (Ethereum Sepolia) ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Load contracts
        USDXToken usdx = USDXToken(hubUSDX);
        USDXVault vault = USDXVault(hubVault);
        USDXShareOFTAdapter adapter = USDXShareOFTAdapter(hubShareAdapter);
        USDXYearnVaultWrapper wrapper = USDXYearnVaultWrapper(hubVaultWrapper);
        MockUSDC usdc = MockUSDC(hubUSDC);
        
        // Step 1: Deposit USDC
        console2.log("\n--- Step 1: Deposit USDC ---");
        uint256 depositAmount = 1000 * 10**6; // 1000 USDC
        
        uint256 usdcBalance = usdc.balanceOf(deployer);
        console2.log("Deployer USDC balance:", usdcBalance / 10**6);
        
        if (usdcBalance < depositAmount) {
            console2.log("Minting additional USDC...");
            usdc.mint(deployer, depositAmount);
        }
        
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        
        uint256 usdxBalance = usdx.balanceOf(deployer);
        uint256 wrapperShares = wrapper.balanceOf(deployer);
        
        console2.log("✓ Deposited", depositAmount / 10**6, "USDC");
        console2.log("✓ Received", usdxBalance / 10**6, "USDX");
        console2.log("✓ Received", wrapperShares / 10**6, "vault wrapper shares");
        
        // Step 2: Lock shares in adapter
        console2.log("\n--- Step 2: Lock Shares in Adapter ---");
        uint256 sharesToLock = wrapperShares / 2; // Lock half
        
        IERC20(address(wrapper)).approve(address(adapter), sharesToLock);
        adapter.lockShares(sharesToLock);
        
        uint256 adapterBalance = adapter.balanceOf(deployer);
        uint256 lockedShares = adapter.lockedShares(deployer);
        
        console2.log("✓ Locked", sharesToLock / 10**6, "shares");
        console2.log("✓ Received", adapterBalance / 10**6, "OFT tokens");
        console2.log("✓ Locked shares:", lockedShares / 10**6);
        
        // Step 3: Bridge shares to Base Sepolia
        console2.log("\n--- Step 3: Bridge Shares to Base Sepolia ---");
        uint256 bridgeAmount = adapterBalance / 2; // Bridge half
        
        bytes memory options = "";
        adapter.send{value: 0.001 ether}(
            EID_BASE_SEPOLIA,
            bytes32(uint256(uint160(deployer))),
            bridgeAmount,
            options
        );
        
        console2.log("✓ Bridged", bridgeAmount / 10**6, "shares to Base Sepolia");
        console2.log("⚠ Note: In production, LayerZero will deliver these shares");
        console2.log("  For demo purposes, manually trigger lzReceive on spoke chain");
        
        vm.stopBroadcast();
        
        console2.log("\n=== Hub Chain Demo Complete ===");
        console2.log("Next: Run runSpokeDemo() on Base Sepolia to mint USDX");
    }
    
    /**
     * @notice Demo on Spoke Chain: Receive shares and mint USDX
     */
    function runSpokeDemo() public {
        require(spokeUSDX != address(0), "SPOKE_USDX not set");
        require(spokeShareOFT != address(0), "SPOKE_SHARE_OFT not set");
        require(spokeMinter != address(0), "SPOKE_MINTER not set");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== USDX Spoke Chain Demo (Base Sepolia) ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Load contracts
        USDXToken usdx = USDXToken(spokeUSDX);
        USDXShareOFT shareOFT = USDXShareOFT(spokeShareOFT);
        USDXSpokeMinter minter = USDXSpokeMinter(spokeMinter);
        
        // Step 1: Check received shares (simulate LayerZero delivery)
        console2.log("\n--- Step 1: Check Received Shares ---");
        uint256 shareBalance = shareOFT.balanceOf(deployer);
        console2.log("Share OFT balance:", shareBalance / 10**6);
        
        if (shareBalance == 0) {
            console2.log("⚠ No shares received yet");
            console2.log("  In production, LayerZero delivers shares automatically");
            console2.log("  For demo, you may need to manually trigger lzReceive");
            console2.log("  Or mint shares directly for testing:");
            
            // For demo purposes, mint some shares directly
            uint256 demoShares = 500 * 10**6;
            shareOFT.mint(deployer, demoShares);
            shareBalance = demoShares;
            console2.log("  ✓ Minted", demoShares / 10**6, "shares for demo");
        }
        
        // Step 2: Mint USDX using shares
        console2.log("\n--- Step 2: Mint USDX Using Shares ---");
        uint256 mintAmount = shareBalance / 2; // Mint half
        
        shareOFT.approve(address(minter), mintAmount);
        minter.mintUSDXFromOVault(mintAmount);
        
        uint256 usdxBalance = usdx.balanceOf(deployer);
        uint256 remainingShares = shareOFT.balanceOf(deployer);
        uint256 mintedAmount = minter.getMintedAmount(deployer);
        
        console2.log("✓ Minted", mintAmount / 10**6, "USDX");
        console2.log("✓ USDX balance:", usdxBalance / 10**6);
        console2.log("✓ Remaining shares:", remainingShares / 10**6);
        console2.log("✓ Total minted by user:", mintedAmount / 10**6);
        
        // Step 3: Transfer USDX to another address
        console2.log("\n--- Step 3: Transfer USDX ---");
        address recipient = address(0x1234);
        uint256 transferAmount = usdxBalance / 2;
        
        usdx.transfer(recipient, transferAmount);
        
        uint256 recipientBalance = usdx.balanceOf(recipient);
        uint256 newBalance = usdx.balanceOf(deployer);
        
        console2.log("✓ Transferred", transferAmount / 10**6, "USDX to", recipient);
        console2.log("✓ Recipient balance:", recipientBalance / 10**6);
        console2.log("✓ Remaining balance:", newBalance / 10**6);
        
        // Step 4: Burn USDX
        console2.log("\n--- Step 4: Burn USDX ---");
        uint256 burnAmount = newBalance;
        
        usdx.approve(address(minter), burnAmount);
        minter.burn(burnAmount);
        
        uint256 finalBalance = usdx.balanceOf(deployer);
        uint256 finalMinted = minter.getMintedAmount(deployer);
        
        console2.log("✓ Burned", burnAmount / 10**6, "USDX");
        console2.log("✓ Final USDX balance:", finalBalance / 10**6);
        console2.log("✓ Final minted amount:", finalMinted / 10**6);
        
        vm.stopBroadcast();
        
        console2.log("\n=== Spoke Chain Demo Complete ===");
        console2.log("✓ Successfully demonstrated:");
        console2.log("  - Receiving shares from hub chain");
        console2.log("  - Minting USDX using shares");
        console2.log("  - Transferring USDX");
        console2.log("  - Burning USDX");
    }
    
    /**
     * @notice Simulate LayerZero delivery (for testing)
     */
    function simulateLayerZeroDelivery(
        address user,
        uint256 amount
    ) public {
        require(spokeShareOFT != address(0), "SPOKE_SHARE_OFT not set");
        require(hubShareAdapter != address(0), "HUB_SHARE_ADAPTER not set");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== Simulating LayerZero Delivery ===");
        console2.log("User:", user);
        console2.log("Amount:", amount / 10**6);
        
        vm.startBroadcast(deployerPrivateKey);
        
        USDXShareOFT shareOFT = USDXShareOFT(spokeShareOFT);
        
        // Simulate lzReceive call
        bytes memory payload = abi.encode(user, amount);
        bytes32 sender = bytes32(uint256(uint160(hubShareAdapter)));
        
        // Note: This would normally be called by LayerZero endpoint
        // For demo, we'll mint directly
        shareOFT.mint(user, amount);
        
        console2.log("✓ Simulated delivery of", amount / 10**6, "shares to", user);
        
        vm.stopBroadcast();
    }
}
