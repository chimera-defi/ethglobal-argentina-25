# Tasks for Next Agent - USDX Protocol Implementation

## Critical Issues to Fix

### 1. Remove Trusted Relayer Pattern ❌
**Current Issue**: CrossChainBridge and USDXSpokeMinter use trusted relayer pattern
**Required**: Implement proper LayerZero OApp and Hyperlane adapters

**Files to Update**:
- `contracts/contracts/core/CrossChainBridge.sol` - Replace with LayerZero OApp implementation
- `contracts/contracts/core/USDXSpokeMinter.sol` - Use cross-chain verification instead of relayer
- `contracts/contracts/adapters/LayerZeroAdapter.sol` - Create proper OApp adapter
- `contracts/contracts/adapters/HyperlaneAdapter.sol` - Create proper Hyperlane adapter

**References**:
- LayerZero OApp docs: https://docs.layerzero.network/contracts/oapp
- Hyperlane docs: https://docs.hyperlane.xyz
- See `docs/08-layerzero-research.md` and `docs/19-hyperlane-deep-research.md`

### 2. Frontend Library Replacement ❌
**Current Issue**: Using wagmi/RainbowKit which user doesn't want
**Required**: Use ethers.js directly + Bridge Kit SDK

**Files to Update**:
- `frontend/app/providers.tsx` - Remove wagmi/RainbowKit, use ethers.js
- `frontend/app/wagmi.config.ts` - Replace with ethers.js config
- `frontend/app/components/*` - Update all components to use ethers.js
- `frontend/package.json` - Remove wagmi, @rainbow-me/rainbowkit, add ethers

**Note**: Bridge Kit requires `@circle-fin/adapter-viem-v2` which uses viem. You may need to:
- Use ethers.js for wallet connection
- Use viem only for Bridge Kit adapter (they can coexist)
- Or check if Bridge Kit has an ethers adapter

**References**:
- Bridge Kit docs: `docs/RESEARCH-bridge-kit.md`
- Bridge Kit uses viem adapter: `@circle-fin/adapter-viem-v2`

### 3. Fix Contract Compilation Issues ⚠️
**Current Issues**:
- Some tests failing due to access control setup
- Reentrancy guard false positives in tests
- Need to verify all contracts compile cleanly

**Tasks**:
- Fix test setup issues (access control)
- Review reentrancy guard usage
- Ensure all contracts compile without warnings
- Run full test suite and fix failures

### 4. LayerZero Contracts Installation ❌
**Current Issue**: LayerZero repo not found
**Required**: Find correct LayerZero contracts repo and install

**Task**:
- Find correct LayerZero OApp contracts repository
- Install via Foundry
- Update remappings in `foundry.toml`
- Verify imports work

**Possible repos**:
- `LayerZero-Labs/lz-evm-oapp-v2`
- `LayerZero-Labs/lz-evm-protocol-v2`
- Check LayerZero docs for correct package

### 5. Implement Proper Cross-Chain Verification ✅
**Current Issue**: USDXSpokeMinter uses trusted relayer
**Required**: Verify hub chain positions via LayerZero/Hyperlane messages

**Implementation**:
- USDXSpokeMinter should send message to hub chain requesting position verification
- Hub chain responds with position data
- Spoke chain verifies and mints USDX

**See**: `docs/05-technical-specification.md` for message formats

## Architecture Corrections Needed

### 1. CrossChainBridge Should Use LayerZero OApp
**Current**: Trusted relayer pattern
**Required**: 
- Implement LayerZero OApp standard
- Use `_lzSend()` and `_lzReceive()` pattern
- Proper nonce management
- Trusted remote configuration

**Reference**: `docs/08-layerzero-research.md` section on OApp implementation

### 2. USDXSpokeMinter Should Verify Positions Cross-Chain
**Current**: Relayer verifies positions
**Required**:
- Send cross-chain message to hub chain
- Hub chain responds with position data
- Verify position before minting

**Reference**: `docs/02-architecture.md` hub-and-spoke flow

