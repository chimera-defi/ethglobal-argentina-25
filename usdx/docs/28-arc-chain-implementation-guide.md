# Arc Chain Implementation Guide - Concrete Steps

## Quick Reference

### Arc Testnet Specifications ✅

- **Chain ID**: `5042002` ✅ **VERIFIED**
- **Network Name**: Arc Testnet
- **Currency**: USDC (native gas token) ✅ **VERIFIED**
- **Currency Symbol**: USDC
- **Currency Decimals**: 6 (USDC standard)
- **RPC Endpoints**:
  - Primary: `https://rpc.testnet.arc.network`
  - Alternative: `https://rpc.blockdaemon.testnet.arc.network`
  - Alternative: `https://rpc.drpc.testnet.arc.network`
  - Alternative: `https://rpc.quicknode.testnet.arc.network`
- **WebSocket**: `wss://rpc.testnet.arc.network`
- **Block Explorer**: `https://testnet.arcscan.app`
- **Faucet**: `https://faucet.circle.com`

### Key Integration Points

- ✅ **Bridge Kit**: Supported
- ✅ **CCTP**: Supported (contract addresses available)
- ❌ **LayerZero**: NOT supported (as of January 2025)

## Implementation Checklist

### Phase 1: Frontend Configuration

#### 1.1 Update Chain Configuration
**File**: `usdx/frontend/src/config/chains.ts`

**Exact Changes**:
```typescript
export const CHAINS = {
  HUB: {
    // ... existing config
  },
  SPOKE: {
    // ... existing config
  },
  ARC: {
    id: 5042002, // ✅ VERIFIED: Arc Testnet chain ID
    name: 'Arc Testnet',
    rpcUrl: process.env.NEXT_PUBLIC_ARC_RPC_URL || 'https://rpc.testnet.arc.network',
    currency: 'USDC', // ✅ VERIFIED: USDC is native gas token
    blockExplorer: 'https://testnet.arcscan.app',
    localhost: {
      id: 5042002,
      rpcUrl: 'http://localhost:8547', // Use different port for local fork
      blockExplorer: 'http://localhost:8547',
    },
  },
} as const;

// Update Bridge Kit chains
export const BRIDGE_KIT_CHAINS = {
  // ... existing chains
  arcTestnet: {
    id: 5042002,
    name: 'Arc Testnet',
    rpcUrl: 'https://rpc.testnet.arc.network',
  },
} as const;

// Update helper functions
export function getChainById(chainId: number): ChainType | null {
  if (chainId === CHAINS.HUB.id) return 'HUB';
  if (chainId === CHAINS.SPOKE.id) return 'SPOKE';
  if (chainId === CHAINS.ARC.id) return 'ARC';
  return null;
}

export function isSpokeChain(chainId: number): boolean {
  return chainId === CHAINS.SPOKE.id || chainId === CHAINS.ARC.id;
}
```

#### 1.2 Update Bridge Kit Chain Mapping
**File**: `usdx/frontend/src/lib/bridgeKit.ts`

**Exact Changes**:
```typescript
export function getBridgeKitChainId(chainId: number): string | null {
  const chainIdMap: Record<number, string> = {
    // Testnets
    11155111: 'ethereum-sepolia', // Ethereum Sepolia
    84532: 'base-sepolia', // Base Sepolia
    421614: 'arbitrum-sepolia', // Arbitrum Sepolia
    11155420: 'optimism-sepolia', // Optimism Sepolia
    5042002: 'arc-testnet', // ✅ Arc Testnet - VERIFY with Bridge Kit SDK
  };

  return chainIdMap[chainId] || null;
}
```

**Note**: Bridge Kit chain identifier needs verification. Check Bridge Kit SDK docs or test with SDK.

#### 1.3 Update Contract Addresses
**File**: `usdx/frontend/src/config/contracts.ts`

**Changes**: Add Arc-specific contract addresses after deployment:
```typescript
// After deploying contracts on Arc, add:
export const CONTRACTS = {
  // ... existing contracts
  ARC: {
    ARC_USDX: '<DEPLOYED_ADDRESS>',
    ARC_MINTER: '<DEPLOYED_ADDRESS>',
  },
} as const;
```

### Phase 2: Smart Contract Deployment

#### 2.1 Update Deployment Scripts
**File**: `usdx/contracts/script/DeploySpoke.s.sol`

**Exact Changes**:
```solidity
function setUp() public {
    uint256 chainId = block.chainid;
    
    if (chainId == 137) {
        // Polygon Mainnet
        POSITION_ORACLE = msg.sender; // TODO: Set actual oracle address
    } else if (chainId == 80001) {
        // Mumbai Testnet
        POSITION_ORACLE = msg.sender; // Use deployer as oracle for testing
    } else if (chainId == 5042002) {
        // Arc Testnet
        // Arc Testnet
        POSITION_ORACLE = msg.sender; // Use deployer as oracle for testing
        // NOTE: LayerZero not supported on Arc, so USDXShareOFT will not be used
        // LOCAL_EID = 0; // LayerZero not supported
    } else {
        revert("Unsupported chain");
    }
}
```

