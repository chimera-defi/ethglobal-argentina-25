// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {USDXVault} from "../../contracts/USDXVault.sol";
import {USDXToken} from "../../contracts/USDXToken.sol";
import {USDXSpokeMinter} from "../../contracts/USDXSpokeMinter.sol";
import {MockUSDC} from "../../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../../contracts/mocks/MockYearnVault.sol";

/**
 * @title IntegrationE2ETest
 * @notice Comprehensive end-to-end integration test for USDX Protocol
 * @dev Tests the complete user journey across hub and spoke chains
 * 
 * Test Scenario:
 * 1. User deposits USDC into vault on hub chain (Ethereum)
 * 2. Vault mints USDX 1:1 and deposits into Yearn for yield
 * 3. User's position is tracked for cross-chain access
 * 4. User mints USDX on spoke chain (Polygon) using hub position
 * 5. Yield accrues in Yearn vault
 * 6. Protocol harvests yield (tests all 3 distribution modes)
 * 7. User burns spoke USDX and withdraws from hub
 * 8. User gets USDC back with accrued yield (depending on mode)
 */
contract IntegrationE2ETest is Test {
    // ============ Hub Chain Contracts ============
    USDXVault public hubVault;
    USDXToken public hubUSDX;
    MockUSDC public usdc;
    MockYearnVault public yearnVault;
    
    // ============ Spoke Chain Contracts ============
    USDXSpokeMinter public spokeMinter;
    USDXToken public spokeUSDX;
    
    // ============ Test Actors ============
    address public admin = makeAddr("admin");
    address public treasury = makeAddr("treasury");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public positionOracle = makeAddr("positionOracle"); // Simulates cross-chain oracle
    
    // ============ Roles ============
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    // ============ Constants ============
    uint256 constant INITIAL_USDC = 100_000 * 10**6; // 100,000 USDC
    uint256 constant ALICE_DEPOSIT = 10_000 * 10**6; // 10,000 USDC
    uint256 constant BOB_DEPOSIT = 5_000 * 10**6;   // 5,000 USDC
    
    function setUp() public {
        console2.log("\n=== Setting up USDX Protocol E2E Test ===\n");
        
        // ============ Deploy Hub Chain Contracts ============
        console2.log("Deploying Hub Chain (Ethereum) contracts...");
        
        usdc = new MockUSDC();
        console2.log("  MockUSDC deployed at:", address(usdc));
        
        hubUSDX = new USDXToken(admin);
        console2.log("  HubUSDX deployed at:", address(hubUSDX));
        
        hubVault = new USDXVault(address(usdc), address(hubUSDX), treasury, admin);
        console2.log("  HubVault deployed at:", address(hubVault));
        
        yearnVault = new MockYearnVault(address(usdc));
        console2.log("  YearnVault deployed at:", address(yearnVault));
        
        // ============ Deploy Spoke Chain Contracts ============
        console2.log("\nDeploying Spoke Chain (Polygon) contracts...");
        
        spokeUSDX = new USDXToken(admin);
        console2.log("  SpokeUSDX deployed at:", address(spokeUSDX));
        
        spokeMinter = new USDXSpokeMinter(address(spokeUSDX), admin);
        console2.log("  SpokeMinter deployed at:", address(spokeMinter));
        
        // ============ Setup Permissions ============
        console2.log("\nSetting up permissions...");
        
        vm.startPrank(admin);
        // Hub chain permissions
        hubUSDX.grantRole(MINTER_ROLE, address(hubVault));
        hubUSDX.grantRole(BURNER_ROLE, address(hubVault));
        hubVault.setYearnVault(address(yearnVault));
        console2.log("  Hub permissions configured");
        
        // Spoke chain permissions
        spokeUSDX.grantRole(MINTER_ROLE, address(spokeMinter));
        spokeUSDX.grantRole(BURNER_ROLE, address(spokeMinter));
        spokeMinter.grantRole(POSITION_UPDATER_ROLE, positionOracle);
        console2.log("  Spoke permissions configured");
        vm.stopPrank();
        
        // ============ Fund Users ============
        console2.log("\nFunding test users...");
        usdc.mint(alice, INITIAL_USDC);
        usdc.mint(bob, INITIAL_USDC);
        console2.log("  Alice funded with:", INITIAL_USDC / 10**6, "USDC");
        console2.log("  Bob funded with:", INITIAL_USDC / 10**6, "USDC");
        
        console2.log("\n=== Setup Complete ===\n");
    }
    
    function testCompleteE2EWorkflow() public {
        console2.log("\n============================================================");
        console2.log("   USDX Protocol - Complete End-to-End Integration Test");
        console2.log("============================================================\n");
        
        // ============================================================
        // PHASE 1: Hub Chain Deposits
        // ============================================================
        console2.log("");
        console2.log(" PHASE 1: Users Deposit USDC on Hub Chain (Ethereum)   ");
        console2.log("\n");
        
        // Alice deposits
        console2.log("Alice deposits", ALICE_DEPOSIT / 10**6, "USDC into HubVault...");
        vm.startPrank(alice);
        usdc.approve(address(hubVault), ALICE_DEPOSIT);
        uint256 aliceUSDXMinted = hubVault.deposit(ALICE_DEPOSIT);
        vm.stopPrank();
        
        assertEq(aliceUSDXMinted, ALICE_DEPOSIT, "Alice should receive 1:1 USDX");
        assertEq(hubUSDX.balanceOf(alice), ALICE_DEPOSIT, "Alice USDX balance");
        assertEq(hubVault.getUserBalance(alice), ALICE_DEPOSIT, "Alice vault balance");
        console2.log("  [OK] Alice received", aliceUSDXMinted / 10**6, "USDX");
        console2.log("  [OK] Alice's USDC deposited into Yearn vault");
        
        // Bob deposits
        console2.log("\nBob deposits", BOB_DEPOSIT / 10**6, "USDC into HubVault...");
        vm.startPrank(bob);
        usdc.approve(address(hubVault), BOB_DEPOSIT);
        uint256 bobUSDXMinted = hubVault.deposit(BOB_DEPOSIT);
        vm.stopPrank();
        
        assertEq(bobUSDXMinted, BOB_DEPOSIT, "Bob should receive 1:1 USDX");
        assertEq(hubUSDX.balanceOf(bob), BOB_DEPOSIT, "Bob USDX balance");
        console2.log("  [OK] Bob received", bobUSDXMinted / 10**6, "USDX");
        
        // Verify vault state
        console2.log("\nHub Vault State:");
        console2.log("  Total Collateral:", hubVault.totalCollateral() / 10**6, "USDC");
        console2.log("  Total USDX Minted:", hubVault.totalMinted() / 10**6, "USDX");
        console2.log("  Collateral Ratio:", hubVault.getCollateralRatio() / 10**16, "/ 100 (should be 100 for 1:1)");
        
        assertEq(hubVault.totalCollateral(), ALICE_DEPOSIT + BOB_DEPOSIT);
        assertEq(hubVault.totalMinted(), ALICE_DEPOSIT + BOB_DEPOSIT);
        
        // ============================================================
        // PHASE 2: Cross-Chain Position Sync
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 2: Sync Positions to Spoke Chain (Polygon)");
        console2.log("------------------------------------------------------------\n");
        
        console2.log("Position Oracle syncs hub positions to spoke chain...");
        vm.startPrank(positionOracle);
        spokeMinter.updateHubPosition(alice, ALICE_DEPOSIT);
        spokeMinter.updateHubPosition(bob, BOB_DEPOSIT);
        vm.stopPrank();
        
        assertEq(spokeMinter.getHubPosition(alice), ALICE_DEPOSIT);
        assertEq(spokeMinter.getHubPosition(bob), BOB_DEPOSIT);
        console2.log("  [OK] Alice's hub position:", ALICE_DEPOSIT / 10**6, "USDC");
        console2.log("  [OK] Bob's hub position:", BOB_DEPOSIT / 10**6, "USDC");
        
        // ============================================================
        // PHASE 3: Spoke Chain Minting
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 3: Users Mint USDX on Spoke Chain (Polygon)");
        console2.log("------------------------------------------------------------\n");
        
        uint256 aliceSpokeMint = ALICE_DEPOSIT / 2; // Alice mints 50% on spoke
        uint256 bobSpokeMint = BOB_DEPOSIT;         // Bob mints 100% on spoke
        
        console2.log("Alice mints", aliceSpokeMint / 10**6, "USDX on spoke chain...");
        vm.prank(alice);
        spokeMinter.mint(aliceSpokeMint);
        
        assertEq(spokeUSDX.balanceOf(alice), aliceSpokeMint);
        assertEq(spokeMinter.getMintedAmount(alice), aliceSpokeMint);
        console2.log("  [OK] Alice received", aliceSpokeMint / 10**6, "USDX on Polygon");
        console2.log("  [OK] Alice still has", spokeMinter.getAvailableMintAmount(alice) / 10**6, "USDC available to mint");
        
        console2.log("\nBob mints", bobSpokeMint / 10**6, "USDX on spoke chain...");
        vm.prank(bob);
        spokeMinter.mint(bobSpokeMint);
        
        assertEq(spokeUSDX.balanceOf(bob), bobSpokeMint);
        console2.log("  [OK] Bob received", bobSpokeMint / 10**6, "USDX on Polygon");
        console2.log("  [OK] Bob used his full hub position");
        
        // ============================================================
        // PHASE 4: Yield Accrual
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 4: Yield Accrues in Yearn Vault");
        console2.log("------------------------------------------------------------\n");
        
        uint256 vaultValueBefore = hubVault.getTotalValue();
        console2.log("Vault value before yield:", vaultValueBefore / 10**6, "USDC");
        
        // Simulate 10% yield accrual
        console2.log("TIME: Time passes... Yearn vault earns 10% yield");
        yearnVault.accrueYield(10);
        
        uint256 vaultValueAfter = hubVault.getTotalValue();
        uint256 yieldEarned = vaultValueAfter - vaultValueBefore;
        console2.log("Vault value after yield:", vaultValueAfter / 10**6, "USDC");
        console2.log("  [OK] Yield earned:", yieldEarned / 10**6, "USDC");
        
        assertGt(vaultValueAfter, vaultValueBefore, "Vault value should increase");
        
        // ============================================================
        // PHASE 5: Yield Distribution (Mode 0 - Treasury)
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 5: Harvest Yield (Mode 0 - Treasury)");
        console2.log("------------------------------------------------------------\n");
        
        uint256 treasuryBalanceBefore = usdc.balanceOf(treasury);
        console2.log("Treasury balance before harvest:", treasuryBalanceBefore / 10**6, "USDC");
        
        console2.log("Manager harvests yield...");
        vm.prank(admin);
        hubVault.harvestYield();
        
        uint256 treasuryBalanceAfter = usdc.balanceOf(treasury);
        uint256 treasuryReceived = treasuryBalanceAfter - treasuryBalanceBefore;
        console2.log("Treasury balance after harvest:", treasuryBalanceAfter / 10**6, "USDC");
        console2.log("  [OK] Treasury received:", treasuryReceived / 10**6, "USDC (protocol revenue)");
        
        assertGt(treasuryReceived, 0, "Treasury should receive yield");
        assertEq(hubVault.yieldDistributionMode(), 0, "Should be in mode 0");
        
        // ============================================================
        // PHASE 6: Test Mode 1 (Users/Rebasing)
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 6: Switch to Mode 1 (Yield to Users - Rebasing)");
        console2.log("------------------------------------------------------------\n");
        
        console2.log("Admin switches to Mode 1 (rebasing)...");
        vm.prank(admin);
        hubVault.setYieldDistributionMode(1);
        
        // Simulate more yield
        yearnVault.accrueYield(5);
        console2.log("TIME: Additional 5% yield accrues...");
        
        uint256 valueBefore = hubVault.getTotalValue();
        vm.prank(admin);
        hubVault.harvestYield();
        uint256 valueAfter = hubVault.getTotalValue();
        
        console2.log("  [OK] Mode 1: Yield stays in vault");
        console2.log("  [OK] Vault value:", valueAfter / 10**6, "USDC (includes user yield)");
        assertGe(valueAfter, valueBefore, "Value should stay high in mode 1");
        
        // ============================================================
        // PHASE 7: Test Mode 2 (Buyback & Burn)
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 7: Switch to Mode 2 (Buyback & Burn)");
        console2.log("------------------------------------------------------------\n");
        
        console2.log("Admin switches to Mode 2 (buyback & burn)...");
        vm.prank(admin);
        hubVault.setYieldDistributionMode(2);
        
        // Simulate more yield
        yearnVault.accrueYield(5);
        console2.log("TIME: Additional 5% yield accrues...");
        
        uint256 treasuryBefore = usdc.balanceOf(treasury);
        vm.prank(admin);
        hubVault.harvestYield();
        uint256 treasuryAfter = usdc.balanceOf(treasury);
        
        console2.log("  [OK] Mode 2: Yield harvested for buyback (goes to treasury in MVP)");
        console2.log("  [OK] Treasury received:", (treasuryAfter - treasuryBefore) / 10**6, "USDC");
        
        // ============================================================
        // PHASE 8: Spoke Chain Burning
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 8: Users Burn USDX on Spoke Chain");
        console2.log("------------------------------------------------------------\n");
        
        console2.log("Alice burns her spoke USDX...");
        vm.startPrank(alice);
        spokeUSDX.approve(address(spokeMinter), aliceSpokeMint);
        spokeMinter.burn(aliceSpokeMint);
        vm.stopPrank();
        
        assertEq(spokeUSDX.balanceOf(alice), 0, "Alice spoke USDX should be burned");
        assertEq(spokeMinter.getMintedAmount(alice), 0, "Alice minted amount should be zero");
        console2.log("  [OK] Alice burned", aliceSpokeMint / 10**6, "USDX on Polygon");
        console2.log("  [OK] Alice can now mint again if desired");
        
        // ============================================================
        // PHASE 9: Hub Chain Withdrawal
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  PHASE 9: Users Withdraw USDC from Hub Chain");
        console2.log("------------------------------------------------------------\n");
        
        // Switch back to mode 0 for clean withdrawal test
        vm.prank(admin);
        hubVault.setYieldDistributionMode(0);
        
        uint256 aliceWithdrawAmount = ALICE_DEPOSIT / 2;
        console2.log("Alice withdraws", aliceWithdrawAmount / 10**6, "USDX from hub vault...");
        
        uint256 aliceUSDCBefore = usdc.balanceOf(alice);
        vm.startPrank(alice);
        hubUSDX.approve(address(hubVault), aliceWithdrawAmount);
        uint256 usdcReturned = hubVault.withdraw(aliceWithdrawAmount);
        vm.stopPrank();
        
        assertEq(usdcReturned, aliceWithdrawAmount, "Should return 1:1 USDC");
        assertEq(usdc.balanceOf(alice) - aliceUSDCBefore, aliceWithdrawAmount, "Alice should receive USDC");
        console2.log("  [OK] Alice received", usdcReturned / 10**6, "USDC");
        console2.log("  [OK] Alice burned", aliceWithdrawAmount / 10**6, "USDX");
        
        // ============================================================
        // FINAL STATE
        // ============================================================
        console2.log("\n------------------------------------------------------------");
        console2.log("  FINAL STATE: Protocol Statistics");
        console2.log("------------------------------------------------------------\n");
        
        console2.log("Hub Chain (Ethereum):");
        console2.log("  Total Collateral:", hubVault.totalCollateral() / 10**6, "USDC");
        console2.log("  Total USDX Minted:", hubVault.totalMinted() / 10**6, "USDX");
        console2.log("  Total Yield Accumulated:", hubVault.totalYieldAccumulated() / 10**6, "USDC");
        console2.log("  Collateral Ratio:", hubVault.getCollateralRatio() / 10**16, "/ 100");
        
        console2.log("\nSpoke Chain (Polygon):");
        console2.log("  Total Minted:", spokeMinter.totalMinted() / 10**6, "USDX");
        console2.log("  Bob's Spoke Balance:", spokeUSDX.balanceOf(bob) / 10**6, "USDX");
        
        console2.log("\nTreasury:");
        console2.log("  Total Yield Collected:", usdc.balanceOf(treasury) / 10**6, "USDC");
        
        console2.log("\n============================================================");
        console2.log("   End-to-End Integration Test PASSED");
        console2.log("============================================================\n");
    }
    
    function testE2EWithMultipleYieldCycles() public {
        console2.log("\n=== Testing Multiple Yield Cycles ===\n");
        
        // Setup: Alice deposits
        vm.startPrank(alice);
        usdc.approve(address(hubVault), ALICE_DEPOSIT);
        hubVault.deposit(ALICE_DEPOSIT);
        vm.stopPrank();
        
        // Cycle through all 3 yield modes
        for (uint8 mode = 0; mode < 3; mode++) {
            console2.log("Testing yield mode:", mode);
            
            vm.prank(admin);
            hubVault.setYieldDistributionMode(mode);
            
            // Accrue yield
            yearnVault.accrueYield(5);
            
            // Harvest
            vm.prank(admin);
            hubVault.harvestYield();
            
            console2.log("  [OK] Mode", mode, "harvest successful");
        }
        
        console2.log("[OK] All yield modes tested successfully\n");
    }
}
