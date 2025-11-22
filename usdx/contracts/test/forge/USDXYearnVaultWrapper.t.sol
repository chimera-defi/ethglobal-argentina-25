// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXYearnVaultWrapper} from "../../contracts/USDXYearnVaultWrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IYearnVault} from "../../contracts/interfaces/IYearnVault.sol";
import {MockUSDC} from "../../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../../contracts/mocks/MockYearnVault.sol";

contract USDXYearnVaultWrapperTest is Test {
    USDXYearnVaultWrapper wrapper;
    MockUSDC usdc;
    MockYearnVault yearnVault;
    
    address user = address(0x1234);
    address owner = address(this);
    
    uint256 constant INITIAL_BALANCE = 10000e6; // 10,000 USDC
    uint256 constant DEPOSIT_AMOUNT = 1000e6; // 1,000 USDC
    
    function setUp() public {
        // Deploy mocks
        usdc = new MockUSDC();
        yearnVault = new MockYearnVault(address(usdc));
        
        // Deploy wrapper
        wrapper = new USDXYearnVaultWrapper(
            address(usdc),
            address(yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        
        // Setup user
        usdc.mint(user, INITIAL_BALANCE);
        vm.prank(user);
        usdc.approve(address(wrapper), type(uint256).max);
    }
    
    function testDeposit() public {
        vm.prank(user);
        uint256 shares = wrapper.deposit(DEPOSIT_AMOUNT, user);
        
        assertGt(shares, 0, "Shares should be greater than zero");
        assertEq(wrapper.balanceOf(user), shares, "User should have shares");
        assertEq(usdc.balanceOf(address(wrapper)), 0, "Wrapper should not hold USDC");
        assertGt(yearnVault.balanceOf(address(wrapper)), 0, "Wrapper should have Yearn shares");
    }
    
    function testDepositZeroAmount() public {
        vm.prank(user);
        vm.expectRevert(USDXYearnVaultWrapper.ZeroAmount.selector);
        wrapper.deposit(0, user);
    }
    
    function testDepositZeroReceiver() public {
        vm.prank(user);
        vm.expectRevert(USDXYearnVaultWrapper.ZeroAddress.selector);
        wrapper.deposit(DEPOSIT_AMOUNT, address(0));
    }
    
    function testRedeem() public {
        // First deposit
        vm.prank(user);
        uint256 shares = wrapper.deposit(DEPOSIT_AMOUNT, user);
        
        uint256 userBalanceBefore = usdc.balanceOf(user);
        
        // Then redeem
        vm.prank(user);
        uint256 assets = wrapper.redeem(shares, user, user);
        
        assertGt(assets, 0, "Assets should be greater than zero");
        assertEq(wrapper.balanceOf(user), 0, "User should have no shares");
        assertGt(usdc.balanceOf(user), userBalanceBefore, "User should receive USDC");
    }
    
    function testRedeemZeroShares() public {
        vm.prank(user);
        vm.expectRevert(USDXYearnVaultWrapper.ZeroAmount.selector);
        wrapper.redeem(0, user, user);
    }
    
    function testTotalAssets() public {
        vm.prank(user);
        wrapper.deposit(DEPOSIT_AMOUNT, user);
        
        uint256 totalAssets = wrapper.totalAssets();
        assertGt(totalAssets, 0, "Total assets should be greater than zero");
    }
    
    function testPauseUnpause() public {
        vm.prank(owner);
        wrapper.pause();
        
        vm.prank(user);
        vm.expectRevert();
        wrapper.deposit(DEPOSIT_AMOUNT, user);
        
        vm.prank(owner);
        wrapper.unpause();
        
        vm.prank(user);
        uint256 shares = wrapper.deposit(DEPOSIT_AMOUNT, user);
        assertGt(shares, 0, "Should work after unpause");
    }
    
    function testConvertToShares() public {
        uint256 assets = 1000e6;
        uint256 shares = wrapper.previewDeposit(assets);
        assertGt(shares, 0, "Shares should be greater than zero");
    }
    
    function testConvertToAssets() public {
        vm.prank(user);
        uint256 shares = wrapper.deposit(DEPOSIT_AMOUNT, user);
        
        uint256 assets = wrapper.previewRedeem(shares);
        assertGt(assets, 0, "Assets should be greater than zero");
    }
}
