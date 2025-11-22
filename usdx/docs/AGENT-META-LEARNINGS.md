# Agent Meta-Learnings: Critical Development Practices

## The Problem

An agent wrote Bridge Kit integration code that **wouldn't compile** because it used API methods that don't exist. The code was based on documentation that didn't match the actual implementation.

## Root Cause Analysis

### What Went Wrong

1. **Trusted Documentation Without Verification**
   - Read documentation in `docs/RESEARCH-bridge-kit.md`
   - Assumed documentation was accurate and up-to-date
   - Never verified against actual package type definitions
   - Wrote code using `createViemAdapter()`, `bridgeKit.transfer()`, etc. that don't exist

2. **No API Verification Step**
   - Should have checked `node_modules/@circle-fin/bridge-kit/index.d.ts` FIRST
   - Should have verified function signatures before writing code
   - Should have run `npm run type-check` immediately after writing code

3. **No Incremental Testing**
   - Wrote entire integration before testing
   - Should have written minimal test case first
   - Should have verified each function call individually

4. **Assumed Pattern Without Validation**
   - Saw examples in docs and assumed they were correct
   - Didn't verify the examples would actually work
   - Pattern matching without validation is dangerous

## Critical Rules for Future Agents

### Rule 1: ALWAYS Verify APIs Before Writing Code

**Before writing ANY code that uses an external library:**

1. **Check Type Definitions First**
   ```bash
   # Find the type definitions
   find node_modules -name "*.d.ts" -path "*@circle-fin*"
   
   # Read the actual API
   cat node_modules/@circle-fin/bridge-kit/index.d.ts | grep -E "export|class|interface"
   ```

2. **Verify Function Existence**
   ```bash
   # Check if function exists
   grep "createViemAdapter\|createAdapter" node_modules/@circle-fin/adapter-viem-v2/index.d.ts
   ```

3. **Check Constructor Signatures**
   ```bash
   # Verify constructor parameters
   grep -A 10 "constructor" node_modules/@circle-fin/bridge-kit/index.d.ts
   ```

4. **Verify Method Names**
   ```bash
   # Check available methods
   grep -E "^    [a-zA-Z]+\(|^    get [a-zA-Z]+" node_modules/@circle-fin/bridge-kit/index.d.ts
   ```

### Rule 2: Test Compilation IMMEDIATELY

**After writing ANY TypeScript code:**

```bash
# Run type check IMMEDIATELY
npm run type-check

# If it fails, FIX IT BEFORE continuing
# Do NOT write more code on top of broken code
```

**Never:**
- Write multiple files before testing
- Assume code will compile
- Continue if type-check fails

**Always:**
- Test after each file
- Fix errors immediately
- Verify imports resolve correctly

### Rule 3: Use Incremental Development

**Correct Approach:**

1. **Minimal Test First**
   ```typescript
   // test-api.ts - Verify API exists
   import { BridgeKit } from '@circle-fin/bridge-kit'
   const kit = new BridgeKit()
   // Does this compile? If not, check constructor signature
   ```

2. **Verify Each Step**
   ```typescript
   // Step 1: Can I import?
   // Step 2: Can I instantiate?
   // Step 3: Can I call methods?
   ```

3. **Build Up Gradually**
   - Don't write the full integration at once
   - Test each piece before moving on

### Rule 4: Question Documentation

**When reading documentation:**

1. **Check Publication Date** - Is it recent?
2. **Look for Version Mismatches** - Docs might be for different version
3. **Find Examples in Package** - Check if package has examples
4. **Verify Against Types** - Always cross-reference with `.d.ts` files
5. **Test Examples** - Copy example code and see if it compiles

**Red Flags:**
- Documentation shows methods that don't appear in type definitions
- Examples use different import paths
- Documentation seems simplified compared to actual API
- No version numbers or dates

### Rule 5: Multi-Pass Review Process

**Before considering code "done":**

**Pass 1: API Verification**
- [ ] Read actual type definitions
- [ ] Verify all imports exist
- [ ] Check function signatures match usage
- [ ] Verify constructor parameters

**Pass 2: Compilation Check**
- [ ] Run `npm run type-check`
- [ ] Fix ALL errors before continuing
- [ ] Verify no implicit `any` types
- [ ] Check all imports resolve

**Pass 3: Logic Review**
- [ ] Review business logic
- [ ] Check error handling
- [ ] Verify state management
- [ ] Review edge cases

**Pass 4: Integration Review**
- [ ] Check component props match
- [ ] Verify data flow
- [ ] Test component integration
- [ ] Check for prop drilling issues

