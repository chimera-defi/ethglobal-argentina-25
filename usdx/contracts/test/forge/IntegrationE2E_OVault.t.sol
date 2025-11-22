// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
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
 * @notice Comprehensive end-to-end integration test for USDX Protocol with LayerZero OVault
 * @dev Tests the complete user journey:
 * 1. User deposits USDC on hub chain → receives vault wrapper shares
 * 2. User locks shares in adapter → receives OFT tokens
 * 3. Shares sent cross-chain via LayerZero → USDXShareOFT minted on spoke
 * 4. User mints USDX on spoke chain using shares
 * 5. User uses USDX on spoke chain
 * 6. User burns USDX → shares unlocked
 * 7. User redeems shares → receives USDC back
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
     */
    function testCompleteE2EFlow() public {
        uint256 depositAmount = DEPOSIT_AMOUNT;
        
        // ============ PHASE 1: Deposit on Hub Chain ============
        vm.prank(user);
        vault.deposit(depositAmount);
        
        // Verify deposit
        assertEq(vault.totalCollateral(), depositAmount);
        assertEq(usdxHub.balanceOf(user), depositAmount);
        assertGt(vaultWrapper.balanceOf(user), 0, "User should have vault wrapper shares");
        
        // ============ PHASE 2: Lock Shares and Send Cross-Chain ============
        uint256 shares = vaultWrapper.balanceOf(user);
        
        // Lock shares in adapter
        vm.startPrank(user);
        shareOFTAdapter.lockShares(shares);
        vm.stopPrank();
        
        // Verify shares locked
        assertEq(shareOFTAdapter.lockedShares(user), shares);
        assertEq(shareOFTAdapter.balanceOf(user), shares);
        assertEq(vaultWrapper.balanceOf(user), 0, "Shares should be transferred to adapter");
        
        // Send shares cross-chain
        bytes memory options = "";
        vm.startPrank(user);
        shareOFTAdapter.send{value: 0.001 ether}(
            SPOKE_EID,
            bytes32(uint256(uint160(user))),
            shares,
            options
        );
        vm.stopPrank();
        
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
        
        // Verify shares received on spoke
        assertEq(shareOFTSpoke.balanceOf(user), shares, "User should have shares on spoke");
        
        // ============ PHASE 3: Mint USDX on Spoke Chain ============
        uint256 mintAmount = shares / 2; // Mint half
        
        vm.startPrank(user);
        shareOFTSpoke.approve(address(spokeMinter), mintAmount);
        spokeMinter.mintUSDXFromOVault(mintAmount);
        vm.stopPrank();
        
        // Verify USDX minted
        assertEq(usdxSpoke.balanceOf(user), mintAmount);
        assertEq(shareOFTSpoke.balanceOf(user), shares - mintAmount, "Shares should be burned");
        assertEq(spokeMinter.getMintedAmount(user), mintAmount);
        
        // ============ PHASE 4: Use USDX (transfer to another user) ============
        address recipient = address(0x9999);
        uint256 transferAmount = mintAmount / 2;
        
        vm.prank(user);
        usdxSpoke.transfer(recipient, transferAmount);
        
        assertEq(usdxSpoke.balanceOf(recipient), transferAmount);
        assertEq(usdxSpoke.balanceOf(user), mintAmount - transferAmount);
        
        // ============ PHASE 5: Burn USDX and Unlock Shares ============
        uint256 burnAmount = mintAmount - transferAmount;
        
        vm.startPrank(user);
        usdxSpoke.approve(address(spokeMinter), burnAmount);
        spokeMinter.burn(burnAmount);
        vm.stopPrank();
        
        // Verify burn
        assertEq(usdxSpoke.balanceOf(user), 0);
        assertEq(spokeMinter.getMintedAmount(user), transferAmount, "Only transferred amount remains minted");
        
        // ============ PHASE 6: Redeem Remaining Shares ============
        uint256 remainingShares = shareOFTSpoke.balanceOf(user);
        
        // Send shares back to hub (simulate)
        vm.startPrank(user);
        shareOFTSpoke.send{value: 0.001 ether}(
            HUB_EID,
            bytes32(uint256(uint160(user))),
            remainingShares,
            options
        );
        vm.stopPrank();
        
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
        
        // Unlock shares
        vm.prank(user);
        shareOFTAdapter.unlockShares(remainingShares);
        
        // Verify shares unlocked
        assertEq(shareOFTAdapter.balanceOf(user), 0);
        assertGt(vaultWrapper.balanceOf(user), 0, "User should have shares back");
        
        // Redeem from vault wrapper
        uint256 finalShares = vaultWrapper.balanceOf(user);
        vm.prank(user);
        uint256 assets = vaultWrapper.redeem(finalShares, user, user);
        
        // Verify redemption
        assertGt(assets, 0, "User should receive assets");
        assertEq(vaultWrapper.balanceOf(user), 0, "All shares should be redeemed");
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
     */
    function testDepositViaComposer() public {
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        IOVaultComposer.DepositParams memory params = IOVaultComposer.DepositParams({
            assets: DEPOSIT_AMOUNT,
            dstEid: SPOKE_EID,
            receiver: receiver
        });
        
        vm.prank(user);
        composer.deposit{value: 0.001 ether}(params, options);
        
        // Verify deposit
        assertGt(shareOFTAdapter.lockedShares(address(composer)), 0, "Composer should have locked shares");
        assertGt(shareOFTAdapter.balanceOf(address(composer)), 0, "Composer should have OFT tokens");
    }
}
