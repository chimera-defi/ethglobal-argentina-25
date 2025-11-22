#!/usr/bin/env node

/**
 * Bridge Relayer for USDX Protocol (MVP)
 * 
 * This script simulates cross-chain messaging between hub and spoke chains.
 * It watches for deposit events on the hub chain and syncs user positions
 * to the spoke chain minter.
 * 
 * In production, this will be replaced by:
 * - LayerZero OApp for secure cross-chain messaging
 * - Hyperlane ISM for alternative routing
 * - Circle CCTP for native USDC bridging
 */

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

// Configuration
const HUB_RPC = 'http://localhost:8545';
const SPOKE_RPC = 'http://localhost:8546';
const PRIVATE_KEY = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

// Load deployment addresses
const hubDeploymentPath = path.join(__dirname, '../deployments/hub-local.json');
const spokeDeploymentPath = path.join(__dirname, '../deployments/spoke-local.json');

let hubAddresses, spokeAddresses;

try {
  hubAddresses = JSON.parse(fs.readFileSync(hubDeploymentPath, 'utf8'));
  spokeAddresses = JSON.parse(fs.readFileSync(spokeDeploymentPath, 'utf8'));
} catch (error) {
  console.error('❌ Error loading deployment files. Make sure contracts are deployed.');
  console.error('   Run: forge script script/DeployHubOnly.s.sol --rpc-url http://localhost:8545 --broadcast');
  console.error('   Run: forge script script/DeploySpokeOnly.s.sol --rpc-url http://localhost:8546 --broadcast');
  process.exit(1);
}

// ABIs (minimal)
const VAULT_ABI = [
  'event Deposited(address indexed user, uint256 usdcAmount, uint256 usdxAmount)',
  'event Withdrawn(address indexed user, uint256 usdcAmount, uint256 usdxAmount)',
  'function getUserPosition(address user) view returns (uint256)',
];

const SPOKE_MINTER_ABI = [
  'function updateHubPosition(address user, uint256 position) external',
  'event HubPositionUpdated(address indexed user, uint256 newPosition, address indexed updater)',
];

// Setup providers and signers
const hubProvider = new ethers.JsonRpcProvider(HUB_RPC);
const spokeProvider = new ethers.JsonRpcProvider(SPOKE_RPC);
const hubSigner = new ethers.Wallet(PRIVATE_KEY, hubProvider);
const spokeSigner = new ethers.Wallet(PRIVATE_KEY, spokeProvider);

// Contract instances
const hubVault = new ethers.Contract(hubAddresses.contracts.hubVault.address, VAULT_ABI, hubProvider);
const spokeMinter = new ethers.Contract(spokeAddresses.contracts.spokeMinter.address, SPOKE_MINTER_ABI, spokeSigner);

// State
const syncedPositions = new Map();
let isRunning = true;

console.log('╔═══════════════════════════════════════════════════════════╗');
console.log('║                                                           ║');
console.log('║         🌉 USDX Bridge Relayer (MVP)                     ║');
console.log('║                                                           ║');
console.log('╚═══════════════════════════════════════════════════════════╝');
console.log('');
console.log('📡 Hub Chain (Ethereum):   ', HUB_RPC);
console.log('📡 Spoke Chain (Polygon):  ', SPOKE_RPC);
console.log('');
console.log('📝 Contracts:');
console.log('   Hub Vault:    ', hubAddresses.contracts.hubVault.address);
console.log('   Spoke Minter: ', spokeAddresses.contracts.spokeMinter.address);
console.log('');
console.log('🔄 Watching for deposit events on hub chain...');
console.log('💡 Press Ctrl+C to stop');
console.log('');

// Listen for deposit events on hub
hubVault.on('Deposited', async (user, usdcAmount, usdxAmount, event) => {
  try {
    console.log('─────────────────────────────────────────────────────────');
    console.log('🔔 New Deposit Event Detected!');
    console.log('   User:        ', user);
    console.log('   USDC Amount: ', ethers.formatUnits(usdcAmount, 6));
    console.log('   USDX Amount: ', ethers.formatUnits(usdxAmount, 6));
    console.log('   Block:       ', event.log.blockNumber);
    console.log('');

    // Get user's total position on hub
    const hubPosition = await hubVault.getUserPosition(user);
    console.log('📊 Hub Position: ', ethers.formatUnits(hubPosition, 6), 'USDX');

    // Check if we need to sync
    const lastSynced = syncedPositions.get(user) || BigInt(0);
    if (hubPosition === lastSynced) {
      console.log('✅ Position already synced');
      return;
    }

    // Sync position to spoke chain
    console.log('🔄 Syncing position to spoke chain...');
    const tx = await spokeMinter.updateHubPosition(user, hubPosition);
    console.log('   Transaction: ', tx.hash);
    
    const receipt = await tx.wait();
    console.log('✅ Position synced! Gas used:', receipt.gasUsed.toString());
    
    // Update our cache
    syncedPositions.set(user, hubPosition);
    console.log('');
  } catch (error) {
    console.error('❌ Error syncing position:', error.message);
  }
});

// Listen for withdrawal events on hub
hubVault.on('Withdrawn', async (user, usdcAmount, usdxAmount, event) => {
  try {
    console.log('─────────────────────────────────────────────────────────');
    console.log('🔔 New Withdrawal Event Detected!');
    console.log('   User:        ', user);
    console.log('   USDC Amount: ', ethers.formatUnits(usdcAmount, 6));
    console.log('   USDX Amount: ', ethers.formatUnits(usdxAmount, 6));
    console.log('   Block:       ', event.log.blockNumber);
    console.log('');

    // Get user's updated position on hub
    const hubPosition = await hubVault.getUserPosition(user);
    console.log('📊 Updated Hub Position: ', ethers.formatUnits(hubPosition, 6), 'USDX');

    // Sync updated position to spoke chain
    console.log('🔄 Syncing updated position to spoke chain...');
    const tx = await spokeMinter.updateHubPosition(user, hubPosition);
    console.log('   Transaction: ', tx.hash);
    
    const receipt = await tx.wait();
    console.log('✅ Position synced! Gas used:', receipt.gasUsed.toString());
    
    // Update our cache
    syncedPositions.set(user, hubPosition);
    console.log('');
  } catch (error) {
    console.error('❌ Error syncing position:', error.message);
  }
});

// Periodic sync (every 30 seconds) - in case we missed any events
setInterval(async () => {
  if (!isRunning) return;
  
  try {
    // This would normally sync all users, but for MVP we just check if service is alive
    const hubBlock = await hubProvider.getBlockNumber();
    const spokeBlock = await spokeProvider.getBlockNumber();
    
    console.log(`⏰ Heartbeat - Hub: block ${hubBlock}, Spoke: block ${spokeBlock}`);
  } catch (error) {
    console.error('❌ Heartbeat error:', error.message);
  }
}, 30000);

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('');
  console.log('🛑 Shutting down bridge relayer...');
  isRunning = false;
  process.exit(0);
});

// Keep alive
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught exception:', error);
});

process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled rejection:', error);
});