**Important**: Since LayerZero is not supported:
- Set `LZ_ENDPOINT = address(0)` or skip USDXShareOFT deployment
- ❌ Set `LOCAL_EID = 0;` LayerZero not supported
- ✅ Still deploy USDXToken and USDXSpokeMinter (but without LayerZero integration)

**Modified Deployment Flow**:
```solidity
function run() public {
    // ... existing setup
    
    // 1. Deploy USDXToken (always needed)
    USDXToken usdx = new USDXToken(deployer);
    
    // 2. Check if LayerZero is supported
    uint256 chainId = block.chainid;
    bool isLayerZeroSupported = (chainId != 5042002); // Arc doesn't support LayerZero
    
    if (isLayerZeroSupported) {
        // Deploy USDXShareOFT for LayerZero chains
        USDXShareOFT shareOFT = new USDXShareOFT(...);
        
        // Deploy minter with LayerZero support
        USDXSpokeMinter minter = new USDXSpokeMinter(
            address(usdx),
            address(shareOFT),
            LZ_ENDPOINT,
            HUB_CHAIN_ID,
            deployer
        );
    } else {
        // Arc: Deploy minter WITHOUT LayerZero support
        // Note: May need to modify USDXSpokeMinter constructor to allow null shareOFT
        // Or create Arc-specific minter contract
        USDXSpokeMinter minter = new USDXSpokeMinter(
            address(usdx),
            address(0), // No shareOFT on Arc
            address(0), // No LayerZero endpoint
            HUB_CHAIN_ID,
            deployer
        );
    }
    
    // ... rest of deployment
}
```

**⚠️ Critical**: USDXSpokeMinter may need modification to work without LayerZero. Review contract to see if it can handle `address(0)` for shareOFT.

### Phase 3: Contract Modifications (If Needed)

#### 3.1 Review USDXSpokeMinter Contract Review
**File**: `usdx/contracts/USDXSpokeMinter.sol`

**Check**:
- [ ] Can constructor accept `address(0)` for shareOFT?
- [ ] Does contract have LayerZero-specific logic that needs conditional execution?
- [ ] Can minting work without LayerZero share verification?

**Possible Solutions**:
1. **Option A**: Modify USDXSpokeMinter to make shareOFT optional
2. **Option B**: Create Arc-specific minter contract (ArcSpokeMinter)
3. **Option C**: Use alternative position verification method for Arc

#### 3.2 Alternative Position Verification for Arc

Since LayerZero is not available, consider:
- **Direct Bridge Kit Integration**: Verify USDC deposits via Bridge Kit events
- **Oracle-Based**: Use off-chain oracle to verify hub positions
- **Simplified Flow**: Arc users bridge USDC → hub, then mint USDX on Arc using hub balance

## Concrete Code Examples

### Frontend: Add Arc to Chain Selector

**File**: `usdx/frontend/src/components/ChainSelector.tsx` (if exists)

```typescript
import { CHAINS } from '@/config/chains';

const availableChains = [
  CHAINS.HUB,
  CHAINS.SPOKE,
  CHAINS.ARC, // ✅ Add Arc
];
```

### Frontend: MetaMask Chain Addition

**File**: `usdx/frontend/src/lib/ethers.ts` or wallet config

```typescript
export async function addArcChain(): Promise<void> {
  if (!window.ethereum) {
    throw new Error('MetaMask not found');
  }

  await window.ethereum.request({
    method: 'wallet_addEthereumChain',
    params: [{
      chainId: '0x4D0A02', // 5042002 in hex
      chainName: 'Arc Testnet',
      nativeCurrency: {
        name: 'USDC',
        symbol: 'USDC',
        decimals: 6,
      },
      rpcUrls: ['https://rpc.testnet.arc.network'],
      blockExplorerUrls: ['https://testnet.arcscan.app'],
    }],
  });
}
```

### Deployment: Arc-Specific Script

**File**: `usdx/contracts/script/DeployArcSpoke.s.sol` (new file)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXSpokeMinter} from "../contracts/USDXSpokeMinter.sol";

/**
 * @title DeployArcSpoke
 * @notice Deployment script for Arc Testnet (no LayerZero support)
 * @dev Run with: forge script script/DeployArcSpoke.s.sol:DeployArcSpoke --rpc-url https://rpc.testnet.arc.network --broadcast --verify
 */
