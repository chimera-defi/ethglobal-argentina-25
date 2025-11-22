// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/USDXToken.sol";
import "../../contracts/core/MockUSDC.sol";

contract USDXTokenTest is Test {
    USDXToken public token;
    address public admin;
    address public vault;
    address public user;

    function setUp() public {
        admin = address(0x1);
        vault = address(0x2);
        user = address(0x3);
        
        token = new USDXToken(admin);
        
        // Grant vault role (admin is set in constructor, so we can grant roles)
        vm.startPrank(admin);
        token.grantRole(token.VAULT_ROLE(), vault);
        vm.stopPrank();
    }

    function testMint() public {
        uint256 amount = 1000e18;
        
        vm.prank(vault);
        token.mint(user, amount);
        
        assertEq(token.balanceOf(user), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testMintRevertsIfNotVault() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 1000e18);
    }

    function testBurn() public {
        uint256 mintAmount = 1000e18;
        uint256 burnAmount = 500e18;
        
        vm.prank(vault);
        token.mint(user, mintAmount);
        
        vm.prank(user);
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(user), mintAmount - burnAmount);
        assertEq(token.totalSupply(), mintAmount - burnAmount);
    }

    function testBurnFrom() public {
        uint256 mintAmount = 1000e18;
        uint256 burnAmount = 500e18;
        address spender = address(0x4);
        
        vm.prank(vault);
        token.mint(user, mintAmount);
        
        vm.prank(user);
        token.approve(spender, burnAmount);
        
        vm.prank(spender);
        token.burnFrom(user, burnAmount);
        
        assertEq(token.balanceOf(user), mintAmount - burnAmount);
        assertEq(token.allowance(user, spender), 0);
    }

    function testPause() public {
        vm.prank(admin);
        token.pause();
        
        assertTrue(token.paused());
        
        vm.prank(vault);
        vm.expectRevert();
        token.mint(user, 1000e18);
    }

    function testUnpause() public {
        vm.prank(admin);
        token.pause();
        
        vm.prank(admin);
        token.unpause();
        
        assertFalse(token.paused());
        
        vm.prank(vault);
        token.mint(user, 1000e18);
        
        assertEq(token.balanceOf(user), 1000e18);
    }
}
