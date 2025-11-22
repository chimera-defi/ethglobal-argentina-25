// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/USDXToken.sol";
import "../../contracts/core/MockUSDC.sol";
import "../../contracts/core/MockYieldVault.sol";
import "../../contracts/core/USDXVault.sol";

contract USDXVaultTest is Test {
    USDXToken public usdxToken;
    MockUSDC public usdc;
    MockYieldVault public yieldVault;
    USDXVault public vault;
    
    address public admin;
    address public user;

    function setUp() public {
        admin = address(0x1);
        user = address(0x2);
        
        // Deploy tokens
        usdc = new MockUSDC();
        usdxToken = new USDXToken(admin);
        yieldVault = new MockYieldVault(address(usdc));
        
        // Deploy vault
        vault = new USDXVault(
            address(usdc),
            address(usdxToken),
            address(yieldVault)
        );
        
        // Grant vault role to mint USDX
        vm.startPrank(admin);
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(vault));
        vm.stopPrank();
        
        // Give user some USDC
        usdc.mint(user, 10000e6);
    }

    function testDepositUSDC() public {
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user);
        usdc.approve(address(vault), depositAmount);
        uint256 usdxAmount = vault.depositUSDC(depositAmount);
        vm.stopPrank();
        
        assertEq(usdxAmount, depositAmount);
        assertEq(usdxToken.balanceOf(user), depositAmount);
        assertEq(vault.getUserCollateral(user), depositAmount);
        assertEq(vault.getTotalCollateral(), depositAmount);
        assertEq(vault.getTotalUSDXMinted(), depositAmount);
    }

    function testWithdrawUSDC() public {
        uint256 depositAmount = 1000e6;
        uint256 withdrawAmount = 500e6;
        
        // Deposit first
        vm.startPrank(user);
        usdc.approve(address(vault), depositAmount);
        vault.depositUSDC(depositAmount);
        
        // Withdraw
        uint256 usdcAmount = vault.withdrawUSDC(withdrawAmount);
        vm.stopPrank();
        
        assertEq(usdxToken.balanceOf(user), depositAmount - withdrawAmount);
        assertEq(vault.getUserCollateral(user), depositAmount - withdrawAmount);
        assertEq(vault.getTotalCollateral(), depositAmount - withdrawAmount);
        assertEq(usdc.balanceOf(user), 10000e6 - depositAmount + usdcAmount);
    }

    function testYieldAccrual() public {
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user);
        usdc.approve(address(vault), depositAmount);
        vault.depositUSDC(depositAmount);
        vm.stopPrank();
        
        // Fast forward time to accrue yield
        vm.warp(block.timestamp + 365 days);
        
        // Check yield position
        (uint256 shares, uint256 assets) = vault.getUserYieldPosition(user);
        assertGt(assets, depositAmount); // Assets should have increased due to yield
    }

    function testWithdrawWithYield() public {
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user);
        usdc.approve(address(vault), depositAmount);
        vault.depositUSDC(depositAmount);
        vm.stopPrank();
        
        // Fast forward time to accrue yield
        vm.warp(block.timestamp + 365 days);
        
        // Withdraw should return more than deposited due to yield
        vm.startPrank(user);
        uint256 usdcAmount = vault.withdrawUSDC(depositAmount);
        vm.stopPrank();
        
        assertGt(usdcAmount, depositAmount); // Should receive yield
    }

    function testCollateralRatio() public {
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user);
        usdc.approve(address(vault), depositAmount);
        vault.depositUSDC(depositAmount);
        vm.stopPrank();
        
        uint256 ratio = vault.getCollateralRatio();
        assertEq(ratio, 1e18); // Should be 1:1 initially
    }
}
