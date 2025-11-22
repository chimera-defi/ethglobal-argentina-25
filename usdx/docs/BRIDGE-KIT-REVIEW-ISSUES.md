# Bridge Kit Integration - Critical Issues Found

## Executive Summary

After thorough review, I found **critical API mismatches** between the documentation and the actual Bridge Kit implementation. The current integration code will **not work** as written. This document outlines all issues found and required fixes.

## Critical Issues

### 1. ❌ **API Mismatch - Wrong Function Names**

**Issue**: The code uses `createViemAdapter()` which doesn't exist.

**Actual API**: 
- `createAdapterFromProvider()` - for browser wallets
- `createAdapterFromPrivateKey()` - for private keys

**Location**: 
- `src/lib/bridgeKit.ts` line 2
- `src/hooks/useBridgeKit.ts` line 3

### 2. ❌ **API Mismatch - BridgeKit Constructor**

**Issue**: Code uses `new BridgeKit({ adapter })` but BridgeKit doesn't accept `adapter`.

**Actual API**: 
```typescript
new BridgeKit({ providers: [...] })
```

BridgeKit uses a provider-based architecture, not a direct adapter.

**Location**: 
- `src/lib/bridgeKit.ts` line 106
- `src/hooks/useBridgeKit.ts` lines 97, 159

### 3. ❌ **API Mismatch - Transfer Method**

**Issue**: Code calls `bridgeKit.transfer()` which doesn't exist.

**Actual API**: BridgeKit uses providers with a `bridge()` method:
```typescript
const result = await provider.bridge({
  source: walletContext,
  destination: destinationContext,
  amount: '1000000',
  token: 'USDC',
  config: {...}
})
```

**Location**: 
- `src/lib/bridgeKit.ts` line 120
- `src/hooks/useBridgeKit.ts` line 168

### 4. ❌ **API Mismatch - Status Tracking**

**Issue**: Code expects `onStatusUpdate` callback in transfer, but actual API uses event handlers.

**Actual API**: 
```typescript
kit.on('approve', (payload) => { ... })
kit.on('burn', (payload) => { ... })
kit.on('mint', (payload) => { ... })
```

**Location**: 
- `src/lib/bridgeKit.ts` lines 123-129
- `src/hooks/useBridgeKit.ts` lines 171-148

### 5. ⚠️ **Missing Wallet Context Creation**

**Issue**: Bridge Kit requires `WalletContext` objects created from adapters, not direct adapters.

**Actual Pattern**:
```typescript
const adapter = await createAdapterFromProvider({ provider: window.ethereum })
const walletContext = adapter.getWalletContext(chainDefinition)
```

### 6. ✅ **Fixed Issues**

- CONTRACTS export conflict in chains.ts - FIXED
- Chain name mismatch (Polygon vs Base Sepolia) - FIXED  
- Unused imports - FIXED
- Race condition in useBridgeKit hook - PARTIALLY FIXED (but needs complete rewrite)

## Required Changes

The Bridge Kit integration needs a **complete rewrite** to match the actual API. The current implementation follows outdated/incorrect documentation.

### Correct Implementation Pattern

```typescript
import { BridgeKit } from '@circle-fin/bridge-kit'
import { createAdapterFromProvider } from '@circle-fin/adapter-viem-v2'
import { sepolia, baseSepolia } from 'viem/chains'

// 1. Create adapter from browser wallet
const adapter = await createAdapterFromProvider({
  provider: window.ethereum
})

// 2. Create wallet contexts
const sourceContext = adapter.getWalletContext(sepolia)
const destContext = adapter.getWalletContext(baseSepolia)

// 3. Initialize BridgeKit (uses default CCTP provider)
const kit = new BridgeKit()

// 4. Set up event handlers
kit.on('approve', (payload) => console.log('Approving...'))
kit.on('burn', (payload) => console.log('Burning...'))
kit.on('mint', (payload) => console.log('Minting...'))

// 5. Get provider and bridge
const provider = kit.providers[0] // CCTP provider
const result = await provider.bridge({
  source: sourceContext,
  destination: destContext,
  amount: '1000000',
  token: 'USDC',
  config: {}
})
```

## TypeScript Compilation Errors

Current code has **12 TypeScript errors**:
1. `createViemAdapter` doesn't exist (2 errors)
2. `adapter` property doesn't exist in BridgeKitConfig (2 errors)
3. `transfer` method doesn't exist (2 errors)
4. Implicit `any` types in callbacks (4 errors)
5. `getTransferStatus` method doesn't exist (2 errors)

## Recommendations

### Option 1: Complete Rewrite (Recommended)
Rewrite the Bridge Kit integration to match the actual API. This is the correct approach but requires significant work.

### Option 2: Use Alternative Bridge
Consider using Circle's CCTP directly or another bridge solution if Bridge Kit's API is too complex for current needs.

### Option 3: Wait for Documentation Update
If Bridge Kit documentation is being updated, wait for corrected docs before implementing.

## Files That Need Complete Rewrite

1. `/frontend/src/lib/bridgeKit.ts` - Complete rewrite needed
2. `/frontend/src/hooks/useBridgeKit.ts` - Complete rewrite needed  
3. `/frontend/src/components/BridgeKitFlow.tsx` - May need updates after hook rewrite

## Testing Status

- ❌ TypeScript compilation: **FAILS** (12 errors)
- ❌ Runtime testing: **NOT TESTED** (code won't compile)
- ✅ Import resolution: **WORKS** (packages installed)
- ✅ Basic structure: **GOOD** (architecture is sound, just wrong API)

## Honest Assessment

**The current implementation will not work.** The API used in the code doesn't match the actual Bridge Kit API. This appears to be based on outdated or incorrect documentation.

**However**, the architecture and approach are sound - we just need to use the correct API methods. The fixes are straightforward but require rewriting the core integration code.

## Next Steps

1. **Immediate**: Rewrite `bridgeKit.ts` and `useBridgeKit.ts` to use correct API
2. **Testing**: Test with actual Bridge Kit on testnets
3. **Documentation**: Update integration docs with correct API usage
4. **Consider**: Whether Bridge Kit's complexity is worth it vs. direct CCTP integration