contract DeployArcSpoke is Script {
    uint256 constant ARC_CHAIN_ID = 5042002;
    
    function run() public {
        require(block.chainid == ARC_CHAIN_ID, "Must deploy on Arc Testnet");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== Arc Testnet Deployment ===");
        console2.log("Chain ID:", block.chainid);
        console2.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy USDXToken
        USDXToken usdx = new USDXToken(deployer);
        console2.log("USDXToken:", address(usdx));
        
        // 2. Deploy USDXSpokeMinter (without LayerZero
        // NOTE: May need to modify constructor
        USDXSpokeMinter minter = new USDXSpokeMinter(
            address(usdx),
            address(0), // No shareOFT on Arc
            address(0), // No LayerZero
            HUB_CHAIN_ID,
            deployer
        );
        );
        
        //  roles
        usdx.grantRole(usdx.MINTER_ROLE(), address(minter));
        usdx.grantRole(keusdx.BURNER_ROLE(), address(minter));
        
        vm.stopBroadcast();
        
        console2.log("\n=== Deployment Complete ===");
        console2.log("USDXToken:", address(usdx));
        console2.log("USDXSpokeMinter:", address(minter));
    }
}
```

## Testing Strategy

### 1. Local Testing
- Fork Arc testnet: `anvil --fork-url https://rpc.testnet.arc.network --chain-id 5042002`
- Test contract deployment
- Test basic minting (without LayerZero)

### 2. Testnet Testing
- Deploy to Arc testnet
- Test Bridge Kit USDC transfers
- Test USDX minting on Arc
- Verify no LayerZero dependencies break

### 3. Integration Testing
- Test full flow: Bridge USDC → Hub → Mint USDX on Arc
- Test error cases
- Test edge cases

## Known Issues & Solutions

### Issue 1: USDXSpokeMinter Requires LayerZero ⚠️ CRITICAL
**Problem**: USDXSpokeMinter **REQUIRES** shareOFT (LayerZero-based) and cannot accept `address(0)`.

**Contract Analysis**:
- Constructor assigns `shareOFT = USDXShareOFT(_shareOFT)` without null check
- All minting functions check `shareOFT != address(0)` and revert if zero
- `setShareOFT()` requires non-zero address

**Solutions**:
1. **Modify USDXSpokeMinter** (Recommended):
   - Make shareOFT optional in constructor
   - Add conditional logic in mint functions
   - Implement alternative position verification for Arc
   - See "Contract Modifications" section above

2. **Create Arc-Specific Minter**:
   - New contract: `ArcSpokeMinter.sol`
   - Uses Bridge Kit events for position verification
   - No LayerZero dependency

3. **Oracle-Based Verification**:
   - Off-chain oracle verifies hub positions
   - On-chain minting after oracle confirmation
   - More complex but flexible

### Issue 2: Cross-Chain USDX Transfers
**Problem**: Cannot transfer USDX to/from Arc via LayerZero.

**Solutions**:
1. **Short-term**: Users must bridge USDC, not USDX, to/from Arc
2. **Medium-term**: Wait for LayerZero Arc support
3. **Long-term**: Implement alternative cross-chain solution

### Issue 3: Bridge Kit Chain Identifier
**Problem**: Exact Bridge Kit identifier for Arc unknown.

**Solution**: 
- Check Bridge Kit SDK source code
- Test with SDK to find correct identifier
- Likely: `'arc'`, `'arc-testnet'`, or `'arc-test'`

## Verification Steps

### After Frontend Changes
1. [ ] Arc appears in chain selector
2. [ ] Can switch to Arc chain in MetaMask
3. [ ] RPC connection works
4. [ ] Block explorer links work

### After Contract Deployment
1. [ ] Contracts deploy successfully
2. [ ] USDXToken works on Arc
3. [ ] USDXSpokeMinter works (or modified version)
4. [ ] No LayerZero errors

### After Bridge Kit Integration
1. [ ] Bridge Kit recognizes Arc chain
2. [ ] USDC transfers work via Bridge Kit
3. [ ] Transfer status updates correctly

## Resources

### Arc Documentation
- **Connect to Arc**: https://docs.arc.network/arc/references/connect-to-arc
- **Contract Addresses**: https://docs.arc.network/arc/references/contract-addresses
- **Gas and Fees**: https://docs.arc.network/arc/references/gas-and-fees

### Circle Documentation
- **Bridge Kit**: https://developers.circle.com/bridge-kit
- **CCTP**: https://developers.circle.com/stablecoin/docs/cctp-overview

### Implementation Files Reference
- **Chain Config**: `usdx/frontend/src/config/chains.ts`
- **Bridge Kit Config**: `usdx/frontend/src/lib/bridgeKit.ts`
- **Deployment Script**: `usdx/contracts/script/DeploySpoke.s.sol`
- **Spoke Minter**: `usdx/contracts/USDXSpokeMinter.sol`

---

**Last Updated**: January 2025  
**Status**: Ready for implementation with concrete specifications
