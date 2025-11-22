// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../contracts/core/USDXToken.sol";
import "../../contracts/core/USDXVault.sol";
import "../../contracts/core/MockUSDC.sol";
import "../../contracts/core/MockYieldVault.sol";
import "../../contracts/core/USDXSpokeMinter.sol";
import "../../contracts/core/CrossChainBridge.sol";

contract E2EIntegrationTest is Test {
    USDXToken public usdxToken;
    USDXVault public usdxVault;
    MockUSDC public mockUSDC;
    MockYieldVault public mockYieldVault;
    USDXSpokeMinter public spokeMinter;
    CrossChainBridge public bridge;

    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public relayer = address(0x4);

    uint256 public constant HUB_CHAIN_ID = 1;
    uint256 public constant SPOKE_CHAIN_ID = 137;
    uint256 public constant INITIAL_USDC_AMOUNT = 10000 * 10**6; // 10,000 USDC
    uint256 public constant DEPOSIT_AMOUNT = 1000 * 10**6; // 1,000 USDC
    uint256 public constant WITHDRAW_AMOUNT = 500 * 10**18; // 500 USDX

    function setUp() public {
        // Set up admin
        vm.startPrank(admin);

        // 1. Deploy MockUSDC
        mockUSDC = new MockUSDC();

        // 2. Deploy USDXToken
        usdxToken = new USDXToken(admin);

        // 3. Deploy MockYieldVault
        mockYieldVault = new MockYieldVault(address(mockUSDC));

        // 4. Deploy USDXVault
        usdxVault = new USDXVault(
            address(mockUSDC),
            address(usdxToken),
            address(mockYieldVault)
        );

        // Grant VAULT_ROLE to vault
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(usdxVault));

        // 5. Deploy USDXSpokeMinter
        spokeMinter = new USDXSpokeMinter(
            address(usdxToken),
            address(usdxVault),
            HUB_CHAIN_ID
        );

        // Grant RELAYER_ROLE to relayer
        spokeMinter.grantRole(spokeMinter.RELAYER_ROLE(), relayer);

        // 6. Deploy CrossChainBridge
        bridge = new CrossChainBridge(address(usdxToken), HUB_CHAIN_ID);

        // Grant RELAYER_ROLE to relayer
        bridge.grantRole(bridge.RELAYER_ROLE(), relayer);

        // Grant BRIDGE_ROLE to bridge
        usdxToken.grantRole(usdxToken.BRIDGE_ROLE(), address(bridge));

        // Set supported chains
        bridge.setSupportedChain(SPOKE_CHAIN_ID, true);

        vm.stopPrank();

        // Mint USDC to users
        mockUSDC.mint(user1, INITIAL_USDC_AMOUNT);
        mockUSDC.mint(user2, INITIAL_USDC_AMOUNT);
    }

    function testCompleteDepositFlow() public {
        // Approve USDC
        vm.startPrank(user1);
        mockUSDC.approve(address(usdxVault), DEPOSIT_AMOUNT);

        // Get initial balances
        uint256 initialUSDCBalance = mockUSDC.balanceOf(user1);
        uint256 initialUSDXBalance = usdxToken.balanceOf(user1);
        uint256 initialVaultCollateral = usdxVault.totalCollateral();

        // Deposit
        usdxVault.depositUSDC(DEPOSIT_AMOUNT);
        vm.stopPrank();

        // Verify balances
        uint256 finalUSDCBalance = mockUSDC.balanceOf(user1);
        uint256 finalUSDXBalance = usdxToken.balanceOf(user1);
        uint256 finalVaultCollateral = usdxVault.totalCollateral();

        assertEq(finalUSDCBalance, initialUSDCBalance - DEPOSIT_AMOUNT, "USDC balance incorrect");
        assertEq(finalUSDXBalance, initialUSDXBalance + DEPOSIT_AMOUNT, "USDX balance incorrect");
        assertEq(finalVaultCollateral, initialVaultCollateral + DEPOSIT_AMOUNT, "Vault collateral incorrect");
    }

    function testYieldAccrual() public {
        // Deposit first
        vm.startPrank(user1);
        mockUSDC.approve(address(usdxVault), DEPOSIT_AMOUNT);
        usdxVault.depositUSDC(DEPOSIT_AMOUNT);
        vm.stopPrank();

        // Get initial yield position (separate call to avoid reentrancy detection)
        (uint256 initialShares, uint256 initialAssets) = usdxVault.getUserYieldPosition(user1);

        // Fast forward time (30 days)
        vm.warp(block.timestamp + 30 days);

        // Get yield position after time passes
        (uint256 finalShares, uint256 finalAssets) = usdxVault.getUserYieldPosition(user1);

        // Shares should remain the same
        assertEq(finalShares, initialShares, "Shares should not change");

        // Assets should increase due to yield
        assertGt(finalAssets, initialAssets, "Assets should increase with yield");
    }

    function testCompleteWithdrawalFlow() public {
        // Deposit first
        vm.startPrank(user1);
        mockUSDC.approve(address(usdxVault), DEPOSIT_AMOUNT);
        usdxVault.depositUSDC(DEPOSIT_AMOUNT);
        vm.stopPrank();

        // Get initial balances (separate call)
        uint256 initialUSDCBalance = mockUSDC.balanceOf(user1);
        uint256 initialUSDXBalance = usdxToken.balanceOf(user1);

        // Withdraw
        vm.prank(user1);
        usdxVault.withdrawUSDC(WITHDRAW_AMOUNT);

        // Verify balances
        uint256 finalUSDCBalance = mockUSDC.balanceOf(user1);
        uint256 finalUSDXBalance = usdxToken.balanceOf(user1);

        // USDX should be burned
        assertEq(finalUSDXBalance, initialUSDXBalance - WITHDRAW_AMOUNT, "USDX should be burned");

        // USDC should be returned (may include yield)
        assertGe(finalUSDCBalance, initialUSDCBalance, "USDC should be returned");
    }

    function testSpokeMinterFlow() public {
        // User deposits on hub chain first
        uint256 depositAmount = 2000 * 10**6;
        vm.startPrank(user2);
        mockUSDC.approve(address(usdxVault), depositAmount);
        usdxVault.depositUSDC(depositAmount);
        vm.stopPrank();

        // Get user's hub position
        uint256 hubPosition = usdxVault.getUserCollateral(user2);

        // Mint USDX on spoke chain via relayer
        uint256 mintAmount = 1000 * 10**18;
        bytes32 mintId = keccak256("test-mint-1");

        uint256 initialSpokeBalance = usdxToken.balanceOf(user2);

        vm.prank(relayer);
        spokeMinter.mintFromHubPosition(user2, mintAmount, hubPosition, mintId);

        // Verify USDX was minted on spoke chain
        uint256 finalSpokeBalance = usdxToken.balanceOf(user2);
        assertEq(finalSpokeBalance, initialSpokeBalance + mintAmount, "USDX should be minted");
    }

    function testCrossChainBridgeFlow() public {
        // Mint USDX to user1 for testing via vault
        vm.prank(user1);
        mockUSDC.approve(address(usdxVault), 100 * 10**6);
        vm.prank(user1);
        usdxVault.depositUSDC(100 * 10**6);

        uint256 transferAmount = 50 * 10**18;

        // Approve bridge
        vm.prank(user1);
        usdxToken.approve(address(bridge), transferAmount);

        // Get initial balance
        uint256 initialBalance = usdxToken.balanceOf(user1);

        // Initiate cross-chain transfer
        vm.prank(user1);
        bridge.transferCrossChain(transferAmount, SPOKE_CHAIN_ID, user2);

        // Verify USDX was burned
        uint256 finalBalance = usdxToken.balanceOf(user1);
        assertEq(finalBalance, initialBalance - transferAmount, "USDX should be burned");

        // Complete transfer via relayer
        bytes32 transferId = keccak256(abi.encodePacked(
            HUB_CHAIN_ID,
            SPOKE_CHAIN_ID,
            user1,
            user2,
            transferAmount,
            bridge.transferNonce() - 1,
            block.timestamp
        ));

        uint256 initialDestBalance = usdxToken.balanceOf(user2);

        vm.prank(relayer);
        bridge.completeTransfer(transferId, HUB_CHAIN_ID, user1, transferAmount, user2);

        // Verify USDX was minted on destination chain
        uint256 finalDestBalance = usdxToken.balanceOf(user2);
        assertEq(finalDestBalance, initialDestBalance + transferAmount, "USDX should be minted");
    }

    function testCompleteE2EFlow() public {
        uint256 depositAmount = 5000 * 10**6;
        uint256 spokeMintAmount = 2000 * 10**18;
        uint256 bridgeAmount = 1000 * 10**18;
        uint256 withdrawAmount = 1500 * 10**18;

        // Step 1: Deposit USDC on hub chain
        vm.startPrank(user2);
        mockUSDC.approve(address(usdxVault), depositAmount);
        usdxVault.depositUSDC(depositAmount);
        vm.stopPrank();

        // Verify deposit
        uint256 hubPosition = usdxVault.getUserCollateral(user2);
        assertEq(hubPosition, depositAmount, "Hub position should match deposit");

        // Step 2: Accrue yield (fast forward time)
        vm.warp(block.timestamp + 60 days);

        // Step 3: Mint USDX on spoke chain using hub position
        bytes32 mintId = keccak256("e2e-mint-1");
        vm.prank(relayer);
        spokeMinter.mintFromHubPosition(user2, spokeMintAmount, hubPosition, mintId);

        // Verify spoke mint
        uint256 spokeBalance = usdxToken.balanceOf(user2);
        assertEq(spokeBalance, spokeMintAmount, "Spoke balance should match mint amount");

        // Step 4: Transfer USDX cross-chain
        vm.prank(user2);
        usdxToken.approve(address(bridge), bridgeAmount);
        vm.prank(user2);
        bridge.transferCrossChain(bridgeAmount, SPOKE_CHAIN_ID, user2);

        // Verify USDX burned
        uint256 balanceAfterBridge = usdxToken.balanceOf(user2);
        assertEq(balanceAfterBridge, spokeMintAmount - bridgeAmount, "USDX should be burned");

        // Step 5: Complete bridge transfer
        bytes32 bridgeTransferId = keccak256(abi.encodePacked(
            HUB_CHAIN_ID,
            SPOKE_CHAIN_ID,
            user2,
            user2,
            bridgeAmount,
            bridge.transferNonce() - 1,
            block.timestamp
        ));

        vm.prank(relayer);
        bridge.completeTransfer(bridgeTransferId, HUB_CHAIN_ID, user2, bridgeAmount, user2);

        // Verify USDX minted on destination chain
        uint256 finalSpokeBalance = usdxToken.balanceOf(user2);
        assertEq(finalSpokeBalance, spokeMintAmount, "USDX should be minted back");

        // Step 6: Withdraw USDC from hub chain
        vm.prank(user2);
        usdxVault.withdrawUSDC(withdrawAmount);

        // Verify withdrawal
        uint256 finalHubPosition = usdxVault.getUserCollateral(user2);
        assertLt(finalHubPosition, hubPosition, "Hub position should decrease");
    }

    function testMultipleUsers() public {
        uint256 user1Deposit = 1000 * 10**6;
        uint256 user2Deposit = 2000 * 10**6;

        // Both users deposit
        vm.startPrank(user1);
        mockUSDC.approve(address(usdxVault), user1Deposit);
        usdxVault.depositUSDC(user1Deposit);
        vm.stopPrank();

        vm.startPrank(user2);
        mockUSDC.approve(address(usdxVault), user2Deposit);
        usdxVault.depositUSDC(user2Deposit);
        vm.stopPrank();

        // Verify both positions tracked correctly
        uint256 user1Position = usdxVault.getUserCollateral(user1);
        uint256 user2Position = usdxVault.getUserCollateral(user2);

        assertEq(user1Position, user1Deposit, "User1 position incorrect");
        assertEq(user2Position, user2Deposit, "User2 position incorrect");

        // Verify total collateral
        uint256 totalCollateral = usdxVault.getTotalCollateral();
        assertEq(totalCollateral, user1Deposit + user2Deposit, "Total collateral incorrect");
    }

    function testPreventDoubleMinting() public {
        uint256 depositAmount = 2000 * 10**6;
        vm.startPrank(user2);
        mockUSDC.approve(address(usdxVault), depositAmount);
        usdxVault.depositUSDC(depositAmount);
        vm.stopPrank();

        uint256 hubPosition = usdxVault.getUserCollateral(user2);
        uint256 mintAmount = 1000 * 10**18;
        bytes32 mintId = keccak256("duplicate-mint");

        // First mint should succeed
        vm.prank(relayer);
        spokeMinter.mintFromHubPosition(user2, mintAmount, hubPosition, mintId);

        // Second mint with same ID should fail
        vm.prank(relayer);
        vm.expectRevert("USDXSpokeMinter: mint already processed");
        spokeMinter.mintFromHubPosition(user2, mintAmount, hubPosition, mintId);
    }

    function testPreventDuplicateTransfer() public {
        // Mint USDX via vault deposit
        vm.prank(user1);
        mockUSDC.approve(address(usdxVault), 100 * 10**6);
        vm.prank(user1);
        usdxVault.depositUSDC(100 * 10**6);

        uint256 transferAmount = 50 * 10**18;
        vm.prank(user1);
        usdxToken.approve(address(bridge), transferAmount);
        vm.prank(user1);
        bridge.transferCrossChain(transferAmount, SPOKE_CHAIN_ID, user2);

        bytes32 transferId = keccak256(abi.encodePacked(
            HUB_CHAIN_ID,
            SPOKE_CHAIN_ID,
            user1,
            user2,
            transferAmount,
            bridge.transferNonce() - 1,
            block.timestamp
        ));

        // Complete once
        vm.prank(relayer);
        bridge.completeTransfer(transferId, HUB_CHAIN_ID, user1, transferAmount, user2);

        // Try to complete again - should fail
        vm.prank(relayer);
        vm.expectRevert("CrossChainBridge: transfer already processed");
        bridge.completeTransfer(transferId, HUB_CHAIN_ID, user1, transferAmount, user2);
    }
}
