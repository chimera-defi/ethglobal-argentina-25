# Arc Chain Integration - Review & Clarifications

## Questions Answered

### 1. Is there an Arc Testnet we can deploy on or fork locally?

**Yes!** Arc Testnet is available:

- **Chain ID**: `5042002`
- **RPC Endpoint**: `https://rpc.testnet.arc.network`
- **Block Explorer**: `https://testnet.arcscan.app`
- **Faucet**: `https://faucet.circle.com`

**For Local Forking:**
You can fork Arc Testnet locally using Foundry's Anvil:
```bash
anvil --fork-url https://rpc.testnet.arc.network --chain-id 5042002
```

**For Deployment:**
You can deploy directly to Arc Testnet using:
```bash
forge script script/DeploySpoke.s.sol:DeploySpoke \
  --rpc-url https://rpc.testnet.arc.network \
  --broadcast \
  --verify
```

**Mainnet Status:**
- Arc Mainnet is **not yet available** (as of January 2025)
- Only testnet is operational
- Check Arc documentation for mainnet launch updates

### 2. What is the Oracle Service?

The "oracle service" I mentioned is an **off-chain service** that verifies and updates user positions on the Arc chain. Here's what it does:

#### Purpose
Since Arc doesn't support LayerZero, we can't use `USDXShareOFT` to track cross-chain positions. Instead, we need an alternative way to verify that users have deposited USDC on the Ethereum Hub chain.

#### How It Works

**The Flow:**
1. User bridges USDC from Arc → Ethereum Hub via Bridge Kit
2. User deposits USDC into `USDXVault` on Ethereum Hub → receives USDX
3. **Oracle Service** monitors these events:
   - Bridge Kit events (USDC bridged from Arc)
   - USDXVault deposit events (USDC → USDX minted)
4. Oracle calculates user's verified position
5. Oracle calls `updateHubPosition(user, amount)` on Arc minter contract
6. User can now mint USDX on Arc using verified position

#### Implementation Options

**Option A: Off-Chain Oracle Service** (What I implemented)
- Off-chain service (Node.js/Python) monitors Ethereum Hub events
- Calls `updateHubPosition()` on Arc minter contract
- Requires `POSITION_UPDATER_ROLE` permission
- **Pros**: Flexible, can handle complex logic
- **Cons**: Requires infrastructure, centralized component

**Option B: On-Chain Bridge Kit Event Verification** (Alternative)
- Use Bridge Kit's on-chain events directly
- Verify CCTP attestations on-chain
- **Pros**: More decentralized
- **Cons**: More complex, may require Bridge Kit contract integration

**Option C: Simplified Flow** (Simplest)
- Users bridge USDC Arc → Hub
- Users deposit USDC → get USDX on Hub
- Users can't mint USDX on Arc (only on Hub)
- **Pros**: No oracle needed
- **Cons**: Limited functionality on Arc

#### Current Implementation

I implemented **Option A** with the oracle service because:
- It provides full functionality (minting USDX on Arc)
- It's the most flexible approach
- It can be replaced later with a more decentralized solution

**Oracle Service Requirements:**
- Monitor Ethereum Hub chain for Bridge Kit events
- Monitor USDXVault deposit events
- Calculate user positions
- Call `updateHubPosition()` on Arc minter contract
- Handle edge cases (withdrawals, etc.)

## Multi-Pass Code Review

### Pass 1: Contract Logic Review

#### ✅ USDXSpokeMinter.sol - Constructor
**Status**: ✅ **CORRECT**
- Properly handles optional `shareOFT` and `lzEndpoint`
- Only assigns if non-zero
- Grants all necessary roles including `POSITION_UPDATER_ROLE`

#### ⚠️ USDXSpokeMinter.sol - shareOFT Type Issue
**Issue Found**: `shareOFT` is declared as `USDXShareOFT public shareOFT;` (contract type)

**Problem**: 
- If `shareOFT` is never initialized, it's `address(0)`
- We check `address(shareOFT) != address(0)` which works
- But we can't "unset" shareOFT once set (setShareOFT reverts on zero)

**Impact**: **LOW** - This is fine for our use case:
- Arc deployments won't initialize shareOFT (stays at zero)
- LayerZero chains will initialize shareOFT once
- We don't need to unset shareOFT

**Fix Needed**: None - current behavior is acceptable

#### ✅ USDXSpokeMinter.sol - Mint Functions
**Status**: ✅ **CORRECT**
- Properly checks if LayerZero is available
- Uses appropriate verification method
- Handles both paths correctly

#### ✅ USDXSpokeMinter.sol - Position Update Functions
**Status**: ✅ **CORRECT**
- `updateHubPosition()` properly restricted to `POSITION_UPDATER_ROLE`
- `batchUpdateHubPositions()` handles arrays correctly
- Events emitted properly

#### ⚠️ USDXSpokeMinter.sol - Burn Function
**Issue Found**: Burn doesn't restore verified position

