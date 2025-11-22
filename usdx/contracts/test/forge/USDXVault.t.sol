// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXVault} from "../../contracts/USDXVault.sol";
import {USDXToken} from "../../contracts/USDXToken.sol";
import {USDXYearnVaultWrapper} from "../../contracts/USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapter} from "../../contracts/USDXShareOFTAdapter.sol";
import {USDXVaultComposerSync} from "../../contracts/USDXVaultComposerSync.sol";
import {MockUSDC} from "../../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../../contracts/mocks/MockYearnVault.sol";
import {MockLayerZeroEndpoint} from "../../contracts/mocks/MockLayerZeroEndpoint.sol";
import {IOVaultComposer} from "../../contracts/interfaces/IOVaultComposer.sol";

contract USDXVaultTest is Test {
    USDXVault public vault;
    USDXToken public usdx;
    MockUSDC public usdc;
    MockYearnVault public yearnVault;
    USDXYearnVaultWrapper public vaultWrapper;
    USDXShareOFTAdapter public shareOFTAdapter;
    USDXVaultComposerSync public composer;
    MockLayerZeroEndpoint public lzEndpoint;
    
    address public admin = address(0x1);
    address public treasury = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    uint32 constant HUB_EID = 30101;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    uint256 constant INITIAL_USDC = 10_000 * 10**6; // 10,000 USDC
    
    function setUp() public {
        // Deploy mocks
        usdc = new MockUSDC();
        yearnVault = new MockYearnVault(address(usdc));
        lzEndpoint = new MockLayerZeroEndpoint(HUB_EID);
        
        // Deploy OVault contracts
        vaultWrapper = new USDXYearnVaultWrapper(
            address(usdc),
            address(yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        
        shareOFTAdapter = new USDXShareOFTAdapter(
            address(vaultWrapper),
            address(lzEndpoint),
            HUB_EID,
            admin
        );
        
        composer = new USDXVaultComposerSync(
            address(vaultWrapper),
            address(shareOFTAdapter),
            address(usdc),
            address(lzEndpoint),
            HUB_EID,
            admin
        );
        
        // Deploy core contracts
        usdx = new USDXToken(admin);
        vault = new USDXVault(
            address(usdc),
            address(usdx),
            treasury,
            admin,
            address(composer),
            address(shareOFTAdapter),
            address(vaultWrapper)
        );
        
        // Grant vault minter and burner roles on USDX
        vm.startPrank(admin);
        usdx.grantRole(MINTER_ROLE, address(vault));
        usdx.grantRole(BURNER_ROLE, address(vault));
        vm.stopPrank();
        
        // Mint USDC to users for testing
        usdc.mint(user1, INITIAL_USDC);
        usdc.mint(user2, INITIAL_USDC);
    }
    
    function testDeployment() public view {
        assertEq(address(vault.usdc()), address(usdc));
        assertEq(address(vault.usdx()), address(usdx));
        assertEq(vault.treasury(), treasury);
        assertEq(vault.yieldDistributionMode(), 0); // Default mode 0
        assertEq(vault.totalCollateral(), 0);
        assertEq(vault.totalMinted(), 0);
    }
    
    function testDeposit() public {
        uint256 depositAmount = 1000 * 10**6; // 1000 USDC
        
        // Approve vault to spend USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        
        // Deposit
        uint256 usdxMinted = vault.deposit(depositAmount);
        vm.stopPrank();
        
        // Verify
        assertEq(usdxMinted, depositAmount, "USDX minted should equal USDC deposited");
        assertEq(usdx.balanceOf(user1), depositAmount, "User should have USDX");
        assertEq(vault.getUserBalance(user1), depositAmount, "Vault should track user deposit");
        assertEq(vault.totalCollateral(), depositAmount, "Total collateral should increase");
        assertEq(vault.totalMinted(), depositAmount, "Total minted should increase");
    }
    
    function testDepositWithOVaultWrapper() public {
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit (should use OVault wrapper)
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        // Verify OVault shares were created
        // Shares are in vaultWrapper (user receives them directly from deposit)
        assertGt(vaultWrapper.balanceOf(user1), 0, "User should have vault wrapper shares");
        // Note: getUserOVaultShares checks adapter first, but shares are in wrapper until locked
        // The vault's userOVaultShares mapping tracks this, but getUserOVaultShares prioritizes adapter
        // So we verify the wrapper directly which is the source of truth
    }
    
    function testDepositWithYearn() public {
        // Set Yearn vault (fallback mode)
        vm.prank(admin);
        vault.setVaultWrapper(address(0)); // Disable wrapper
        vm.prank(admin);
        vault.setYearnVault(address(yearnVault));
        
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        // Verify Yearn shares were received
        assertGt(vault.getUserYearnShares(user1), 0, "User should have Yearn shares");
        assertGt(yearnVault.balanceOf(address(vault)), 0, "Vault should hold Yearn shares");
    }
    
    function testDepositViaOVault() public {
        uint256 depositAmount = 1000 * 10**6;
        bytes32 receiver = bytes32(uint256(uint160(user1)));
        bytes memory options = "";
        
        vm.deal(user1, 1 ether); // Give user ETH for LayerZero fees
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.depositViaOVault{value: 0.001 ether}(
            depositAmount,
            30109, // Polygon EID
            receiver,
            options
        );
        vm.stopPrank();
        
        // Verify deposit
        assertEq(vault.totalCollateral(), depositAmount);
        assertEq(vault.getUserBalance(user1), depositAmount);
    }
    
    function testSetOVaultComposer() public {
        vm.prank(admin);
        vault.setOVaultComposer(address(composer));
        
        assertEq(address(vault.ovaultComposer()), address(composer));
    }
    
    function testSetShareOFTAdapter() public {
        vm.prank(admin);
        vault.setShareOFTAdapter(address(shareOFTAdapter));
        
        assertEq(address(vault.shareOFTAdapter()), address(shareOFTAdapter));
    }
    
    function testSetVaultWrapper() public {
        vm.prank(admin);
        vault.setVaultWrapper(address(vaultWrapper));
        
        assertEq(address(vault.vaultWrapper()), address(vaultWrapper));
    }
    
    function testGetUserOVaultShares() public {
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        uint256 shares = vault.getUserOVaultShares(user1);
        assertGt(shares, 0, "User should have OVault shares");
    }
    
    function testGetTotalValueWithOVault() public {
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        uint256 totalValue = vault.getTotalValue();
        assertGt(totalValue, 0, "Total value should be greater than zero");
    }
    
    function testDepositRevertsIfZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(USDXVault.ZeroAmount.selector);
        vault.deposit(0);
    }
    
    function testDepositRevertsIfInsufficientAllowance() public {
        vm.prank(user1);
        vm.expectRevert();
        vault.deposit(1000 * 10**6);
    }
    
    function testWithdraw() public {
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit first
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        
        // Approve vault to burn USDX
        usdx.approve(address(vault), depositAmount);
        
        // Withdraw half
        uint256 withdrawAmount = depositAmount / 2;
        uint256 usdcReturned = vault.withdraw(withdrawAmount);
        vm.stopPrank();
        
        // Verify
        assertEq(usdcReturned, withdrawAmount, "Should return 1:1 USDC");
        assertEq(usdc.balanceOf(user1), INITIAL_USDC - depositAmount + withdrawAmount, "User should have USDC");
        assertEq(usdx.balanceOf(user1), depositAmount - withdrawAmount, "User USDX should decrease");
        assertEq(vault.getUserBalance(user1), depositAmount - withdrawAmount, "Vault tracking should update");
    }
    
    function testWithdrawWithYearn() public {
        // Set Yearn vault
        vm.prank(admin);
        vault.setYearnVault(address(yearnVault));
        
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        
        // Withdraw
        usdx.approve(address(vault), depositAmount);
        vault.withdraw(depositAmount);
        vm.stopPrank();
        
        // Verify all Yearn shares were redeemed
        assertEq(vault.getUserYearnShares(user1), 0, "All Yearn shares should be redeemed");
        assertEq(usdc.balanceOf(user1), INITIAL_USDC, "User should have all USDC back");
    }
    
    function testWithdrawRevertsIfInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert(USDXVault.InsufficientBalance.selector);
        vault.withdraw(1000 * 10**6);
    }
    
    function testYieldDistributionMode0_Treasury() public {
        // Set Yearn vault
        vm.prank(admin);
        vault.setYearnVault(address(yearnVault));
        
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        // Simulate yield (10% increase)
        yearnVault.accrueYield(10);
        
        // Harvest yield
        vm.prank(admin);
        vault.harvestYield();
        
        // Verify yield went to treasury
        assertGt(usdc.balanceOf(treasury), 0, "Treasury should receive yield");
        assertEq(vault.totalYieldAccumulated(), depositAmount / 10, "Yield should be tracked");
    }
    
    function testYieldDistributionMode1_Users() public {
        // Set mode to users (rebasing)
        vm.prank(admin);
        vault.setYieldDistributionMode(1);
        
        // Set Yearn vault
        vm.prank(admin);
        vault.setYearnVault(address(yearnVault));
        
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        // Simulate yield
        yearnVault.accrueYield(10);
        
        // Get value before harvest
        uint256 valueBefore = vault.getTotalValue();
        
        // Harvest yield (mode 1 keeps it in vault)
        vm.prank(admin);
        vault.harvestYield();
        
        // Value should stay higher (yield remains in vault for users)
        assertGt(vault.getTotalValue(), depositAmount, "Value should include yield");
    }
    
    function testYieldDistributionMode2_Buyback() public {
        // Set mode to buyback
        vm.prank(admin);
        vault.setYieldDistributionMode(2);
        
        // Set Yearn vault  
        vm.prank(admin);
        vault.setYearnVault(address(yearnVault));
        
        uint256 depositAmount = 1000 * 10**6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        // Simulate yield
        yearnVault.accrueYield(10);
        
        // Harvest yield (simplified for MVP - goes to treasury)
        vm.prank(admin);
        vault.harvestYield();
        
        // Verify yield was harvested
        assertGt(vault.totalYieldAccumulated(), 0, "Yield should be tracked");
    }
    
    function testSetYieldDistributionMode() public {
        // Set to mode 1
        vm.prank(admin);
        vault.setYieldDistributionMode(1);
        assertEq(vault.yieldDistributionMode(), 1);
        
        // Set to mode 2
        vm.prank(admin);
        vault.setYieldDistributionMode(2);
        assertEq(vault.yieldDistributionMode(), 2);
        
        // Back to mode 0
        vm.prank(admin);
        vault.setYieldDistributionMode(0);
        assertEq(vault.yieldDistributionMode(), 0);
    }
    
    function testSetYieldDistributionModeRevertsIfInvalid() public {
        vm.prank(admin);
        vm.expectRevert(USDXVault.InvalidYieldMode.selector);
        vault.setYieldDistributionMode(3);
    }
    
    function testSetYieldDistributionModeRevertsIfNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        vault.setYieldDistributionMode(1);
    }
    
    function testGetCollateralRatio() public {
        // Should return 1:1 ratio (1e18 precision)
        uint256 ratio = vault.getCollateralRatio();
        assertEq(ratio, 1e18, "Empty vault should have 1:1 ratio");
        
        // After deposit, should still be 1:1
        vm.startPrank(user1);
        usdc.approve(address(vault), 1000 * 10**6);
        vault.deposit(1000 * 10**6);
        vm.stopPrank();
        
        ratio = vault.getCollateralRatio();
        assertEq(ratio, 1e18, "Vault should maintain 1:1 ratio");
    }
    
    function testPauseAndUnpause() public {
        uint256 depositAmount = 1000 * 10**6;
        
        // Pause vault
        vm.prank(admin);
        vault.pause();
        
        // Deposit should revert when paused
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        vm.expectRevert();
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        // Unpause
        vm.prank(admin);
        vault.unpause();
        
        // Should work after unpause
        vm.startPrank(user1);
        vault.deposit(depositAmount);
        vm.stopPrank();
        
        assertEq(usdx.balanceOf(user1), depositAmount);
    }
    
    function testFuzzDeposit(uint256 amount) public {
        // Bound amount to reasonable values
        amount = bound(amount, 1, 1_000_000 * 10**6); // 1 to 1M USDC
        
        // Mint USDC to user
        usdc.mint(user1, amount);
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(vault), amount);
        uint256 usdxMinted = vault.deposit(amount);
        vm.stopPrank();
        
        assertEq(usdxMinted, amount);
        assertEq(usdx.balanceOf(user1), amount);
        assertEq(vault.totalCollateral(), amount);
    }
    
    function testMultipleUserDeposits() public {
        uint256 amount1 = 1000 * 10**6;
        uint256 amount2 = 2000 * 10**6;
        
        // User1 deposits
        vm.startPrank(user1);
        usdc.approve(address(vault), amount1);
        vault.deposit(amount1);
        vm.stopPrank();
        
        // User2 deposits
        vm.startPrank(user2);
        usdc.approve(address(vault), amount2);
        vault.deposit(amount2);
        vm.stopPrank();
        
        // Verify
        assertEq(vault.getUserBalance(user1), amount1);
        assertEq(vault.getUserBalance(user2), amount2);
        assertEq(vault.totalCollateral(), amount1 + amount2);
        assertEq(vault.totalMinted(), amount1 + amount2);
    }
    
    function testDepositViaOVaultRevertsIfNoComposer() public {
        // Remove composer
        vm.prank(admin);
        vault.setOVaultComposer(address(0));
        
        vm.prank(user1);
        usdc.approve(address(vault), 1000 * 10**6);
        vm.expectRevert(USDXVault.ZeroAddress.selector);
        vault.depositViaOVault(
            1000 * 10**6,
            30109,
            bytes32(uint256(uint160(user1))),
            ""
        );
    }
}