### 3. Frontend Should Use Bridge Kit Properly
**Current**: Not fully integrated
**Required**:
- Integrate Bridge Kit SDK for USDC transfers
- Use ethers.js for wallet connection
- Build custom UI (Bridge Kit has no UI components)
- Handle Bridge Kit status updates

**Reference**: `docs/RESEARCH-bridge-kit.md` for integration patterns

## Testing Requirements

### 1. Fix Existing Tests
- Fix access control test setup issues
- Resolve reentrancy guard false positives
- Ensure all tests pass

### 2. Add Integration Tests
- Test LayerZero message flow
- Test Hyperlane message flow
- Test Bridge Kit integration
- Test end-to-end deposit → mint → transfer flow

### 3. Add Fork Tests
- Test with real LayerZero endpoints (testnet)
- Test with real Hyperlane mailboxes (testnet)
- Test with real Bridge Kit contracts (testnet)

## Documentation Updates Needed

### 1. Update MVP-IMPLEMENTATION.md
- Document that trusted relayer was removed
- Update with proper LayerZero/Hyperlane implementation
- Update frontend stack (ethers.js instead of wagmi)

### 2. Create Deployment Guide
- Step-by-step deployment instructions
- Configuration for each chain
- LayerZero endpoint addresses
- Hyperlane mailbox addresses
- Bridge Kit contract addresses

### 3. Update Architecture Docs
- Remove references to trusted relayer
- Add LayerZero OApp architecture
- Add Hyperlane ISM architecture

## Code Quality Improvements

### 1. Gas Optimization
- Review all contracts for gas optimization opportunities
- Use packed structs where possible
- Optimize storage layout
- Minimize external calls

### 2. Security Review
- Review access control patterns
- Ensure proper reentrancy protection
- Verify input validation
- Check for overflow/underflow issues

### 3. Error Handling
- Improve error messages
- Add proper revert reasons
- Handle edge cases
- Add events for all state changes

## Priority Order

1. **HIGH**: Remove trusted relayer, implement LayerZero OApp
2. **HIGH**: Fix frontend to use ethers.js instead of wagmi
3. **MEDIUM**: Fix all test failures
4. **MEDIUM**: Add proper cross-chain verification
5. **LOW**: Gas optimization
6. **LOW**: Documentation updates

## Files Created/Modified Summary

### Smart Contracts
- ✅ Created: USDXToken.sol, USDXVault.sol, MockYieldVault.sol, MockUSDC.sol
- ⚠️ Needs Fix: CrossChainBridge.sol (remove relayer)
- ⚠️ Needs Fix: USDXSpokeMinter.sol (remove relayer)
- ❌ Missing: LayerZeroAdapter.sol, HyperlaneAdapter.sol

### Tests
- ✅ Created: Tests for all contracts
- ⚠️ Needs Fix: Some tests failing due to access control

### Frontend
- ✅ Created: Basic structure
- ❌ Needs Fix: Replace wagmi/RainbowKit with ethers.js
- ❌ Missing: Bridge Kit integration

### Scripts
- ✅ Created: Deployment script

## Resources

### Documentation
- `docs/02-architecture.md` - Complete architecture
- `docs/05-technical-specification.md` - Contract interfaces
- `docs/08-layerzero-research.md` - LayerZero integration
- `docs/19-hyperlane-deep-research.md` - Hyperlane integration
- `docs/RESEARCH-bridge-kit.md` - Bridge Kit integration

### External Docs
- LayerZero OApp: https://docs.layerzero.network/contracts/oapp
- Hyperlane: https://docs.hyperlane.xyz
- Bridge Kit: https://developers.circle.com/bridge-kit

## Notes

- Bridge Kit requires viem adapter (`@circle-fin/adapter-viem-v2`)
- Can use ethers.js for wallet + viem only for Bridge Kit
- LayerZero OApp is the recommended pattern (not basic LayerZero)
- Hyperlane uses ISM (Interchain Security Module) for verification
- All cross-chain operations should use proper protocols, not trusted relayers
