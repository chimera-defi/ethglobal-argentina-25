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
        
        // Mint USDX using shares
        vm.prank(user1);
        minter.mintUSDXFromOVault(mintAmount);
        
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
        
        // Mint USDX
        vm.prank(user1);
        minter.mint(mintAmount);
        
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
        
        // Mint in multiple steps
        vm.startPrank(user1);
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
        
        vm.prank(user1);
        minter.mint(mintAmount);
        
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
        vm.prank(user1);
        minter.mint(shares);
        
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
        vm.prank(user1);
        minter.mint(shares / 2);
        
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
        
        // Should work after unpause
        vm.prank(user1);
        minter.mint(100 * 10**6);
        
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
        
        // After minting USDX
        vm.prank(user1);
        minter.mint(600 * 10**6);
        assertEq(minter.getAvailableMintAmount(user1), 400 * 10**6);
    }
    
    function testMultipleUsersIndependent() public {
        // Mint shares for both users
        vm.startPrank(admin);
        shareOFT.mint(user1, 1000 * 10**6);
        shareOFT.mint(user2, 2000 * 10**6);
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
    
    function testFuzzMint(uint256 shares, uint256 mintAmount) public {
        // Bound values
        shares = bound(shares, 1, 1_000_000 * 10**6);
        mintAmount = bound(mintAmount, 1, shares);
        
        // Mint shares
        vm.prank(admin);
        shareOFT.mint(user1, shares);
        
        // Mint
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount);
        assertEq(minter.getMintedAmount(user1), mintAmount);
        assertEq(minter.getAvailableMintAmount(user1), shares - mintAmount);
    }
}
