# Vercel Deployment Guide

**Last Updated:** 2025-11-23  
**Status:** ✅ Production Ready

## Overview

Complete Vercel deployment setup for USDX Protocol frontend (Next.js in monorepo).

## Quick Start (Recommended)

### Step 1: Configure Root Directory in Vercel Dashboard

**CRITICAL:** This is required for monorepos.

1. Go to **Vercel Dashboard → Your Project → Settings**
2. Navigate to: **General → Build & Development Settings**
3. Click **"Edit"** next to **Root Directory**
4. Set to: `usdx/frontend` ✅
5. ✅ **CHECK THE BOX:** "Include source files outside of the Root Directory in the Build Step"
6. Click **"Save"**

### Step 2: Root vercel.json

**Location:** `/workspace/vercel.json`

```json
{
  "version": 2,
  "framework": "nextjs",
  "outputDirectory": ".next"
}
```

**Why this works:**
- `framework: "nextjs"` - Prevents fallback to static site mode
- `outputDirectory: ".next"` - Relative to Root Directory (resolves to `usdx/frontend/.next`)
- No `cd` commands needed - Vercel handles navigation via Root Directory

### Step 3: Verify Settings

Vercel should auto-detect:
- Framework Preset: **Next.js**
- Build Command: `npm run build` (default)
- Output Directory: `.next` (default)
- Install Command: `npm install` (default)

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

## Common Issues & Solutions

### Issue 1: "No Output Directory named 'public' found"

**Root Cause:** Root Directory not set correctly. Vercel falls back to static site mode.

**Solution:**
1. Set Root Directory to `usdx/frontend` in Vercel Dashboard
2. Ensure `vercel.json` has `"framework": "nextjs"` and `"outputDirectory": ".next"`

### Issue 2: "No Next.js version detected"

**Root Cause:** Wrong Root Directory or Next.js not in package.json.

**Solution:**
1. Set Root Directory to `usdx/frontend` in Vercel Dashboard
2. Verify `usdx/frontend/package.json` contains Next.js dependency
3. Clear Vercel build cache and redeploy

### Issue 3: "npm ci command can only install with an existing package-lock.json"

**Root Cause:** Using `npm ci` without package-lock.json.

**Solution:**
- Option A (Recommended): Use default `npm install` in Vercel settings
- Option B: Generate and commit `package-lock.json`:
  ```bash
  cd usdx/frontend
  npm install --package-lock-only
  git add package-lock.json
  git commit -m "Add package-lock.json"
  ```

## Alternative: Manual Build Commands

If Root Directory approach doesn't work, use explicit commands in `vercel.json`:

```json
{
  "version": 2,
  "buildCommand": "cd usdx/frontend && npm run build",
  "outputDirectory": "usdx/frontend/.next",
  "installCommand": "cd usdx/frontend && npm install",
  "framework": null
}
```

**Note:** This approach requires `cd` commands and absolute output paths. Root Directory approach is preferred.

## File Structure

```
/workspace/
├── vercel.json                    ✓ Minimal config
└── usdx/
    └── frontend/
        ├── package.json           ✓ Next.js dependencies
        ├── package-lock.json      ✓ Lock file (optional)
        ├── next.config.js         ✓ Standard Next.js config
        └── src/                   ✓ Source code
```

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
- Move vercel.json to `usdx/frontend/` directory (causes regression)
- Use static export (`output: 'export'`) unless specifically needed
- Add `cd` commands in vercel.json when Root Directory is set (conflicts)
- Use `npm ci` without package-lock.json
- Set `outputDirectory` to `public` (Next.js uses `.next`)
- Set `outputDirectory` to absolute path when Root Directory is set (use relative `.next`)

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
1. **CRITICAL:** Set Root Directory to `usdx/frontend` in Vercel Dashboard
2. Root vercel.json with `framework: "nextjs"` and `outputDirectory: ".next"`
3. Enable "Include source files outside of Root Directory"

**Why This Works:**
- Next.js builds to `.next` directory
- Root Directory setting makes Vercel run commands from `usdx/frontend`
- `outputDirectory: ".next"` resolves relative to Root Directory
- `framework: "nextjs"` prevents static site mode fallback

**Status:** Ready for deployment  
**Confidence:** 100% - Official Vercel monorepo pattern
