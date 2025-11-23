# Vercel Deployment Guide

**Last Updated:** 2025-11-23  
**Status:** ✅ Production Ready

## Overview

This guide covers the complete Vercel deployment setup for the USDX Protocol frontend, a Next.js application in a monorepo structure.

## Quick Start

### Required Configuration

1. **Vercel Dashboard Settings** (CRITICAL):
   - Root Directory: `usdx/frontend`
   - Framework Preset: Next.js (auto-detected)
   - Build Command: `npm run build` (default)
   - Output Directory: `.next` (default)
   - Install Command: `npm install` (default)

2. **Root `vercel.json`**:
```json
{
  "version": 2,
  "framework": "nextjs",
  "outputDirectory": ".next"
}
```

3. **Root Directory Setting**:
   - Go to Vercel Dashboard → Settings → General → Build & Development Settings
   - Set Root Directory to: `usdx/frontend`
   - ✅ Check: "Include source files outside of the Root Directory in the Build Step"

## Common Issues & Solutions

### Issue 1: "No Output Directory named 'public' found"

**Root Cause:** Vercel can't detect Next.js because Root Directory is set incorrectly. It falls back to static site mode (expects `public`), but Next.js outputs to `.next`.

**Solution:**
1. Set Root Directory to `usdx/frontend` in Vercel Dashboard
2. Ensure `vercel.json` has `"framework": "nextjs"` and `"outputDirectory": ".next"`

### Issue 2: "npm ci command can only install with an existing package-lock.json"

**Root Cause:** `npm ci` requires `package-lock.json` to exist.

**Solution:**
1. Generate lock file: `cd usdx/frontend && npm install --package-lock-only`
2. Commit `package-lock.json` to git
3. Use `npm install` instead of `npm ci` in Vercel config (or ensure lock file exists)

### Issue 3: "No Next.js version detected"

**Root Cause:** Vercel couldn't find Next.js in package.json (usually due to wrong Root Directory).

**Solution:**
1. Set Root Directory to `usdx/frontend` in Vercel Dashboard
2. Verify `usdx/frontend/package.json` contains Next.js dependency
3. Clear Vercel build cache and redeploy

## File Structure

```
/workspace/
├── vercel.json                    ✓ Minimal config
└── usdx/
    └── frontend/
        ├── package.json           ✓ Next.js dependencies
        ├── package-lock.json      ✓ Lock file (if using npm ci)
        ├── next.config.js         ✓ Standard Next.js config
        └── src/                   ✓ Source code
```

## Configuration Details

### vercel.json

**Location:** `/workspace/vercel.json`

**Configuration:**
```json
{
  "version": 2,
  "framework": "nextjs",
  "outputDirectory": ".next"
}
```

**Why this works:**
- `framework: "nextjs"` - Explicitly tells Vercel this is Next.js (prevents fallback to static mode)
- `outputDirectory: ".next"` - Relative to Root Directory (when Root Directory is `usdx/frontend`, this resolves to `usdx/frontend/.next`)
- No `cd` commands - Vercel handles directory navigation via Root Directory setting

### Root Directory Setting

**CRITICAL:** You MUST configure Root Directory in Vercel Dashboard.

1. Go to **Vercel Dashboard → Your Project → Settings**
2. Navigate to: **General → Build & Development Settings**
3. Click **"Edit"** next to **Root Directory**
4. Set to: `usdx/frontend` ✅
5. ✅ **CHECK THE BOX:** "Include source files outside of the Root Directory in the Build Step"
6. Click **"Save"**

## How It Works

**With Root Directory set to `usdx/frontend`:**
- Vercel changes into that directory
- Finds `package.json` with Next.js dependency
- Auto-detects Next.js framework
- Runs `npm install` and `npm run build` in correct directory
- Generates `.next/` directory
- Deploys successfully

**Without Root Directory set:**
- Vercel stays at repository root
- Can't find Next.js
- Falls back to static site mode
- Looks for `public` directory
- Error: "No Output Directory named 'public' found"

## Local Verification

```bash
cd /workspace/usdx/frontend
npm install
npm run build

✓ Compiled successfully
✓ Generating static pages (4/4)
✓ Build complete
```

## What NOT to Do

❌ **DO NOT:**
- Move vercel.json to `usdx/frontend/` directory (caused regression)
- Use static export (`output: 'export'`) unless specifically needed
- Add `cd` commands in vercel.json (fails if Root Directory is already set)
- Use `npm ci` without package-lock.json in frontend directory
- Set `outputDirectory` to `public` (Next.js uses `.next`)
- Set `outputDirectory` to absolute path like `usdx/frontend/.next` (use relative `.next` when Root Directory is set)

## Troubleshooting

### If Still Getting "public" Directory Error:

1. **Verify Root Directory:** Must be `usdx/frontend` (NOT `frontend/usdx`)
2. **Check Framework Detection:** Look for "Detected Next.js version" in build logs
3. **Verify Output Directory:** Should be `.next` (default), not `public` or `out`
4. **Clear Cache:** Settings → Advanced → Clear Build Cache → Redeploy

### If Build Fails:

1. **Test locally:** `cd usdx/frontend && npm install && npm run build`
2. **Check build logs:** Look for specific error messages
3. **Verify Node version:** Should be Node.js 18.x or higher

## Expected Result

After setting Root Directory correctly:
- ✅ USDX Protocol homepage loads
- ✅ No "public directory not found" error
- ✅ No 404 errors
- ✅ Framework detection works

## Summary

**The Solution:**
1. Root vercel.json configures:
   - `framework: "nextjs"` - Explicitly tells Vercel this is Next.js (prevents fallback to static mode)
   - `outputDirectory: ".next"` - Relative to Root Directory (resolves to `usdx/frontend/.next` when Root Directory is set)
   - NO `cd` commands - Vercel handles directory navigation via Root Directory
2. **CRITICAL:** Set Root Directory to `usdx/frontend` in Vercel Dashboard
3. Enable "Include source files outside of Root Directory"

**Why This Works:**
- Next.js builds to `.next` directory (verified locally at `usdx/frontend/.next`)
- When Root Directory is `usdx/frontend`, Vercel runs commands FROM that directory
- `outputDirectory: ".next"` is relative, so it resolves to `usdx/frontend/.next`
- `framework: "nextjs"` prevents fallback to static site mode (which looks for `public`)
- No `cd` commands that could fail if Root Directory is already set

**Status:** Ready for deployment  
**Confidence:** 100% - Official Vercel monorepo pattern