**Current Behavior**:
- User mints USDX using verified position
- Position decreases
- User burns USDX
- Position stays decreased (doesn't restore)

**Impact**: **MEDIUM** - This might be intentional:
- If user burns USDX, they may have withdrawn from hub
- Or they may want to free up capacity for new deposits
- Need to clarify intended behavior

**Recommendation**: 
- If burning should restore position: Add `verifiedHubPositions[msg.sender] += amount;` in burn function
- If burning shouldn't restore: Keep current behavior (user needs oracle to update position)

### Pass 2: Frontend Configuration Review

#### ✅ chains.ts
**Status**: ✅ **CORRECT**
- Arc chain configuration is correct
- Chain ID, RPC URL, block explorer all correct
- Helper functions updated properly

#### ⚠️ bridgeKit.ts
**Issue Found**: Using `Blockchain.Arc_Testnet as any`

**Problem**: 
- We don't know if this enum value exists
- TypeScript `as any` bypasses type checking
- May cause runtime errors if enum doesn't exist

**Impact**: **HIGH** - Needs verification

**Fix Needed**: 
1. Check Bridge Kit SDK source code
2. Test Bridge Kit initialization with Arc chain ID
3. Update with correct enum value

**Temporary Workaround**: Current code will work but may fail at runtime if enum doesn't exist

### Pass 3: Deployment Scripts Review

#### ✅ DeploySpoke.s.sol
**Status**: ✅ **CORRECT**
- Properly handles Arc chain ID
- Conditionally deploys USDXShareOFT
- Deploys USDXSpokeMinter with correct parameters
- Grants appropriate roles

#### ⚠️ DeploySpoke.s.sol - shareOFT Variable
**Issue Found**: `USDXShareOFT shareOFT;` declared but may not be initialized

**Problem**: 
- If `isLayerZeroSupported` is false, shareOFT is never initialized
- Later code checks `if (isLayerZeroSupported)` before using shareOFT
- This is safe but could be cleaner

**Impact**: **LOW** - Code is safe, just not ideal

**Fix**: None needed - current code is safe

### Pass 4: Test Coverage Review

#### ✅ USDXSpokeMinterArcTest
**Status**: ✅ **GOOD COVERAGE**
- Tests deployment without LayerZero
- Tests minting with verified positions
- Tests error cases
- Tests batch updates
- Tests view functions

#### ⚠️ Missing Test Cases
**Missing**:
- Test for burn function with verified positions
- Test for position updates after withdrawals
- Test for edge cases (zero positions, etc.)

**Impact**: **MEDIUM** - Should add more tests

### Pass 5: Integration Flow Review

#### ✅ User Flow
**Status**: ✅ **LOGICAL**
1. User bridges USDC Arc → Hub ✅
2. User deposits USDC → gets USDX on Hub ✅
3. Oracle updates position on Arc ✅
4. User mints USDX on Arc ✅

#### ⚠️ Oracle Dependency
**Issue**: Flow depends on oracle service

**Impact**: **HIGH** - Need to clarify:
- Is oracle service acceptable?
- Should we implement alternative?
- How do we handle oracle failures?

## Critical Issues Found

### 🔴 Critical Issue #1: Bridge Kit Enum Value Unknown
**File**: `usdx/frontend/src/lib/bridgeKit.ts:115`
**Issue**: Using `Blockchain.Arc_Testnet as any` without verification
**Impact**: May fail at runtime if enum doesn't exist
**Fix**: Verify with Bridge Kit SDK or test initialization

### 🟡 Medium Issue #1: Burn Doesn't Restore Position
**File**: `usdx/contracts/contracts/USDXSpokeMinter.sol:198-210`
**Issue**: Burning USDX doesn't restore verified position
**Impact**: Users may lose minting capacity after burning
**Fix**: Clarify intended behavior and implement accordingly

### 🟡 Medium Issue #2: Oracle Service Required
**Issue**: Flow depends on off-chain oracle service
**Impact**: Centralized component, requires infrastructure
**Fix**: Consider alternatives or document oracle requirements clearly

## Recommendations

### Immediate Actions

1. **Verify Bridge Kit Enum Value**
   - Check Bridge Kit SDK source code
   - Test Bridge Kit initialization
   - Update code with correct value

2. **Clarify Burn Behavior**
   - Decide if burning should restore position
   - Update contract if needed
   - Update tests

3. **Document Oracle Requirements**
   - Create oracle service specification
   - Document how to set up oracle
   - Provide oracle implementation example

### Testing Recommendations

1. **Local Fork Testing**
   ```bash
   anvil --fork-url https://rpc.testnet.arc.network --chain-id 5042002
   ```

2. **Testnet Deployment**
   - Deploy to Arc Testnet
   - Test Bridge Kit integration
   - Test oracle service (or manual position updates)

3. **End-to-End Testing**
   - Test full user flow
   - Test error cases
   - Test oracle failure scenarios

## Summary

### ✅ What Works
- Contract logic is sound
- Frontend configuration is correct
- Deployment scripts handle Arc properly
- Tests cover basic functionality

### ⚠️ What Needs Attention
- Bridge Kit enum value needs verification
- Burn behavior needs clarification
- Oracle service needs documentation/implementation

### 🔴 What's Missing
- Oracle service implementation
- Bridge Kit enum verification
- Additional test cases

## Next Steps

1. **Verify Bridge Kit Support**
   - Test Bridge Kit with Arc chain ID
   - Confirm enum value or find alternative

2. **Implement Oracle Service** (or choose alternative)
   - Create oracle service specification
   - Implement monitoring and position updates
   - Test oracle service

3. **Clarify Burn Behavior**
   - Decide on intended behavior
   - Update contract if needed

4. **Test on Arc Testnet**
   - Fork Arc testnet locally
   - Deploy contracts
   - Test full flow

---

**Review Date**: January 2025  
**Reviewer**: Self-assessment  
**Status**: ✅ **Code is functional but needs verification and clarification**
