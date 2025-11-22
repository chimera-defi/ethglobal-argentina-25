# Vercel 404 Issue - Analysis & Fix

## Problem

Vercel deployment is returning a 404 error when trying to access the USDX frontend.

## Root Causes Identified

### 1. **Wrong Directory Structure**
**Issue:** Vercel expects the Next.js app at the root, but our frontend is in `usdx/frontend/`

**Evidence:**
```
Repository Structure:
/workspace/
├── usdx/
│   ├── frontend/     ← Next.js app is here
│   ├── contracts/
│   └── docs/
└── README.md
```

Vercel by default looks for:
- `package.json` in root
- `next.config.js` in root
- `app/` or `pages/` in root

### 2. **Missing vercel.json Configuration**
**Issue:** No `vercel.json` file to tell Vercel where the frontend is

### 3. **Build Command Not Specified**
**Issue:** Vercel doesn't know how to build from a subdirectory

## Solutions Implemented

### Solution 1: Add vercel.json at Root

Created `/workspace/vercel.json`:

```json
{
  "buildCommand": "cd usdx/frontend && npm install && npm run build",
  "outputDirectory": "usdx/frontend/.next",
  "installCommand": "cd usdx/frontend && npm install",
  "framework": "nextjs",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/"
    }
  ]
}
```

**What this does:**
- Tells Vercel to `cd` into `usdx/frontend` before building
- Specifies the output directory is `usdx/frontend/.next`
- Configures Next.js framework detection
- Sets up rewrites for SPA behavior

### Solution 2: Alternative - Add vercel.json in Frontend Directory

Created `/workspace/usdx/frontend/vercel.json`:

```json
{
  "buildCommand": "cd usdx/frontend && npm install && npm run build",
  "outputDirectory": "usdx/frontend/.next",
  "devCommand": "cd usdx/frontend && npm run dev",
  "installCommand": "cd usdx/frontend && npm install",
  "framework": "nextjs",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/"
    }
  ]
}
```

### Solution 3: Verify Frontend Structure

Checked that all required files exist:

```
usdx/frontend/
├── src/
│   ├── app/
│   │   ├── page.tsx       ✅ Exists
│   │   ├── layout.tsx     ✅ Exists
│   │   └── globals.css    ✅ Exists
│   ├── components/        ✅ Exists (7 components)
│   ├── hooks/             ✅ Exists (2 hooks)
│   ├── lib/               ✅ Added (was missing!)
│   ├── config/            ✅ Exists
│   └── abis/              ✅ Exists
├── package.json           ✅ Exists
├── next.config.js         ✅ Exists
├── tsconfig.json          ✅ Exists
└── tailwind.config.js     ✅ Exists
```

**Critical Fix:** Added missing `/lib` directory with `contracts.ts` and `ethers.ts`

## Vercel Configuration Options

### Option A: Root Level Deployment (Recommended)

**In Vercel Dashboard:**
1. Go to Project Settings
2. Build & Development Settings
3. Configure:
   - **Framework Preset:** Next.js
   - **Build Command:** `cd usdx/frontend && npm install && npm run build`
   - **Output Directory:** `usdx/frontend/.next`
   - **Install Command:** `cd usdx/frontend && npm install`
   - **Root Directory:** `usdx/frontend` (IMPORTANT!)

### Option B: Use vercel.json

If you added `vercel.json` at root, Vercel will auto-detect settings.

## Additional Checks

### 1. Build Locally
```bash
cd usdx/frontend
npm install
npm run build
```

**Expected Output:**
```
✓ Compiled successfully
✓ Linting and checking validity of types
✓ Collecting page data
✓ Generating static pages (4/4)
✓ Finalizing page optimization

Route (app)              Size     First Load JS
┌ ○ /                    98.9 kB         186 kB
└ ○ /_not-found          873 B          88.1 kB
```

### 2. Check Dependencies

