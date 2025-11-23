# Arc Chain Integration - Implementation Task List

## Overview

This document provides a comprehensive task list for implementing Circle's Arc chain as a spoke chain in the USDX Protocol. This task list should be used by the implementation agent to systematically add Arc chain support.

## Prerequisites

Before starting implementation, ensure:
- [ ] All research from `25-circle-arc-chain-research.md` is complete
- [ ] Arc chain specifications are verified (chain ID, RPC endpoints, etc.)
- [ ] CCTP contract addresses are confirmed
- [ ] Bridge Kit SDK support is verified
- [ ] LayerZero support is verified

## Task Breakdown

### Phase 1: Research & Verification ✅ (Current Phase)

**Status**: Research phase - gathering information

- [x] Create research document (`25-circle-arc-chain-research.md`)
- [x] Document integration requirements
- [ ] Verify Arc chain ID
- [ ] Verify CCTP contract addresses on Arc
- [ ] Verify Bridge Kit SDK support for Arc
- [ ] Verify LayerZero support for Arc
- [ ] Gather all network configuration details

**Output**: Complete research document with all verified information

---

### Phase 2: Frontend Configuration

#### Task 2.1: Update Chain Configuration
**File**: `usdx/frontend/src/config/chains.ts`

**Changes Needed**:
- [ ] Add Arc chain configuration to `CHAINS` object
- [ ] Add Arc to `BRIDGE_KIT_CHAINS` if supported
- [ ] Update `getChainById()` function to handle Arc chain ID
- [ ] Add `isSpokeChain()` check for Arc

**Example Structure**:
```typescript
ARC: {
  id: <ARC_CHAIN_ID>, // To be determined
  name: 'Arc',
  rpcUrl: process.env.NEXT_PUBLIC_ARC_RPC_URL || '<DEFAULT_RPC_URL>',
  currency: '<NATIVE_CURRENCY>', // Likely 'ETH' or 'ARC'
  blockExplorer: '<BLOCK_EXPLORER_URL>',
  localhost: {
    id: <ARC_CHAIN_ID>,
    rpcUrl: 'http://localhost:<PORT>',
    blockExplorer: 'http://localhost:<PORT>',
  },
}
```

**Dependencies**: Phase 1 complete

---

#### Task 2.2: Update Bridge Kit Chain Mapping
**File**: `usdx/frontend/src/lib/bridgeKit.ts`

**Changes Needed**:
- [ ] Add Arc chain ID to `chainIdMap` in `getBridgeKitChainId()`
- [ ] Map Arc chain ID to Bridge Kit identifier (e.g., `'arc'` or `'arc-mainnet'`)

**Example**:
```typescript
const chainIdMap: Record<number, string> = {
  // ... existing chains
  <ARC_CHAIN_ID>: 'arc', // To be verified
};
```

**Dependencies**: Task 2.1, Bridge Kit SDK support verification

---

#### Task 2.3: Update Contract Addresses Configuration
**File**: `usdx/frontend/src/config/contracts.ts`

**Changes Needed**:
- [ ] Add Arc chain contract addresses (if different from other spokes)
- [ ] Update contract address mappings for Arc chain ID

**Note**: May use same contract addresses pattern as other spoke chains if contracts are deployed per-chain

**Dependencies**: Task 2.1

---

#### Task 2.4: Update Wallet Configuration
**Files**: 
- `usdx/frontend/src/lib/ethers.ts`
- `usdx/frontend/src/hooks/useWallet.ts`

**Changes Needed**:
- [ ] Ensure wallet providers support Arc chain
- [ ] Add Arc chain to MetaMask/Web3 wallet chain configurations
- [ ] Update chain switching logic if needed

**Dependencies**: Task 2.1

---

### Phase 3: Smart Contract Configuration

#### Task 3.1: Update Deployment Scripts
**Files**:
- `usdx/contracts/script/DeploySpoke.s.sol`
- `usdx/contracts/script/DeploySpokeOnly.s.sol`

**Changes Needed**:
- [ ] Add Arc chain ID check in `setUp()` function
- [ ] Configure Arc-specific LayerZero endpoint ID (EID)
- [ ] Set Arc-specific position oracle address (if needed)
- [ ] Add Arc chain ID comments/documentation

**Example**:
```solidity
if (chainId == <ARC_CHAIN_ID>) {
    // Arc Mainnet
    POSITION_ORACLE = msg.sender; // TODO: Set actual oracle address
    LOCAL_EID = <ARC_LAYERZERO_EID>; // To be determined
} else if (chainId == 137) {
    // Existing Polygon configuration
    // ...
}
```

**Dependencies**: Phase 1 complete, LayerZero EID verification

---

#### Task 3.2: Update Contract Chain ID Handling
**Files**:
- `usdx/contracts/USDXSpokeMinter.sol`
- `usdx/contracts/USDXToken.sol`
- `usdx/contracts/USDXShareOFT.sol`

**Changes Needed**:
- [ ] Review contracts for chain-specific logic
- [ ] Ensure contracts handle Arc chain ID correctly
- [ ] Update any hardcoded chain ID checks (if any)
- [ ] Verify cross-chain message handling works with Arc

**Note**: Most contracts should be chain-agnostic, but verify any chain-specific logic

**Dependencies**: Task 3.1

---

#### Task 3.3: Update LayerZero Configuration
**Files**: Contract deployment scripts and configuration files

**Changes Needed**:
- [ ] Add Arc LayerZero endpoint ID to configuration
- [ ] Update cross-chain path mappings (Hub ↔ Arc)
- [ ] Configure LayerZero message types for Arc
- [ ] Verify LayerZero endpoint contract address on Arc

**Dependencies**: Phase 1 complete, LayerZero support verification

---

### Phase 4: Testing

