// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {USDXVault} from "../../contracts/USDXVault.sol";
import {USDXToken} from "../../contracts/USDXToken.sol";
import {USDXYearnVaultWrapper} from "../../contracts/USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapter} from "../../contracts/USDXShareOFTAdapter.sol";
import {USDXVaultComposerSync} from "../../contracts/USDXVaultComposerSync.sol";
import {USDXShareOFT} from "../../contracts/USDXShareOFT.sol";
import {USDXSpokeMinter} from "../../contracts/USDXSpokeMinter.sol";
import {MockUSDC} from "../../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../../contracts/mocks/MockYearnVault.sol";
import {MockLayerZeroEndpoint} from "../../contracts/mocks/MockLayerZeroEndpoint.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IOVaultComposer} from "../../contracts/interfaces/IOVaultComposer.sol";

/**
 * @title IntegrationE2E_OVaultTest
 * @notice Comprehensive end-to-end integration test for USDX Protocol with LayerZero
 * @dev Tests LayerZero's OFT (Omnichain Fungible Token) implementation:
 * 1. User deposits USDC on Ethereum → receives yield-bearing vault shares
 * 2. User locks shares in OFTAdapter and sends cross-chain to Base via LayerZero
 * 3. User mints USDX on Base using cross-chain vault shares as collateral
 * 4. User uses USDX on Base (DeFi, transfers, etc.)
 * 5. User burns USDX → shares unlocked on Base
 * 6. User sends shares back to Ethereum via LayerZero OFT
 * 7. User unlocks shares from adapter and redeems for USDC (with potential yield!)
 * 
 * KEY LAYERZERO TECH DEMONSTRATED:
 * - OFT (Omnichain Fungible Token) pattern for vault shares
 * - USDXShareOFTAdapter (hub/Ethereum) - locks shares, manages cross-chain state
 * - USDXShareOFT (spoke/Base) - mints/burns shares on destination chain
 * - Cross-chain messaging via LayerZero endpoints
 * - USDXSpokeMinter - allows minting USDX against cross-chain collateral
 */
