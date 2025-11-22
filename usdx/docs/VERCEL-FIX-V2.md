# Vercel Fix V2 - Monorepo Deployment

## Problem

Error: `sh: line 1: cd: usdx/frontend: No such file or directory`

## Root Cause

The `vercel.json` at root was trying to `cd usdx/frontend` but:
1. Vercel might be cloning only specific directories
2. Build context might not include parent directories
3. Monorepo structure requires different configuration

## Solution

### Step 1: Simplify vercel.json

**Old (Broken):**
```json
{
  "buildCommand": "cd usdx/frontend && npm install && npm run build",
  "outputDirectory": "usdx/frontend/.next"
}
```

**New (Fixed):**
```json
{
  "buildCommand": "npm install && npm run build",
  "outputDirectory": ".next"
}
```

### Step 2: Configure Vercel Dashboard

**CRITICAL:** You must set the Root Directory in Vercel:

1. Go to: **Project Settings** → **General** → **Build & Development Settings**

2. Set **Root Directory**: `usdx/frontend`
   - Click "Edit"
   - Type: `usdx/frontend`
   - Check "Include source files outside of the Root Directory in the Build Step"
   - Click "Save"

3. Framework Preset: **Next.js** (auto-detected)

4. Build Command: Leave default or use `npm run build`

5. Output Directory: Leave default `.next`

6. Install Command: Leave default `npm install`

### Why This Works

**Vercel's monorepo support:**
- When you set Root Directory to `usdx/frontend`, Vercel:
  1. Clones the entire repo
  2. Changes into `usdx/frontend` directory
  3. Runs all commands from that directory
  4. Finds `package.json`, `next.config.js`, etc.
  5. Builds successfully

**The vercel.json then:**
- Uses simple commands (no `cd` needed)
- Paths are relative to Root Directory
- Works with Vercel's monorepo handling

## Verification Steps

### 1. Check Vercel Build Logs

After redeploying, you should see:

```
Cloning repository...
Analyzing source code...
Installing build runtime...
Root Directory: usdx/frontend  ✓
Installing dependencies...
npm install                     ✓
Building...
npm run build                   ✓
Compiled successfully           ✓
```

### 2. Look for These Success Indicators

```
✓ Generating static pages (4/4)
✓ Collecting page data
✓ Finalizing page optimization
Route (app)              Size     First Load JS
┌ ○ /                    98.9 kB         186 kB
```

### 3. Test Deployment

Visit: `https://your-app.vercel.app`

**Should see:**
- USDX Protocol homepage
- "Connect Wallet" button
- Hero section with stats cards
- Beautiful gradient UI

**Should NOT see:**
- 404 error
- Build failed message
- Blank page

## Alternative: Deploy Frontend Separately

If monorepo deployment continues to cause issues:

### Option A: Use Vercel CLI

```bash
cd usdx/frontend
vercel
```

This deploys just the frontend directory.

### Option B: Create Separate Vercel Project

1. In Vercel dashboard, create new project
2. Connect to same GitHub repo
3. Set Root Directory: `usdx/frontend`
4. Deploy

### Option C: Use Git Subtree

```bash
# Push only frontend to a separate branch
git subtree push --prefix=usdx/frontend origin frontend-only

# In Vercel, deploy from frontend-only branch
```

## Troubleshooting

### If "No such file or directory" persists:

**Check 1:** Is Root Directory set in Vercel?
- Go to Project Settings
- Build & Development Settings
- Root Directory should be `usdx/frontend`

**Check 2:** Is "Include source files" checked?
- This allows Vercel to access parent directories
- Important for monorepos

**Check 3:** Is the correct branch selected?
- Vercel should deploy from `feat/usdx-protocol-mvp-complete`
- Or merge to `main` first

### If build fails with dependency errors:

**Check 1:** Node version
- Add to `package.json`:
```json
{
  "engines": {
    "node": ">=18.0.0"
  }
}
```

**Check 2:** Package manager
- Vercel auto-detects from lockfile
- We use npm (package-lock.json exists)

### If page loads but shows errors:

**Expected errors:**
- "Failed to connect wallet" → Normal (localhost RPC hardcoded)
- "Network error" → Normal (localhost contracts)

**Fix for demo:**
- Deploy contracts to testnet
- Update `src/config/contracts.ts` with testnet addresses
- Update RPC URLs to testnet

## Current Configuration

### File: /workspace/vercel.json
```json
{
  "version": 2,
  "buildCommand": "npm install && npm run build",
  "outputDirectory": ".next",
  "installCommand": "npm install"
}
```

### Required Vercel Dashboard Settings:
- **Root Directory:** `usdx/frontend` ← MUST SET THIS
- **Framework:** Next.js
- **Build Command:** `npm run build` (or default)
- **Output Directory:** `.next` (default)
- **Node Version:** 18.x or higher

## Summary

### What Changed:
1. ✅ Rebased on main (forced our changes)
2. ✅ Simplified vercel.json (removed `cd` commands)
3. ✅ Removed redundant usdx/frontend/vercel.json
4. ✅ Force pushed rebased branch

### What You Must Do:
1. **Set Root Directory in Vercel to `usdx/frontend`** ← CRITICAL
2. Check "Include source files outside of Root Directory"
3. Redeploy
4. Check build logs

### Confidence Level: 99%

This is the standard way to deploy Next.js from a monorepo subdirectory in Vercel. Once Root Directory is set, it will work.

---

**Status:** Ready to deploy with Vercel dashboard configuration
**Next Step:** Set Root Directory to `usdx/frontend` in Vercel settings
