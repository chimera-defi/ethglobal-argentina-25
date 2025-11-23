// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXSpokeMinter} from "../../contracts/USDXSpokeMinter.sol";
import {USDXToken} from "../../contracts/USDXToken.sol";
import {USDXShareOFT} from "../../contracts/USDXShareOFT.sol";
import {MockLayerZeroEndpoint} from "../../contracts/mocks/MockLayerZeroEndpoint.sol";

contract USDXSpokeMinterTest is Test {
    USDXSpokeMinter public minter;
    USDXToken public usdx;
    USDXShareOFT public shareOFT;
    MockLayerZeroEndpoint public lzEndpoint;
    
    address public admin = address(0x1);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    uint32 constant HUB_CHAIN_ID = 30101; // Ethereum
    uint32 constant LOCAL_EID = 30109; // Polygon
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    function setUp() public {
        // Deploy contracts
        lzEndpoint = new MockLayerZeroEndpoint(LOCAL_EID);
        usdx = new USDXToken(admin);
        
        shareOFT = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            address(lzEndpoint),
            LOCAL_EID,
            admin
        );
        
        minter = new USDXSpokeMinter(
            address(usdx),
            address(shareOFT),
            address(lzEndpoint),
            HUB_CHAIN_ID,
            admin
        );
        
        // Grant minter the ability to mint/burn USDX
        vm.startPrank(admin);
        usdx.grantRole(MINTER_ROLE, address(minter));
        usdx.grantRole(BURNER_ROLE, address(minter));
        shareOFT.setMinter(admin); // Admin can mint shares for testing
        vm.stopPrank();
    }
    
    function testDeployment() public view {
        assertEq(address(minter.usdxToken()), address(usdx));
        assertEq(address(minter.shareOFT()), address(shareOFT));
        assertEq(minter.totalMinted(), 0);
    }
    
    function testMintUSDXFromOVault() public {
        uint256 shares = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Mint OVault shares to user
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Approve minter to transfer shares
        vm.startPrank(user1);
        shareOFT.approve(address(minter), mintAmount);
        
        // Mint USDX using shares
        minter.mintUSDXFromOVault(mintAmount);
        vm.stopPrank();
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount, "User should have USDX");
        assertEq(minter.getMintedAmount(user1), mintAmount, "Minted amount should be tracked");
        assertEq(minter.totalMinted(), mintAmount, "Total minted should increase");
        assertEq(shareOFT.balanceOf(user1), shares - mintAmount, "Shares should be burned");
    }
    
    function testMint() public {
        uint256 shares = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Mint OVault shares to user
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Approve minter to transfer shares
        vm.startPrank(user1);
        shareOFT.approve(address(minter), mintAmount);
        
        // Mint USDX
        minter.mint(mintAmount);
        vm.stopPrank();
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount, "User should have USDX");
        assertEq(minter.getMintedAmount(user1), mintAmount, "Minted amount should be tracked");
        assertEq(minter.totalMinted(), mintAmount, "Total minted should increase");
        assertEq(shareOFT.balanceOf(user1), shares - mintAmount, "Shares should be burned");
    }
    
    function testMintMultipleTimes() public {
        uint256 shares = 1000 * 10**6;
        
        // Mint shares to user
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Approve minter to transfer shares
        vm.startPrank(user1);
        shareOFT.approve(address(minter), shares);
        
        // Mint in multiple steps
        minter.mint(300 * 10**6);
        minter.mint(200 * 10**6);
        minter.mint(100 * 10**6);
        vm.stopPrank();
        
        // Verify total minted
        assertEq(minter.getMintedAmount(user1), 600 * 10**6);
        assertEq(minter.getAvailableMintAmount(user1), 400 * 10**6);
    }
    
    function testMintRevertsIfZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.ZeroAmount.selector);
        minter.mint(0);
    }
    
    function testMintRevertsIfNoShares() public {
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.InsufficientShares.selector);
        minter.mint(1000 * 10**6);
    }
    
    function testMintRevertsIfInsufficientShares() public {
        uint256 shares = 500 * 10**6;
        
        // Mint shares
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Try to mint more than shares
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.InsufficientShares.selector);
        minter.mint(shares + 1);
    }
    
    function testBurn() public {
        uint256 shares = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Setup: mint shares and mint USDX
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        vm.startPrank(user1);
        shareOFT.approve(address(minter), mintAmount);
        minter.mint(mintAmount);
        vm.stopPrank();
        
        // Burn half
        uint256 burnAmount = 250 * 10**6;
        vm.startPrank(user1);
        usdx.approve(address(minter), burnAmount);
        minter.burn(burnAmount);
        vm.stopPrank();
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount - burnAmount, "USDX balance should decrease");
        assertEq(minter.getMintedAmount(user1), mintAmount - burnAmount, "Minted tracking should decrease");
    }
    
    function testBurnAllowsReminting() public {
        uint256 shares = 1000 * 10**6;
        
        // Mint shares
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Mint full amount
        vm.startPrank(user1);
        shareOFT.approve(address(minter), shares);
        minter.mint(shares);
        vm.stopPrank();
        
        // Can't mint more (no shares left)
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.InsufficientShares.selector);
        minter.mint(1);
        
        // Burn half
        vm.startPrank(user1);
        usdx.approve(address(minter), shares / 2);
        minter.burn(shares / 2);
        vm.stopPrank();
        
        // Mint more shares
        vm.prank(admin);
        shareOFT.mint(user1, shares / 2);
        
        // Now can mint again
        vm.startPrank(user1);
        shareOFT.approve(address(minter), shares / 2);
        minter.mint(shares / 2);
        vm.stopPrank();
        
        assertEq(minter.getMintedAmount(user1), shares);
    }
    
    function testBurnRevertsIfInsufficientBalance() public {
        vm.startPrank(user1);
        usdx.approve(address(minter), 1000 * 10**6);
        vm.expectRevert(USDXSpokeMinter.InsufficientShares.selector);
        minter.burn(1000 * 10**6);
        vm.stopPrank();
    }
    
    function testGetUserOVaultShares() public {
        uint256 shares = 1000 * 10**6;
        
        // Initially zero
        assertEq(minter.getUserOVaultShares(user1), 0);
        
        // After minting shares
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        assertEq(minter.getUserOVaultShares(user1), shares);
    }
    
    function testSetShareOFT() public {
        USDXShareOFT newShareOFT = new USDXShareOFT(
            "New Shares",
            "NEW",
            address(lzEndpoint),
            LOCAL_EID,
            admin
        );
        
        vm.prank(admin);
        minter.setShareOFT(address(newShareOFT));
        
        assertEq(address(minter.shareOFT()), address(newShareOFT));
    }
    
    function testPauseAndUnpause() public {
        uint256 shares = 1000 * 10**6;
        
        // Mint shares
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Pause
        vm.prank(admin);
        minter.pause();
        
        // Mint should revert when paused
        vm.prank(user1);
        vm.expectRevert();
        minter.mint(100 * 10**6);
        
        // Unpause
        vm.prank(admin);
        minter.unpause();
        
        // Should work after unpause (need approval)
        vm.startPrank(user1);
        shareOFT.approve(address(minter), 100 * 10**6);
        minter.mint(100 * 10**6);
        vm.stopPrank();
        
        assertEq(usdx.balanceOf(user1), 100 * 10**6);
    }
    
    function testGetAvailableMintAmount() public {
        uint256 shares = 1000 * 10**6;
        
        // Initially zero
        assertEq(minter.getAvailableMintAmount(user1), 0);
        
        // After minting shares
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        assertEq(minter.getAvailableMintAmount(user1), shares);
        
        // After minting USDX (need approval)
        vm.startPrank(user1);
        shareOFT.approve(address(minter), 600 * 10**6);
        minter.mint(600 * 10**6);
        vm.stopPrank();
        assertEq(minter.getAvailableMintAmount(user1), 400 * 10**6);
    }
    
    function testMultipleUsersIndependent() public {
        // Mint shares for both users
        vm.startPrank(admin);
        shareOFT.mint(user1, 1000 * 10**6);
        shareOFT.mint(user2, 2000 * 10**6);
        vm.stopPrank();
        
        // User1 mints (need approval)
        vm.startPrank(user1);
        shareOFT.approve(address(minter), 500 * 10**6);
        minter.mint(500 * 10**6);
        vm.stopPrank();
        
        // User2 should still have full capacity
        assertEq(minter.getAvailableMintAmount(user2), 2000 * 10**6);
        
        // User2 mints (need approval)
        vm.startPrank(user2);
        shareOFT.approve(address(minter), 1500 * 10**6);
        minter.mint(1500 * 10**6);
        vm.stopPrank();
        
        // Verify independence
        assertEq(minter.getMintedAmount(user1), 500 * 10**6);
        assertEq(minter.getMintedAmount(user2), 1500 * 10**6);
        assertEq(minter.totalMinted(), 2000 * 10**6);
    }
    
    function testFuzzMint(uint256 shares, uint256 mintAmount) public {
        // Bound values
        shares = bound(shares, 1, 1_000_000 * 10**6);
        mintAmount = bound(mintAmount, 1, shares);
        
        // Mint shares
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Mint (need approval)
        vm.startPrank(user1);
        shareOFT.approve(address(minter), mintAmount);
        minter.mint(mintAmount);
        vm.stopPrank();
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount);
        assertEq(minter.getMintedAmount(user1), mintAmount);
        assertEq(minter.getAvailableMintAmount(user1), shares - mintAmount);
    }
}