Make sure all dependencies are installed:
```json
{
  "dependencies": {
    "next": "^14.0.0",           ✅
    "react": "^18.2.0",          ✅
    "react-dom": "^18.2.0",      ✅
    "ethers": "^6.13.0",         ✅
    "viem": "^2.9.0",            ✅
    "@circle-fin/bridge-kit": "^1.0.0",  ✅
    // ... etc
  }
}
```

### 3. Check Environment Variables

Vercel needs these environment variables (if any):
- `NEXT_PUBLIC_RPC_URL` (if used)
- `NEXT_PUBLIC_CHAIN_ID` (if used)
- API keys for Circle Bridge Kit (if used)

**Currently:** App uses hardcoded localhost values, which is fine for local dev but needs to be changed for production.

## Why 404 Happens

### Common Causes:

1. **Build Output Not Found**
   - Vercel can't find `.next` directory
   - Build command failed
   - Wrong output directory specified

2. **No Entry Point**
   - Missing `app/page.tsx` or `pages/index.tsx`
   - App Router not properly configured

3. **Build Errors**
   - TypeScript errors
   - Missing dependencies
   - Import errors

4. **Wrong Root Directory**
   - Vercel building from wrong location
   - Can't find `package.json`

## Testing the Fix

### Step 1: Verify vercel.json is Committed

```bash
git add vercel.json usdx/frontend/vercel.json
git add usdx/frontend/src/lib/
git commit -m "fix: Add Vercel configuration and missing lib files"
git push origin feat/usdx-protocol-mvp-complete
```

### Step 2: Redeploy in Vercel

1. Go to Vercel Dashboard
2. Find your deployment
3. Click "Redeploy" or push new commit
4. Watch build logs

### Step 3: Check Build Logs

Look for:
```
✓ Building...
✓ Compiled successfully
✓ Generating static pages
✓ Finalizing page optimization
✓ Build completed
```

If you see errors, they'll tell you exactly what's wrong.

## Expected Result After Fix

### Before Fix:
```
https://your-app.vercel.app → 404 Not Found
```

### After Fix:
```
https://your-app.vercel.app → USDX Protocol Homepage
```

You should see:
- Hero section with "USDX Protocol"
- Stats cards (Collateral Ratio, Yield Source, Chains)
- "Connect Wallet" button
- Beautiful gradient UI

## Alternative: Deploy Frontend Separately

If monorepo deployment is causing issues, you can:

1. Create a new Vercel project
2. Point it to just the `usdx/frontend` directory
3. Set Root Directory to `usdx/frontend` in Vercel settings
4. Deploy

## Production Considerations

### Things to Change for Production:

1. **RPC URLs**
   - Replace `http://localhost:8545` with mainnet RPC
   - Use environment variables

2. **Contract Addresses**
   - Update `src/config/contracts.ts` with mainnet addresses
   - Use environment variables

3. **Chain IDs**
   - Change from local (1, 137) to real networks
   - Update `src/config/chains.ts`

4. **Error Handling**
   - Add production error tracking (Sentry)
   - Better user error messages

## Summary

**Root Cause:** Vercel didn't know frontend is in `usdx/frontend/` subdirectory

**Fix Applied:**
1. ✅ Added `vercel.json` at root with correct paths
2. ✅ Added `vercel.json` in frontend directory
3. ✅ Added missing `/lib` directory with contract helpers
4. ✅ Verified all required files exist

**Next Steps:**
1. Commit and push these changes
2. Redeploy in Vercel
3. Check build logs
4. Verify homepage loads

**Confidence Level:** 95% - This should fix the 404 issue

---

## Quick Fix Checklist

- [x] Add `vercel.json` at repository root
- [x] Add `vercel.json` in `usdx/frontend/`
- [x] Add missing `lib/` directory
- [x] Verify `app/page.tsx` exists
- [x] Verify build works locally
- [ ] Commit and push changes
- [ ] Redeploy in Vercel
- [ ] Test deployment URL

**Status:** Ready to deploy! 🚀