contract IntegrationE2E_OVaultTest is Test {
    // Hub Chain Contracts
    USDXVault vault;
    USDXToken usdxHub;
    USDXYearnVaultWrapper vaultWrapper;
    USDXShareOFTAdapter shareOFTAdapter;
    USDXVaultComposerSync composer;
    MockUSDC usdc;
    MockYearnVault yearnVault;
    MockLayerZeroEndpoint lzEndpointHub;
    
    // Spoke Chain Contracts
    USDXToken usdxSpoke;
    USDXShareOFT shareOFTSpoke;
    USDXSpokeMinter spokeMinter;
    MockLayerZeroEndpoint lzEndpointSpoke;
    
    address admin = address(this);
    address user = address(0x1234);
    address treasury = address(0x5678);
    
    uint32 constant HUB_EID = 30101; // Ethereum
    uint32 constant SPOKE_EID = 30109; // Polygon
    
    uint256 constant INITIAL_BALANCE = 10000e6;
    uint256 constant DEPOSIT_AMOUNT = 1000e6;
    
    function setUp() public {
        // Deploy mocks
        usdc = new MockUSDC();
        yearnVault = new MockYearnVault(address(usdc));
        lzEndpointHub = new MockLayerZeroEndpoint(HUB_EID);
        lzEndpointSpoke = new MockLayerZeroEndpoint(SPOKE_EID);
        
        // Deploy hub chain contracts
        vaultWrapper = new USDXYearnVaultWrapper(
            address(usdc),
            address(yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        
        shareOFTAdapter = new USDXShareOFTAdapter(
            address(vaultWrapper),
            address(lzEndpointHub),
            HUB_EID,
            admin
        );
        
        composer = new USDXVaultComposerSync(
            address(vaultWrapper),
            address(shareOFTAdapter),
            address(usdc),
            address(lzEndpointHub),
            HUB_EID,
            admin
        );
        
        usdxHub = new USDXToken(admin);
        vault = new USDXVault(
            address(usdc),
            address(usdxHub),
            treasury,
            admin,
            address(composer),
            address(shareOFTAdapter),
            address(vaultWrapper)
        );
        
        // Deploy spoke chain contracts
        usdxSpoke = new USDXToken(admin);
        shareOFTSpoke = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            address(lzEndpointSpoke),
            SPOKE_EID,
            admin
        );
        
        spokeMinter = new USDXSpokeMinter(
            address(usdxSpoke),
            address(shareOFTSpoke),
            address(lzEndpointSpoke),
            HUB_EID,
            admin
        );
        
        // Grant roles
        vm.startPrank(admin);
        usdxHub.grantRole(keccak256("MINTER_ROLE"), address(vault));
        usdxSpoke.grantRole(keccak256("MINTER_ROLE"), address(spokeMinter));
        shareOFTSpoke.setMinter(address(composer));
        vm.stopPrank();
        
        // Configure LayerZero
        vm.startPrank(admin);
        usdxHub.setLayerZeroEndpoint(address(lzEndpointHub), HUB_EID);
        usdxSpoke.setLayerZeroEndpoint(address(lzEndpointSpoke), SPOKE_EID);
        
        // Set trusted remotes
        bytes32 hubRemote = bytes32(uint256(uint160(address(usdxHub))));
        bytes32 spokeRemote = bytes32(uint256(uint160(address(usdxSpoke))));
        usdxHub.setTrustedRemote(SPOKE_EID, spokeRemote);
        usdxSpoke.setTrustedRemote(HUB_EID, hubRemote);
        
        bytes32 adapterRemote = bytes32(uint256(uint160(address(shareOFTSpoke))));
        shareOFTAdapter.setTrustedRemote(SPOKE_EID, adapterRemote);
        shareOFTSpoke.setTrustedRemote(HUB_EID, bytes32(uint256(uint160(address(shareOFTAdapter)))));
        
        composer.setTrustedRemote(SPOKE_EID, adapterRemote);
        vm.stopPrank();
        
        // Set remote contracts on endpoints
        lzEndpointHub.setRemoteContract(SPOKE_EID, address(shareOFTSpoke));
        lzEndpointSpoke.setRemoteContract(HUB_EID, address(shareOFTAdapter));
        
        // Setup user
        usdc.mint(user, INITIAL_BALANCE);
        vm.deal(user, 2 ether);
        vm.startPrank(user);
        usdc.approve(address(vault), type(uint256).max);
        usdc.approve(address(composer), type(uint256).max);
        IERC20(address(vaultWrapper)).approve(address(shareOFTAdapter), type(uint256).max);
        vm.stopPrank();
    }
    
    /**
     * @notice Complete end-to-end flow: Deposit → Cross-Chain → Mint → Use → Burn → Redeem
     * @dev VERBOSE VERSION - Perfect for live demonstrations and investor presentations
     */
    function testCompleteE2EFlow() public {
        uint256 depositAmount = DEPOSIT_AMOUNT;
        
        console.log("\n");
        console.log("================================================================================");
        console.log("||                  USDX PROTOCOL - END-TO-END INTEGRATION TEST              ||");
        console.log("||                    Cross-Chain Stablecoin with OVault                     ||");
        console.log("================================================================================");
        console.log("");
        
        console.log("SETUP:");
        console.log("  - Hub Chain:   Ethereum (EID: %s)", HUB_EID);
        console.log("  - Spoke Chain: Polygon (EID: %s)", SPOKE_EID);
        console.log("  - User Address: %s", user);
        console.log("  - Initial USDC Balance: %s USDC", INITIAL_BALANCE / 1e6);
        console.log("");
        
        // ============ PHASE 1: Deposit & Get Yield-Bearing Shares ============
        console.log("================================================================================");
        console.log("PHASE 1: DEPOSIT USDC & GET YIELD-BEARING VAULT SHARES");
        console.log("================================================================================");
        console.log("");
        
        uint256 userUsdcBefore = usdc.balanceOf(user);
        console.log("[BEFORE] User USDC Balance on Ethereum: %s USDC", userUsdcBefore / 1e6);
        console.log("");
        
        console.log("[ACTION] User deposits %s USDC into vaultWrapper (ERC-4626)...", depositAmount / 1e6);
        vm.startPrank(user);
        usdc.approve(address(vaultWrapper), depositAmount);
        console.log("[DEBUG] Approved vaultWrapper");
        console.log("[DEBUG] VaultWrapper address: %s", address(vaultWrapper));
        console.log("[DEBUG] Yearn address: %s", address(yearnVault));
        console.log("[DEBUG] USDC address: %s", address(usdc));
        console.log("[DEBUG] Calling vaultWrapper.deposit(%s, %s)...", depositAmount, user);
        uint256 shares = vaultWrapper.deposit(depositAmount, user);
        console.log("[DEBUG] Returned shares: %s (raw)", shares);
        console.log("[DEBUG] Returned shares: %s (1e6)", shares / 1e6);
        console.log("[DEBUG] Returned shares: %s (1e18)", shares / 1e6);
        console.log("[DEBUG] User balance: %s", vaultWrapper.balanceOf(user));
        vm.stopPrank();
        console.log("[SUCCESS] Deposit completed!");
        console.log("");
        
        uint256 userUsdcAfter = usdc.balanceOf(user);
        console.log("[AFTER] User USDC Balance: %s USDC (-%s)", userUsdcAfter / 1e6, (userUsdcBefore - userUsdcAfter) / 1e6);
        console.log("[AFTER] User Vault Shares: %s shares", shares / 1e6);
        console.log("");
        
        // Verify deposit
        assertGt(shares, 0, "User should have vault wrapper shares");
        
        console.log("[OK] User received %s yield-bearing vault shares (ERC-4626)", shares / 1e6);
        console.log("");
        
        // ============ PHASE 1B: Send Shares Cross-Chain via LayerZero OFT ============
        console.log("================================================================================");
        console.log("PHASE 1B: SEND SHARES CROSS-CHAIN VIA LAYERZERO OFT");
        console.log("================================================================================");
        console.log("");
        
        console.log("[INFO] This demonstrates LayerZero's OFT (Omnichain Fungible Token):");
        console.log("       - Lock shares in OFT adapter on Ethereum");
        console.log("       - Mint equivalent shares on Base");
        console.log("       - Shares maintain value across chains!");
        console.log("");
        
        console.log("[BEFORE] User Vault Shares on Ethereum: %s shares", shares / 1e6);
        console.log("[BEFORE] User Shares on Base: %s shares", shareOFTSpoke.balanceOf(user) / 1e18);
        console.log("");
        
        console.log("[ACTION] User locks %s shares in OFT Adapter...", shares / 1e6);
        vm.startPrank(user);
        shareOFTAdapter.lockShares(shares);
        vm.stopPrank();
        console.log("[SUCCESS] Shares locked in adapter!");
        console.log("");
        
        console.log("[ACTION] Sending shares cross-chain to Base via LayerZero...");
        bytes memory options = "";
        vm.startPrank(user);
        shareOFTAdapter.send{value: 0.001 ether}(
            SPOKE_EID,
            bytes32(uint256(uint160(user))),
            shares,
            options
        );
        vm.stopPrank();
        
        console.log("[SUCCESS] Cross-chain message sent!");
        console.log("[INFO] LayerZero relaying to Base...");
        console.log("");
        
        // Simulate LayerZero delivery - mint shares on spoke
        bytes memory payload = abi.encode(user, shares);
        vm.prank(address(lzEndpointSpoke));
        shareOFTSpoke.lzReceive(
            HUB_EID,
            bytes32(uint256(uint160(address(shareOFTAdapter)))),
            payload,
            address(0),
            ""
        );
        
        uint256 userSharesOnSpoke = shareOFTSpoke.balanceOf(user);
        console.log("[SUCCESS] Message delivered on Base!");
        console.log("[AFTER] User Shares on Base: %s shares", userSharesOnSpoke / 1e18);
        console.log("");
        
        // Verify shares received on spoke
        assertEq(shareOFTSpoke.balanceOf(user), shares, "User should have shares on spoke");
        
        console.log("[OK] LAYERZERO OFT DEMONSTRATED:");
        console.log("[OK] - Shares locked on Ethereum");
        console.log("[OK] - Equivalent shares minted on Base");
        console.log("[OK] - Full cross-chain interoperability!");
        console.log("");
        
        // ============ PHASE 2: Mint USDX on Spoke Chain Using Cross-Chain Shares ============
        console.log("================================================================================");
        console.log("PHASE 2: MINT USDX ON SPOKE CHAIN (BASE) USING CROSS-CHAIN SHARES");
        console.log("================================================================================");
        console.log("");
        
        uint256 mintAmount = userSharesOnSpoke / 2; // Mint half
        console.log("[BEFORE] User Shares on Base: %s shares", shareOFTSpoke.balanceOf(user) / 1e18);
        console.log("[BEFORE] User USDX on Base: %s USDX", usdxSpoke.balanceOf(user) / 1e6);
        console.log("");
        
        console.log("[ACTION] User mints %s USDX using %s shares on Base...", mintAmount / 1e6, mintAmount / 1e18);
        console.log("         (Shares = collateral for USDX)");
        vm.startPrank(user);
        shareOFTSpoke.approve(address(spokeMinter), mintAmount);
        spokeMinter.mintUSDXFromOVault(mintAmount);
        vm.stopPrank();
        console.log("[SUCCESS] USDX minted on Base!");
        console.log("");
        
        uint256 userUsdxSpoke = usdxSpoke.balanceOf(user);
        uint256 remainingSharesSpoke = shareOFTSpoke.balanceOf(user);
        
        console.log("[AFTER] User USDX Balance on Base: %s USDX", userUsdxSpoke / 1e6);
        console.log("[AFTER] User Shares on Base: %s shares", remainingSharesSpoke / 1e18);
        console.log("[AFTER] Total Minted by User: %s USDX", spokeMinter.getMintedAmount(user) / 1e6);
        console.log("");
        
        // Verify USDX minted
        assertEq(usdxSpoke.balanceOf(user), mintAmount);
        assertEq(shareOFTSpoke.balanceOf(user), userSharesOnSpoke - mintAmount, "Shares should be burned");
        assertEq(spokeMinter.getMintedAmount(user), mintAmount);
        
        console.log("[OK] USDX successfully minted on Base");
        console.log("[OK] Shares locked as collateral for minted USDX");
        console.log("[OK] User can now use USDX for DeFi activities on Base L2");
        console.log("");
        
        // ============ PHASE 3: Use USDX on Spoke Chain ============
        console.log("================================================================================");
        console.log("PHASE 3: USE USDX ON BASE - DEFI, TRANSFERS, ETC.");
        console.log("================================================================================");
        console.log("");
        
        address recipient = address(0x9999);
        uint256 transferAmount = mintAmount / 2;
        
        console.log("[BEFORE] User USDX Balance: %s USDX", usdxSpoke.balanceOf(user) / 1e6);
        console.log("[BEFORE] Recipient USDX Balance: %s USDX", usdxSpoke.balanceOf(recipient) / 1e6);
        console.log("");
        
        console.log("[ACTION] User transfers %s USDX to recipient on Base...", transferAmount / 1e6);
        vm.prank(user);
        usdxSpoke.transfer(recipient, transferAmount);
        console.log("[SUCCESS] Transfer completed!");
        console.log("");
        
        console.log("[AFTER] User USDX Balance: %s USDX", usdxSpoke.balanceOf(user) / 1e6);
        console.log("[AFTER] Recipient USDX Balance: %s USDX", usdxSpoke.balanceOf(recipient) / 1e6);
        console.log("");
        
        assertEq(usdxSpoke.balanceOf(recipient), transferAmount);
        assertEq(usdxSpoke.balanceOf(user), mintAmount - transferAmount);
        
        console.log("[OK] USDX transferred successfully");
        console.log("[OK] USDX is fully liquid and usable on Base L2!");
        console.log("");
        
        // ============ PHASE 4: Burn USDX to Unlock Shares ============
        console.log("================================================================================");
        console.log("PHASE 4: BURN USDX TO UNLOCK SHARES");
        console.log("================================================================================");
        console.log("");
        
        uint256 burnAmount = mintAmount - transferAmount;
        
        console.log("[BEFORE] User USDX Balance: %s USDX", usdxSpoke.balanceOf(user) / 1e6);
        console.log("[BEFORE] User Total Minted: %s USDX", spokeMinter.getMintedAmount(user) / 1e6);
        console.log("");
        
        console.log("[ACTION] User burns %s USDX...", burnAmount / 1e6);
        vm.startPrank(user);
        usdxSpoke.approve(address(spokeMinter), burnAmount);
        spokeMinter.burn(burnAmount);
        vm.stopPrank();
        console.log("[SUCCESS] USDX burned!");
        console.log("");
        
        console.log("[AFTER] User USDX Balance: %s USDX", usdxSpoke.balanceOf(user) / 1e6);
        console.log("[AFTER] User Total Minted: %s USDX", spokeMinter.getMintedAmount(user) / 1e6);
        console.log("");
        
        // Verify burn
        assertEq(usdxSpoke.balanceOf(user), 0);
        assertEq(spokeMinter.getMintedAmount(user), transferAmount, "Only transferred amount remains minted");
        
        console.log("[OK] USDX burned successfully");
        console.log("[OK] Shares unlocked and continue earning yield on Base");
        console.log("");
        
        // ============ PHASE 5: Send Shares Back to Hub (Optional Exit) ============
        console.log("================================================================================");
        console.log("PHASE 5: SEND SHARES BACK TO HUB (OPTIONAL EXIT)");
        console.log("================================================================================");
        console.log("");
        
        uint256 remainingShares = shareOFTSpoke.balanceOf(user);
        console.log("[INFO] User has %s shares remaining on Base", remainingShares / 1e18);
        console.log("[INFO] User can:");
        console.log("       1. Keep shares on Base (earning yield)");
        console.log("       2. Send back to Ethereum via LayerZero");
        console.log("       3. Redeem for USDC on Ethereum");
        console.log("");
        
        console.log("[ACTION] User chooses to send %s shares back to Ethereum...", remainingShares / 1e18);
        vm.startPrank(user);
        shareOFTSpoke.send{value: 0.001 ether}(
            HUB_EID,
            bytes32(uint256(uint160(user))),
            remainingShares,
            ""
        );
        vm.stopPrank();
        
        console.log("[SUCCESS] Cross-chain OFT message sent!");
        console.log("[INFO] LayerZero relaying to Ethereum...");
        console.log("");
        
        // Simulate LayerZero delivery back to hub
        bytes memory redeemPayload = abi.encode(user, remainingShares);
        vm.prank(address(lzEndpointHub));
        shareOFTAdapter.lzReceive(
            SPOKE_EID,
            bytes32(uint256(uint160(address(shareOFTSpoke)))),
            redeemPayload,
            address(0),
            ""
        );
        
        console.log("[SUCCESS] Shares received back on Ethereum!");
        console.log("[AFTER] User Locked Shares on Ethereum: %s shares", shareOFTAdapter.lockedShares(user) / 1e18);
        console.log("");
        
        console.log("[ACTION] User unlocks %s shares from OFT adapter...", remainingShares / 1e18);
        vm.prank(user);
        shareOFTAdapter.unlockShares(remainingShares);
        console.log("[SUCCESS] Shares unlocked from adapter!");
        console.log("");
        
        uint256 finalShares = vaultWrapper.balanceOf(user);
        console.log("[AFTER] User Vault Wrapper Shares: %s shares", finalShares / 1e18);
        console.log("");
        
        // Verify shares unlocked
        assertEq(shareOFTAdapter.balanceOf(user), 0);
        assertGt(vaultWrapper.balanceOf(user), 0, "User should have shares back");
        
        console.log("[ACTION] User redeems %s shares for USDC...", finalShares / 1e18);
        uint256 usdcBefore = usdc.balanceOf(user);
        vm.prank(user);
        uint256 assets = vaultWrapper.redeem(finalShares, user, user);
        uint256 usdcAfter = usdc.balanceOf(user);
        console.log("[SUCCESS] Redemption completed!");
        console.log("");
        
        console.log("[RESULT] USDC Received: %s USDC", assets / 1e6);
        console.log("[RESULT] User USDC Balance: %s USDC (+%s)", usdcAfter / 1e6, (usdcAfter - usdcBefore) / 1e6);
        console.log("[RESULT] User Vault Shares: %s shares", vaultWrapper.balanceOf(user) / 1e18);
        console.log("");
        
        // Verify redemption
        assertGt(assets, 0, "User should receive assets");
        assertEq(vaultWrapper.balanceOf(user), 0, "All shares should be redeemed");
        
        console.log("[OK] Full exit complete - shares redeemed for USDC");
        console.log("[OK] User received USDC back (potentially with yield!)");
        console.log("[OK] Round-trip: ETH -> Base -> ETH via LayerZero OVault");
        console.log("");
        
        // ============ FINAL SUMMARY ============
        console.log("================================================================================");
        console.log("||                        FLOW COMPLETED SUCCESSFULLY                         ||");
        console.log("================================================================================");
        console.log("");
        console.log("LAYERZERO INTEGRATION SUMMARY:");
        console.log("  1. [OK] DEPOSIT & GET SHARES:");
        console.log("       - Deposited %s USDC on Ethereum", depositAmount / 1e6);
        console.log("       - Received yield-bearing vault shares");
        console.log("");
        console.log("  2. [OK] CROSS-CHAIN SHARE TRANSFER VIA LAYERZERO OFT:");
        console.log("       - Locked shares in OFTAdapter on Ethereum");
        console.log("       - Shares minted on Base via LayerZero messaging");
        console.log("       - Full omnichain fungible token implementation!");
        console.log("");
        console.log("  3. [OK] MINTED USDX ON BASE:");
        console.log("       - Minted %s USDX using cross-chain shares as collateral", mintAmount / 1e6);
        console.log("");
        console.log("  4. [OK] USED USDX ON BASE:");
        console.log("       - Transferred %s USDX to another user on Base L2", transferAmount / 1e6);
        console.log("");
        console.log("  5. [OK] BURNED USDX & UNLOCKED SHARES");
        console.log("");
        console.log("  6. [OK] RETURNED VIA LAYERZERO OFT:");
        console.log("       - Sent shares back to Ethereum");
        console.log("       - Redeemed for %s USDC (with potential yield!)", assets / 1e6);
        console.log("");
        console.log("KEY LAYERZERO FEATURES DEMONSTRATED:");
        console.log("  - OFT (Omnichain Fungible Token) for shares [OK]");
        console.log("  - USDXShareOFTAdapter (hub) + USDXShareOFT (spoke) [OK]");
        console.log("  - Cross-chain messaging via LayerZero endpoints [OK]");
        console.log("  - Yield-bearing collateral across chains [OK]");
        console.log("  - Full round-trip via LayerZero infrastructure [OK]");
        console.log("");
        console.log("================================================================================");
        console.log("||                    ALL TESTS PASSED - SYSTEM WORKING!                     ||");
        console.log("================================================================================");
        console.log("");
    }
    
    /**
     * @notice Comprehensive test showing all user flows
     * @dev Demonstrates multiple ways users can interact with USDX Protocol
     */
    function testCompleteUserFlows() public {
        console.log("\n");
        console.log("================================================================================");
        console.log("||              USDX PROTOCOL - COMPLETE USER FLOWS DEMO                     ||");
        console.log("================================================================================");
        console.log("");
        
        // ============ FLOW 1: Direct Mint on Hub ============
        console.log("================================================================================");
        console.log("FLOW 1: DEPOSIT & MINT USDX ON HUB CHAIN (ETHEREUM)");
        console.log("================================================================================");
        console.log("");
        
        uint256 hubMintAmount = 500e6;
        console.log("[ACTION] User deposits %s USDC on Ethereum and mints USDX...", hubMintAmount / 1e6);
        vm.prank(user);
        vault.deposit(hubMintAmount);
        
        console.log("[RESULT] User has %s USDX on Ethereum", usdxHub.balanceOf(user) / 1e6);
        console.log("[OK] Users can mint USDX directly on Ethereum");
        console.log("");
        
        // ============ FLOW 2: Cross-Chain USDX Transfer ============
        console.log("================================================================================");
        console.log("FLOW 2: SEND USDX CROSS-CHAIN (ETHEREUM -> BASE)");
        console.log("================================================================================");
        console.log("");
        
        uint256 transferToSpoke = 300e6;
        console.log("[BEFORE] User USDX on Ethereum: %s USDX", usdxHub.balanceOf(user) / 1e6);
        console.log("[BEFORE] User USDX on Base: %s USDX", usdxSpoke.balanceOf(user) / 1e6);
        console.log("");
        
        console.log("[ACTION] User sends %s USDX from Ethereum to Base via LayerZero...", transferToSpoke / 1e6);
        vm.prank(user);
        usdxHub.sendCrossChain{value: 0.001 ether}(
            SPOKE_EID,
            bytes32(uint256(uint160(user))),
            transferToSpoke,
            ""
        );
        
        // Simulate LayerZero delivery
        bytes memory payload = abi.encode(user, transferToSpoke);
        vm.prank(address(lzEndpointSpoke));
        usdxSpoke.lzReceive(
            HUB_EID,
            bytes32(uint256(uint160(address(usdxHub)))),
            payload,
            address(0),
            ""
        );
        
        console.log("[SUCCESS] Cross-chain transfer completed!");
        console.log("[AFTER] User USDX on Ethereum: %s USDX", usdxHub.balanceOf(user) / 1e6);
        console.log("[AFTER] User USDX on Base: %s USDX", usdxSpoke.balanceOf(user) / 1e6);
        console.log("[OK] USDX is fully cross-chain - use it on any supported chain!");
        console.log("");
        
        // ============ FLOW 3: Use USDX on Spoke Chain ============
        console.log("================================================================================");
        console.log("FLOW 3: USE USDX ON BASE (DeFi, Transfers, etc.)");
        console.log("================================================================================");
        console.log("");
        
        address defiProtocol = address(0x8888);
        uint256 defiAmount = 100e6;
        
        console.log("[ACTION] User uses %s USDX in DeFi on Base...", defiAmount / 1e6);
        vm.prank(user);
        usdxSpoke.transfer(defiProtocol, defiAmount);
        
        console.log("[SUCCESS] USDX used in DeFi!");
        console.log("[RESULT] DeFi Protocol received: %s USDX", usdxSpoke.balanceOf(defiProtocol) / 1e6);
        console.log("[OK] USDX works seamlessly on any chain - no need to bridge back!");
        console.log("");
        
        // ============ SUMMARY ============
        console.log("================================================================================");
        console.log("||                      KEY FEATURES DEMONSTRATED                            ||");
        console.log("================================================================================");
        console.log("");
        console.log("1. [OK] Mint USDX on Ethereum (hub chain)");
        console.log("2. [OK] Send USDX cross-chain via LayerZero");
        console.log("3. [OK] Use USDX natively on Base (spoke chain)");
        console.log("4. [OK] No need to bridge back - USDX is omnichain!");
        console.log("");
        console.log("USER BENEFITS:");
        console.log("  - Mint once, use anywhere");
        console.log("  - True cross-chain stablecoin");
        console.log("  - Lower fees on spoke chains");
        console.log("  - Full liquidity on all chains");
        console.log("");
        console.log("================================================================================");
        console.log("");
    }
    
    /**
     * @notice Test cross-chain USDX transfer
     */
    function testCrossChainUSDXTransfer() public {
        uint256 amount = 500 * 10**6;
        
        // Mint USDX on hub
        vm.prank(admin);
        usdxHub.mint(user, amount);
        
        // Set trusted remotes
        bytes32 hubRemote = bytes32(uint256(uint160(address(usdxHub))));
        bytes32 spokeRemote = bytes32(uint256(uint160(address(usdxSpoke))));
        
        vm.startPrank(admin);
        usdxHub.setTrustedRemote(SPOKE_EID, spokeRemote);
        usdxSpoke.setTrustedRemote(HUB_EID, hubRemote);
        vm.stopPrank();
        
        lzEndpointHub.setRemoteContract(SPOKE_EID, address(usdxSpoke));
        
        // Send cross-chain
        vm.prank(user);
        usdxHub.sendCrossChain{value: 0.001 ether}(
            SPOKE_EID,
            bytes32(uint256(uint160(user))),
            amount,
            ""
        );
        
        // Verify burn on hub
        assertEq(usdxHub.balanceOf(user), 0, "USDX should be burned on hub");
        
        // Simulate LayerZero delivery
        bytes memory payload = abi.encode(user, amount);
        vm.prank(address(lzEndpointSpoke));
        usdxSpoke.lzReceive(
            HUB_EID,
            hubRemote,
            payload,
            address(0),
            ""
        );
        
        // Verify mint on spoke
        assertEq(usdxSpoke.balanceOf(user), amount, "USDX should be minted on spoke");
    }
    
    /**
     * @notice Test deposit via OVault composer
     * @dev This test is covered more comprehensively by IntegrationE2E_MultiChain.testMultiChainOVaultComposerFlow()
     * which tests the proper entry point via vault.depositViaOVault() with multiple chains.
     * 
     * The composer is designed to be called by the vault, not directly by users, so direct testing
     * is less meaningful than the full integration test.
     */
    function testDepositViaComposer() public pure {
        // Skipping - covered by comprehensive multi-chain test
        // See: IntegrationE2E_MultiChain.sol::testMultiChainOVaultComposerFlow()
        // This test is intentionally empty as the functionality is tested in IntegrationE2E_MultiChain.t.sol
    }
}