/**
 * @title USDXSpokeMinterArcTest
 * @notice Tests for Arc chain functionality (without LayerZero)
 */
contract USDXSpokeMinterArcTest is Test {
    USDXSpokeMinter public minter;
    USDXToken public usdx;
    
    address public admin = address(0x1);
    address public user1 = address(0x3);
    address public oracle = address(0x5);
    
    uint32 constant HUB_CHAIN_ID = 30101; // Ethereum
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    function setUp() public {
        // Deploy contracts for Arc chain (no LayerZero)
        usdx = new USDXToken(admin);
        
        // Deploy minter without shareOFT and lzEndpoint (Arc chain)
        minter = new USDXSpokeMinter(
            address(usdx),
            address(0), // No shareOFT on Arc
            address(0), // No LayerZero on Arc
            HUB_CHAIN_ID,
            admin
        );
        
        // Grant minter the ability to mint/burn USDX
        vm.startPrank(admin);
        usdx.grantRole(MINTER_ROLE, address(minter));
        usdx.grantRole(BURNER_ROLE, address(minter));
        minter.grantRole(POSITION_UPDATER_ROLE, oracle); // Grant oracle role
        vm.stopPrank();
    }
    
    function testArcDeployment() public view {
        assertEq(address(minter.usdxToken()), address(usdx));
        assertEq(address(minter.shareOFT()), address(0), "shareOFT should be address(0) for Arc");
        assertEq(minter.totalMinted(), 0);
    }
    
    function testArcMintWithVerifiedPosition() public {
        uint256 verifiedPosition = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // User can mint USDX using verified position
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount, "User should have USDX");
        assertEq(minter.getMintedAmount(user1), mintAmount, "Minted amount should be tracked");
        assertEq(minter.totalMinted(), mintAmount, "Total minted should increase");
        assertEq(minter.getVerifiedHubPosition(user1), verifiedPosition - mintAmount, "Position should decrease");
    }
    
    function testArcMintRevertsIfInsufficientPosition() public {
        uint256 verifiedPosition = 100 * 10**6;
        uint256 mintAmount = 200 * 10**6;
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // Try to mint more than position
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.InsufficientHubPosition.selector);
        minter.mint(mintAmount);
    }
    
    function testArcGetAvailableMintAmount() public {
        uint256 verifiedPosition = 1000 * 10**6;
        
        // Initially zero
        assertEq(minter.getAvailableMintAmount(user1), 0);
        
        // After oracle updates position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        assertEq(minter.getAvailableMintAmount(user1), verifiedPosition);
        
        // After minting USDX
        vm.prank(user1);
        minter.mint(600 * 10**6);
        assertEq(minter.getAvailableMintAmount(user1), 400 * 10**6);
    }
    
    function testArcBatchUpdatePositions() public {
        address[] memory users = new address[](2);
        uint256[] memory positions = new uint256[](2);
        
        users[0] = user1;
        users[1] = address(0x6);
        positions[0] = 1000 * 10**6;
        positions[1] = 2000 * 10**6;
        
        // Batch update positions
        vm.prank(oracle);
        minter.batchUpdateHubPositions(users, positions);
        
        // Verify
        assertEq(minter.getVerifiedHubPosition(user1), 1000 * 10**6);
        assertEq(minter.getVerifiedHubPosition(users[1]), 2000 * 10**6);
    }
    
    function testArcGetUserOVaultSharesReturnsZero() public {
        // On Arc chain, getUserOVaultShares should return 0
        assertEq(minter.getUserOVaultShares(user1), 0);
    }
    
    function testArcBurnRestoresPosition() public {
        uint256 verifiedPosition = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        uint256 burnAmount = 300 * 10**6;
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // User mints USDX
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Verify mint succeeded - CRITICAL: These assertions must pass
        assertEq(usdx.balanceOf(user1), mintAmount, "User should have USDX tokens");
        assertEq(minter.getMintedAmount(user1), mintAmount, "Minted amount should be tracked");
        assertEq(minter.getVerifiedHubPosition(user1), verifiedPosition - mintAmount, "Position should decrease");
        assertEq(minter.getAvailableMintAmount(user1), verifiedPosition - mintAmount, "Available should decrease");
        
        // Verify mintedPerUser is set correctly before burn
        assertGe(minter.getMintedAmount(user1), burnAmount, "Must have minted at least burnAmount");
        
        // User burns some USDX
        vm.startPrank(user1);
        usdx.approve(address(minter), burnAmount);
        minter.burn(burnAmount);
        vm.stopPrank();
        
        // Verify position restored
        assertEq(minter.getVerifiedHubPosition(user1), verifiedPosition - mintAmount + burnAmount, "Position should be restored");
        assertEq(minter.getAvailableMintAmount(user1), verifiedPosition - mintAmount + burnAmount, "Available should be restored");
        assertEq(minter.getMintedAmount(user1), mintAmount - burnAmount, "Minted amount should decrease");
        assertEq(usdx.balanceOf(user1), mintAmount - burnAmount, "User USDX balance should decrease");
    }
    
    function testArcMintUSDXFromOVault() public {
        uint256 verifiedPosition = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // User mints USDX using mintUSDXFromOVault
        vm.prank(user1);
        minter.mintUSDXFromOVault(mintAmount);
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount, "User should have USDX");
        assertEq(minter.getMintedAmount(user1), mintAmount, "Minted amount should be tracked");
        assertEq(minter.totalMinted(), mintAmount, "Total minted should increase");
        assertEq(minter.getVerifiedHubPosition(user1), verifiedPosition - mintAmount, "Position should decrease");
    }
    
    function testArcBurnRevertsIfInsufficientMinted() public {
        uint256 verifiedPosition = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        uint256 burnAmount = 600 * 10**6; // More than minted
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // User mints USDX
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Try to burn more than minted
        vm.startPrank(user1);
        usdx.approve(address(minter), burnAmount);
        vm.expectRevert(USDXSpokeMinter.InsufficientShares.selector);
        minter.burn(burnAmount);
        vm.stopPrank();
    }
    
    function testArcBurnAllowsReminting() public {
        uint256 verifiedPosition = 1000 * 10**6;
        uint256 mintAmount = 1000 * 10**6;
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // User mints full amount
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Verify can't mint more (no position left)
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.InsufficientHubPosition.selector);
        minter.mint(1);
        
        // Burn half
        uint256 burnAmount = 500 * 10**6;
        vm.startPrank(user1);
        usdx.approve(address(minter), burnAmount);
        minter.burn(burnAmount);
        vm.stopPrank();
        
        // Verify position restored
        assertEq(minter.getVerifiedHubPosition(user1), burnAmount, "Position should be restored");
        assertEq(minter.getAvailableMintAmount(user1), burnAmount, "Available should be restored");
        
        // Now can mint again up to restored position
        vm.prank(user1);
        minter.mint(burnAmount);
        
        assertEq(minter.getMintedAmount(user1), mintAmount, "Should have minted full amount again");
    }
    
    function testArcBurnRevertsIfZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.ZeroAmount.selector);
        minter.burn(0);
    }
    
    function testArcPauseAndUnpause() public {
        uint256 verifiedPosition = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // Pause
        vm.prank(admin);
        minter.pause();
        
        // Mint should revert when paused
        vm.prank(user1);
        vm.expectRevert();
        minter.mint(mintAmount);
        
        // Unpause
        vm.prank(admin);
        minter.unpause();
        
        // Should work after unpause
        vm.prank(user1);
        minter.mint(mintAmount);
        
        assertEq(usdx.balanceOf(user1), mintAmount);
    }
    
    function testArcUpdateHubPositionRequiresRole() public {
        vm.prank(user1); // Not oracle
        vm.expectRevert();
        minter.updateHubPosition(user1, 1000 * 10**6);
    }
    
    function testArcMultipleUsersIndependent() public {
        address user2 = address(0x7);
        
        // Oracle updates positions for both users
        vm.startPrank(oracle);
        minter.updateHubPosition(user1, 1000 * 10**6);
        minter.updateHubPosition(user2, 2000 * 10**6);
        vm.stopPrank();
        
        // User1 mints
        vm.prank(user1);
        minter.mint(500 * 10**6);
        
        // User2 should still have full capacity
        assertEq(minter.getAvailableMintAmount(user2), 2000 * 10**6);
        
        // User2 mints
        vm.prank(user2);
        minter.mint(1500 * 10**6);
        
        // Verify independence
        assertEq(minter.getMintedAmount(user1), 500 * 10**6);
        assertEq(minter.getMintedAmount(user2), 1500 * 10**6);
        assertEq(minter.totalMinted(), 2000 * 10**6);
    }
    
    function testArcBatchUpdatePositionsMismatch() public {
        address[] memory users = new address[](2);
        uint256[] memory positions = new uint256[](3); // Mismatch
        
        users[0] = user1;
        users[1] = address(0x6);
        positions[0] = 1000 * 10**6;
        positions[1] = 2000 * 10**6;
        positions[2] = 3000 * 10**6;
        
        // Batch update should revert
        vm.prank(oracle);
        vm.expectRevert("Arrays length mismatch");
        minter.batchUpdateHubPositions(users, positions);
    }
    
    function testArcBurnFullAmount() public {
        uint256 verifiedPosition = 1000 * 10**6;
        uint256 mintAmount = 1000 * 10**6;
        
        // Oracle updates verified hub position
        vm.prank(oracle);
        minter.updateHubPosition(user1, verifiedPosition);
        
        // User mints full amount
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Burn full amount
        vm.startPrank(user1);
        usdx.approve(address(minter), mintAmount);
        minter.burn(mintAmount);
        vm.stopPrank();
        
        // Verify
        assertEq(minter.getMintedAmount(user1), 0, "Minted amount should be zero");
        assertEq(minter.getVerifiedHubPosition(user1), verifiedPosition, "Position should be fully restored");
        assertEq(usdx.balanceOf(user1), 0, "USDX balance should be zero");
    }
}