#### Task 4.1: Local Testing Setup
**Files**: Test configuration and scripts

**Changes Needed**:
- [ ] Set up local Arc chain fork (if possible)
- [ ] Configure test environment for Arc chain
- [ ] Update test scripts to support Arc chain ID
- [ ] Create test fixtures for Arc chain

**Dependencies**: Phase 2 and 3 complete

---

#### Task 4.2: Unit Tests
**Files**: Test files in `usdx/contracts/test/`

**Changes Needed**:
- [ ] Add Arc chain ID to test fixtures
- [ ] Create Arc-specific test cases (if needed)
- [ ] Test contract deployment on Arc chain ID
- [ ] Test cross-chain operations (Hub ↔ Arc)

**Dependencies**: Task 4.1

---

#### Task 4.3: Integration Tests
**Files**: Integration test files

**Changes Needed**:
- [ ] Test full flow: Deposit → Mint → Transfer → Burn
- [ ] Test Bridge Kit integration with Arc
- [ ] Test LayerZero cross-chain transfers to/from Arc
- [ ] Test error handling and edge cases

**Dependencies**: Task 4.2

---

#### Task 4.4: End-to-End Testing
**Environment**: Testnet (if available) or mainnet

**Changes Needed**:
- [ ] Deploy contracts to Arc testnet/mainnet
- [ ] Test complete user flow on Arc chain
- [ ] Verify Bridge Kit transfers work
- [ ] Verify LayerZero cross-chain transfers work
- [ ] Test with real wallets and transactions

**Dependencies**: All previous tasks complete

---

### Phase 5: Documentation

#### Task 5.1: Update Architecture Documentation
**File**: `usdx/docs/02-architecture.md`

**Changes Needed**:
- [ ] Add Arc to spoke chains list
- [ ] Update chain configuration examples
- [ ] Update flow diagrams if needed

**Dependencies**: Phase 4 complete

---

#### Task 5.2: Update Deployment Documentation
**File**: `usdx/contracts/DEPLOYMENT-GUIDE.md`

**Changes Needed**:
- [ ] Add Arc chain deployment instructions
- [ ] Document Arc-specific configuration
- [ ] Add Arc contract addresses (after deployment)
- [ ] Update verification commands

**Dependencies**: Phase 4 complete

---

#### Task 5.3: Update Frontend Documentation
**Files**: Frontend documentation files

**Changes Needed**:
- [ ] Document Arc chain configuration
- [ ] Update chain selector documentation
- [ ] Update Bridge Kit integration docs

**Dependencies**: Phase 2 complete

---

#### Task 5.4: Create Arc Chain Summary
**File**: `usdx/docs/27-arc-chain-integration-complete.md`

**Changes Needed**:
- [ ] Document final Arc chain configuration
- [ ] List deployed contract addresses
- [ ] Document any Arc-specific considerations
- [ ] Create quick reference guide

**Dependencies**: All phases complete

---

## Implementation Checklist

### Pre-Implementation
- [ ] All research complete (`25-circle-arc-chain-research.md`)
- [ ] Arc chain specifications verified
- [ ] CCTP contract addresses confirmed
- [ ] Bridge Kit SDK support confirmed
- [ ] LayerZero support confirmed

### Frontend
- [ ] Chain configuration added
- [ ] Bridge Kit mapping updated
- [ ] Contract addresses configured
- [ ] Wallet support verified

### Contracts
- [ ] Deployment scripts updated
- [ ] Contract chain handling verified
- [ ] LayerZero configuration updated

### Testing
- [ ] Local testing setup complete
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] End-to-end tests passing

### Documentation
- [ ] Architecture docs updated
- [ ] Deployment docs updated
- [ ] Frontend docs updated
- [ ] Integration summary created

## Verification Steps

After implementation, verify:

1. **Chain Configuration**
   - [ ] Arc chain appears in chain selector
   - [ ] Wallet can connect to Arc chain
   - [ ] RPC endpoints are correct

2. **Bridge Kit Integration**
   - [ ] Bridge Kit recognizes Arc chain
   - [ ] USDC transfers work via Bridge Kit to/from Arc
   - [ ] Transfer status updates correctly

3. **Contract Deployment**
   - [ ] Contracts deploy successfully on Arc
   - [ ] Contract addresses are correct
   - [ ] Permissions are set correctly

4. **Cross-Chain Operations**
   - [ ] LayerZero messages work to/from Arc
   - [ ] USDX can be minted on Arc using hub positions
   - [ ] USDX can be transferred cross-chain
   - [ ] USDX can be burned on Arc

5. **User Flow**
   - [ ] User can deposit USDC on Arc → bridge to hub
   - [ ] User can mint USDX on Arc
   - [ ] User can transfer USDX from Arc to other chains
   - [ ] User can burn USDX on Arc → redeem on hub

## Known Challenges

1. **Limited Documentation**: Arc is new, documentation may be incomplete
2. **SDK Support**: Bridge Kit SDK may need updates for Arc support
3. **LayerZero Support**: May need to wait for LayerZero to add Arc support
4. **Testing**: Testnet may not be available, requiring mainnet testing

## Rollback Plan

If issues are encountered:
1. Keep Arc chain configuration commented out
2. Document issues encountered
3. Wait for Circle/LayerZero updates if needed
4. Re-attempt integration after dependencies are resolved

## Success Criteria

Integration is complete when:
- ✅ Arc chain appears in frontend chain selector
- ✅ Contracts deploy successfully on Arc
- ✅ Bridge Kit transfers work to/from Arc
- ✅ LayerZero cross-chain transfers work
- ✅ Full user flow works end-to-end
- ✅ All tests pass
- ✅ Documentation is complete

---

**Last Updated**: January 2025  
**Status**: Ready for implementation after research phase
