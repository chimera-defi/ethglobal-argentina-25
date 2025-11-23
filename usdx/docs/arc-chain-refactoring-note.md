# Arc Chain Refactoring - Treating Arc as a Standard Spoke Chain

## Issue Identified

Arc was initially implemented as a separate chain type (`ARC`) when it should be treated as just another spoke chain, similar to Base Sepolia. The only difference is the internal verification mechanism (LayerZero vs oracle-based), not the architectural role.

## Changes Made

### Frontend Configuration (`chains.ts`)

**Before:**
```typescript
export const CHAINS = {
  HUB: { ... },
  SPOKE: { ... },  // Base Sepolia
  ARC: { ... },    // Arc Testnet - treated separately
}
```

**After:**
```typescript
export const CHAINS = {
  HUB: { ... },
  SPOKE_BASE: { ... },  // Base Sepolia - explicit spoke chain
  SPOKE_ARC: { ... },   // Arc Testnet - explicit spoke chain
}

// All spoke chains in one array
export const SPOKE_CHAINS = [
  CHAINS.SPOKE_BASE,
  CHAINS.SPOKE_ARC,
] as const;

// Legacy support for backward compatibility
export const SPOKE = CHAINS.SPOKE_BASE;
```

### Key Improvements

1. **Consistent Naming**: Both Base and Arc are now `SPOKE_*` chains
2. **SPOKE_CHAINS Array**: Makes it easy to iterate over all spoke chains
3. **isSpokeChain() Function**: Now uses the array, automatically includes all spoke chains
4. **Backward Compatibility**: Legacy `SPOKE` export maintained for existing code

## Why This Matters

### Architectural Clarity
- Arc is **not** a special case - it's just another spoke chain
- The difference is only in the **verification mechanism**:
  - Base Sepolia: Uses LayerZero + USDXShareOFT
  - Arc Testnet: Uses oracle-based verified positions
- Both serve the same purpose: Allow users to mint USDX using hub positions

### Code Maintainability
- Adding new spoke chains is now straightforward: just add to `SPOKE_CHAINS` array
- No need to update `isSpokeChain()` for each new chain
- Clear pattern for future spoke chains

### User Experience
- From a user perspective, both chains work the same way
- Users can mint USDX on either chain using their hub positions
- The internal verification mechanism is an implementation detail

## Files That May Need Updates

The following files may reference `CHAINS.SPOKE` or `CHAINS.ARC` and should be updated:

1. **Frontend Components**:
   - `BridgeKitFlow.tsx` - Uses `CHAINS.SPOKE` (has legacy support)
   - Any chain selector components
   - Any chain-specific UI components

2. **Contract Scripts**:
   - `DeploySpoke.s.sol` - Already handles Arc correctly
   - Other deployment scripts

3. **Documentation**:
   - Update references to clarify Arc is a spoke chain
   - Update architecture diagrams if needed

## Migration Path

### For Existing Code Using `CHAINS.SPOKE`
- **Option 1**: Use `CHAINS.SPOKE_BASE` (explicit)
- **Option 2**: Use legacy `SPOKE` export (backward compatible)
- **Option 3**: Use `SPOKE_CHAINS[0]` (if you need the first spoke)

### For New Code
- Use `SPOKE_CHAINS` array to iterate over all spoke chains
- Use `isSpokeChain(chainId)` to check if a chain is a spoke
- Use specific chain names (`SPOKE_BASE`, `SPOKE_ARC`) when you need a specific chain

## Example Usage

```typescript
// Check if chain is a spoke chain
if (isSpokeChain(chainId)) {
  // Handle spoke chain logic
}

// Iterate over all spoke chains
SPOKE_CHAINS.forEach(spoke => {
  console.log(`Spoke chain: ${spoke.name}`);
});

// Get specific chain
const baseChain = CHAINS.SPOKE_BASE;
const arcChain = CHAINS.SPOKE_ARC;

// Legacy support (backward compatible)
const oldSpoke = SPOKE; // Same as SPOKE_BASE
```

## Next Steps

1. ✅ Refactored `chains.ts` to treat Arc as a spoke chain
2. ⏳ Update components that reference `CHAINS.SPOKE` or `CHAINS.ARC`
3. ⏳ Update documentation to reflect this change
4. ⏳ Consider adding more spoke chains using the same pattern

---

**Date**: January 2025  
**Status**: Refactoring complete - Arc now treated as standard spoke chain
