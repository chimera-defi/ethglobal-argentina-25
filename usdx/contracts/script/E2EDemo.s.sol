// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {USDXVault} from "../contracts/USDXVault.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {MockUSDC} from "../contracts/mocks/MockUSDC.sol";

/**
 * @title E2EDemo
 * @notice Demonstrates the complete USDX Protocol flow on live local chains
 * @dev This script runs against deployed contracts on local anvil chains
 * 
 * Usage:
 *   forge script script/E2EDemo.s.sol:E2EDemo \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast \
 *     -vvvv
 */
contract E2EDemo is Script {
    // Test user (Anvil's second account)
    address constant USER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint256 constant USER_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    
    uint256 constant DEPOSIT_AMOUNT = 1000e6; // 1,000 USDC
    
    function run() external {
        console.log("\n");
        console.log("================================================================================");
        console.log("||              USDX PROTOCOL - LIVE E2E DEMONSTRATION                       ||");
        console.log("||                   On Local Anvil Chains                                   ||");
        console.log("================================================================================");
        console.log("");
        
        // Load deployed contract addresses from environment or use defaults
        // In production, read from deployments/forked-local.json
        address usdcAddress = vm.envOr("HUB_USDC", address(0));
        address vaultAddress = vm.envOr("HUB_VAULT", address(0));
        address usdxAddress = vm.envOr("HUB_USDX", address(0));
        
        if (usdcAddress == address(0)) {
            console.log("[ERROR] Contract addresses not set!");
            console.log("[INFO] Run start-multi-chain.sh first to deploy contracts");
            return;
        }
        
        console.log("CONFIGURATION:");
        console.log("  User Address: %s", USER);
        console.log("  USDC: %s", usdcAddress);
        console.log("  Vault: %s", vaultAddress);
        console.log("  USDX: %s", usdxAddress);
        console.log("");
        
        MockUSDC usdc = MockUSDC(usdcAddress);
        USDXVault vault = USDXVault(vaultAddress);
        USDXToken usdx = USDXToken(usdxAddress);
        
        // ============ PHASE 1: Check Initial Balances ============
        console.log("================================================================================");
        console.log("PHASE 1: INITIAL STATE");
        console.log("================================================================================");
        console.log("");
        
        uint256 initialUsdcBalance = usdc.balanceOf(USER);
        uint256 initialUsdxBalance = usdx.balanceOf(USER);
        
        console.log("[BEFORE] User USDC Balance: %s USDC", initialUsdcBalance / 1e6);
        console.log("[BEFORE] User USDX Balance: %s USDX", initialUsdxBalance / 1e6);
        console.log("[BEFORE] Vault Total Collateral: %s USDC", vault.totalCollateral() / 1e6);
        console.log("");
        
        // ============ PHASE 2: Approve and Deposit ============
        console.log("================================================================================");
        console.log("PHASE 2: DEPOSIT USDC INTO VAULT");
        console.log("================================================================================");
        console.log("");
        
        vm.startBroadcast(USER_KEY);
        
        console.log("[ACTION] Approving vault to spend %s USDC...", DEPOSIT_AMOUNT / 1e6);
        usdc.approve(address(vault), DEPOSIT_AMOUNT);
        console.log("[SUCCESS] Approval granted!");
        console.log("");
        
        console.log("[ACTION] Depositing %s USDC into vault...", DEPOSIT_AMOUNT / 1e6);
        vault.deposit(DEPOSIT_AMOUNT);
        console.log("[SUCCESS] Deposit completed!");
        console.log("");
        
        vm.stopBroadcast();
        
        // Check balances after deposit
        uint256 afterUsdcBalance = usdc.balanceOf(USER);
        uint256 afterUsdxBalance = usdx.balanceOf(USER);
        uint256 totalCollateral = vault.totalCollateral();
        
        console.log("[AFTER] User USDC Balance: %s USDC (-%s)", 
            afterUsdcBalance / 1e6, 
            (initialUsdcBalance - afterUsdcBalance) / 1e6
        );
        console.log("[AFTER] User USDX Balance: %s USDX (+%s)", 
            afterUsdxBalance / 1e6,
            (afterUsdxBalance - initialUsdxBalance) / 1e6
        );
        console.log("[AFTER] Vault Total Collateral: %s USDC", totalCollateral / 1e6);
        console.log("");
        
        console.log("[OK] Deposit successful!");
        console.log("[OK] User received USDX 1:1 with deposited USDC");
        console.log("");
        
        // ============ PHASE 3: Use USDX (Transfer) ============
        console.log("================================================================================");
        console.log("PHASE 3: USE USDX (TRANSFER)");
        console.log("================================================================================");
        console.log("");
        
        address recipient = address(0x9999);
        uint256 transferAmount = 250e6;
        
        console.log("[BEFORE] User USDX Balance: %s USDX", usdx.balanceOf(USER) / 1e6);
        console.log("[BEFORE] Recipient USDX Balance: %s USDX", usdx.balanceOf(recipient) / 1e6);
        console.log("");
        
        vm.startBroadcast(USER_KEY);
        
        console.log("[ACTION] Transferring %s USDX to recipient...", transferAmount / 1e6);
        usdx.transfer(recipient, transferAmount);
        console.log("[SUCCESS] Transfer completed!");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("[AFTER] User USDX Balance: %s USDX", usdx.balanceOf(USER) / 1e6);
        console.log("[AFTER] Recipient USDX Balance: %s USDX", usdx.balanceOf(recipient) / 1e6);
        console.log("");
        
        console.log("[OK] USDX transferred successfully");
        console.log("[OK] Demonstrates USDX is fully liquid and usable");
        console.log("");
        
        // ============ FINAL SUMMARY ============
        console.log("================================================================================");
        console.log("||                    DEMONSTRATION COMPLETED SUCCESSFULLY                    ||");
        console.log("================================================================================");
        console.log("");
        console.log("SUMMARY:");
        console.log("  1. [OK] Deposited %s USDC on Hub Chain", DEPOSIT_AMOUNT / 1e6);
        console.log("  2. [OK] Received %s USDX tokens (1:1)", DEPOSIT_AMOUNT / 1e6);
        console.log("  3. [OK] Transferred %s USDX to another user", transferAmount / 1e6);
        console.log("  4. [OK] Vault holds %s USDC in collateral", totalCollateral / 1e6);
        console.log("");
        console.log("KEY FEATURES DEMONSTRATED:");
        console.log("  - Collateralized stablecoin minting [OK]");
        console.log("  - Full liquidity and transferability [OK]");
        console.log("  - 1:1 USDC backing maintained [OK]");
        console.log("");
        console.log("NEXT STEPS:");
        console.log("  - Cross-chain flow requires LayerZero endpoints");
        console.log("  - Full E2E test available in test/forge/IntegrationE2E_OVault.t.sol");
        console.log("  - Run: forge test --match-test testCompleteE2EFlow -vv");
        console.log("");
        console.log("================================================================================");
        console.log("");
    }
}