**Pass 5: Final Verification**
- [ ] Run full type-check again
- [ ] Check for unused code
- [ ] Verify no console.logs left
- [ ] Review error messages

### Rule 6: When You Find API Mismatches

**If documentation doesn't match actual API:**

1. **STOP immediately** - Don't write more code
2. **Document the mismatch** - Create issue document
3. **Find correct API** - Read type definitions thoroughly
4. **Rewrite using correct API** - Start fresh with verified API
5. **Test incrementally** - Verify each piece works

**Never:**
- Continue with wrong API hoping it will work
- Write workarounds for API mismatches
- Assume the API will change to match docs

**Always:**
- Use the actual API as source of truth
- Update documentation if you find it's wrong
- Create clear notes about API differences

## The Correct Process (What Should Have Happened)

### Step 1: API Discovery
```bash
# 1. Install packages
npm install @circle-fin/bridge-kit @circle-fin/adapter-viem-v2

# 2. Find type definitions
find node_modules -name "*.d.ts" -path "*@circle-fin*"

# 3. Read actual API
cat node_modules/@circle-fin/bridge-kit/index.d.ts | head -200
cat node_modules/@circle-fin/adapter-viem-v2/index.d.ts | head -200

# 4. Verify exports
grep "^export" node_modules/@circle-fin/adapter-viem-v2/index.d.ts
```

### Step 2: Minimal Verification
```typescript
// verify-api.ts
import { BridgeKit } from '@circle-fin/bridge-kit'
import { createAdapterFromProvider } from '@circle-fin/adapter-viem-v2'

// Test 1: Can I import?
console.log('Imports work')

// Test 2: Can I create BridgeKit?
const kit = new BridgeKit()
console.log('BridgeKit created')

// Test 3: What methods exist?
console.log('Methods:', Object.getOwnPropertyNames(Object.getPrototypeOf(kit)))
```

### Step 3: Compile and Fix
```bash
# Run type check
npm run type-check

# If errors, fix them BEFORE writing more code
```

### Step 4: Build Integration Incrementally
```typescript
// Step 1: Create adapter (test this works)
const adapter = await createAdapterFromProvider({ provider: window.ethereum })

// Step 2: Create wallet context (test this works)
const context = adapter.getWalletContext(chain)

// Step 3: Use BridgeKit (test this works)
const kit = new BridgeKit()
const result = await kit.providers[0].bridge({...})
```

## Specific Lessons for Bridge Kit

### What the Actual API Looks Like

```typescript
// CORRECT: Create adapter
import { createAdapterFromProvider } from '@circle-fin/adapter-viem-v2'
const adapter = await createAdapterFromProvider({
  provider: window.ethereum,
  getPublicClient: (params) => createPublicClient({...})
})

// CORRECT: Create wallet context
const sourceContext = adapter.getWalletContext(sourceChain)
const destContext = adapter.getWalletContext(destChain)

// CORRECT: Initialize BridgeKit
const kit = new BridgeKit() // Uses default CCTP provider

// CORRECT: Bridge using provider
const provider = kit.providers[0] // CCTP provider
const result = await provider.bridge({
  source: sourceContext,
  destination: destContext,
  amount: '1000000',
  token: 'USDC',
  config: {}
})

// CORRECT: Event handlers
kit.on('approve', (payload) => {...})
kit.on('burn', (payload) => {...})
kit.on('mint', (payload) => {...})
```

### What Was Wrong

```typescript
// WRONG: Function doesn't exist
import { createViemAdapter } from '@circle-fin/adapter-viem-v2'

// WRONG: Constructor doesn't take adapter
const kit = new BridgeKit({ adapter })

// WRONG: Method doesn't exist
await kit.transfer({...})

// WRONG: Callback pattern doesn't exist
await kit.transfer({
  onStatusUpdate: (status) => {...}
})
```

## Checklist for Future Work

Before writing code using ANY external library:

- [ ] Read actual type definitions (`.d.ts` files)
- [ ] Verify all imports exist
- [ ] Check constructor signatures
- [ ] Verify method names and signatures
- [ ] Write minimal test case
- [ ] Run type-check immediately
- [ ] Fix all errors before continuing
- [ ] Build incrementally
- [ ] Test each step
- [ ] Question documentation if it seems off

## Final Thoughts

**The most important rule:** 

**The actual API (type definitions) is ALWAYS the source of truth. Documentation can be wrong, outdated, or for different versions. Always verify against `.d.ts` files.**

**Never trust documentation blindly. Always verify.**
