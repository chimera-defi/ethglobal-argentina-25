// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXSpokeMinter} from "../../contracts/USDXSpokeMinter.sol";
import {USDXToken} from "../../contracts/USDXToken.sol";

contract USDXSpokeMinterTest is Test {
    USDXSpokeMinter public minter;
    USDXToken public usdx;
    
    address public admin = address(0x1);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    function setUp() public {
        // Deploy contracts
        usdx = new USDXToken(admin);
        minter = new USDXSpokeMinter(address(usdx), admin);
        
        // Grant minter the ability to mint/burn USDX
        vm.startPrank(admin);
        usdx.grantRole(MINTER_ROLE, address(minter));
        usdx.grantRole(BURNER_ROLE, address(minter));
        vm.stopPrank();
    }
    
    function testDeployment() public view {
        assertEq(address(minter.usdxToken()), address(usdx));
        assertEq(minter.totalMinted(), 0);
    }
    
    function testMint() public {
        uint256 hubPosition = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Update user's hub position
        vm.prank(admin);
        minter.updateHubPosition(user1, hubPosition);
        
        // Mint USDX
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount, "User should have USDX");
        assertEq(minter.getMintedAmount(user1), mintAmount, "Minted amount should be tracked");
        assertEq(minter.totalMinted(), mintAmount, "Total minted should increase");
        assertEq(minter.getAvailableMintAmount(user1), hubPosition - mintAmount, "Available amount should decrease");
    }
    
    function testMintMultipleTimes() public {
        uint256 hubPosition = 1000 * 10**6;
        
        // Update user's hub position
        vm.prank(admin);
        minter.updateHubPosition(user1, hubPosition);
        
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
    
    function testMintRevertsIfNoPosition() public {
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.InsufficientPosition.selector);
        minter.mint(1000 * 10**6);
    }
    
    function testMintRevertsIfExceedsPosition() public {
        uint256 hubPosition = 1000 * 10**6;
        
        // Update position
        vm.prank(admin);
        minter.updateHubPosition(user1, hubPosition);
        
        // Try to mint more than position
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.ExceedsPosition.selector);
        minter.mint(hubPosition + 1);
    }
    
    function testBurn() public {
        uint256 hubPosition = 1000 * 10**6;
        uint256 mintAmount = 500 * 10**6;
        
        // Setup: update position and mint
        vm.prank(admin);
        minter.updateHubPosition(user1, hubPosition);
        
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
        assertEq(minter.getAvailableMintAmount(user1), hubPosition - (mintAmount - burnAmount), "Available should increase");
    }
    
    function testBurnAllowsReminting() public {
        uint256 hubPosition = 1000 * 10**6;
        
        // Update position
        vm.prank(admin);
        minter.updateHubPosition(user1, hubPosition);
        
        // Mint full amount
        vm.prank(user1);
        minter.mint(hubPosition);
        
        // Can't mint more
        vm.prank(user1);
        vm.expectRevert(USDXSpokeMinter.ExceedsPosition.selector);
        minter.mint(1);
        
        // Burn half
        vm.startPrank(user1);
        usdx.approve(address(minter), hubPosition / 2);
        minter.burn(hubPosition / 2);
        vm.stopPrank();
        
        // Now can mint again
        vm.prank(user1);
        minter.mint(hubPosition / 2);
        
        assertEq(minter.getMintedAmount(user1), hubPosition);
    }
    
    function testBurnRevertsIfInsufficientBalance() public {
        vm.startPrank(user1);
        usdx.approve(address(minter), 1000 * 10**6);
        vm.expectRevert(USDXSpokeMinter.InsufficientPosition.selector);
        minter.burn(1000 * 10**6);
        vm.stopPrank();
    }
    
    function testUpdateHubPosition() public {
        uint256 position1 = 1000 * 10**6;
        uint256 position2 = 2000 * 10**6;
        
        // Update position first time
        vm.prank(admin);
        minter.updateHubPosition(user1, position1);
        assertEq(minter.getHubPosition(user1), position1);
        
        // Update position second time
        vm.prank(admin);
        minter.updateHubPosition(user1, position2);
        assertEq(minter.getHubPosition(user1), position2);
    }
    
    function testUpdateHubPositionRevertsIfNotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert();
        minter.updateHubPosition(user2, 1000 * 10**6);
    }
    
    function testBatchUpdateHubPositions() public {
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = address(0x5);
        
        uint256[] memory positions = new uint256[](3);
        positions[0] = 1000 * 10**6;
        positions[1] = 2000 * 10**6;
        positions[2] = 3000 * 10**6;
        
        // Batch update
        vm.prank(admin);
        minter.batchUpdateHubPositions(users, positions);
        
        // Verify all positions were updated
        assertEq(minter.getHubPosition(user1), 1000 * 10**6);
        assertEq(minter.getHubPosition(user2), 2000 * 10**6);
        assertEq(minter.getHubPosition(address(0x5)), 3000 * 10**6);
    }
    
    function testBatchUpdateRevertsIfArrayLengthMismatch() public {
        address[] memory users = new address[](2);
        uint256[] memory positions = new uint256[](3);
        
        vm.prank(admin);
        vm.expectRevert("Array length mismatch");
        minter.batchUpdateHubPositions(users, positions);
    }
    
    function testPauseAndUnpause() public {
        uint256 hubPosition = 1000 * 10**6;
        
        // Update position
        vm.prank(admin);
        minter.updateHubPosition(user1, hubPosition);
        
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
        uint256 hubPosition = 1000 * 10**6;
        
        // Initially zero
        assertEq(minter.getAvailableMintAmount(user1), 0);
        
        // After setting position
        vm.prank(admin);
        minter.updateHubPosition(user1, hubPosition);
        assertEq(minter.getAvailableMintAmount(user1), hubPosition);
        
        // After minting
        vm.prank(user1);
        minter.mint(600 * 10**6);
        assertEq(minter.getAvailableMintAmount(user1), 400 * 10**6);
    }
    
    function testMultipleUsersIndependent() public {
        // Set positions for both users
        vm.startPrank(admin);
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
    
    function testFuzzMint(uint256 position, uint256 mintAmount) public {
        // Bound values
        position = bound(position, 1, 1_000_000 * 10**6);
        mintAmount = bound(mintAmount, 1, position);
        
        // Update position
        vm.prank(admin);
        minter.updateHubPosition(user1, position);
        
        // Mint
        vm.prank(user1);
        minter.mint(mintAmount);
        
        // Verify
        assertEq(usdx.balanceOf(user1), mintAmount);
        assertEq(minter.getMintedAmount(user1), mintAmount);
        assertEq(minter.getAvailableMintAmount(user1), position - mintAmount);
    }
}
