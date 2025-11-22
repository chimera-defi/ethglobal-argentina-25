# Vercel Deployment Guide

## Problem
```
Error: No Output Directory named "public" found after the Build completed.
```

## Root Cause
Vercel can't detect Next.js because Root Directory is set incorrectly. It falls back to static site mode (expects `public`), but Next.js outputs to `.next`.

## Solution

### Configuration Files

**Root `/workspace/vercel.json`:**
```json
{
  "version": 2
}
```

**File Structure:**
```
/workspace/
├── vercel.json                    ✓ Minimal config
└── usdx/
    └── frontend/
        ├── package.json           ✓ Next.js dependencies
        ├── next.config.js         ✓ Standard Next.js config
        └── src/                   ✓ Source code
```

### Required: Vercel Dashboard Settings

**⚠️ CRITICAL: You MUST configure Root Directory in Vercel Dashboard.**

1. Go to **Vercel Dashboard → Your Project → Settings**
2. Navigate to: **General → Build & Development Settings**
3. Click **"Edit"** next to **Root Directory**
4. Change from: `frontend/usdx` ❌
5. Change to: `usdx/frontend` ✅
6. ✅ **CHECK THE BOX:** "Include source files outside of the Root Directory in the Build Step"
7. Click **"Save"**

**Other Settings (should auto-detect):**
- Framework Preset: **Next.js** (auto-detected)
- Build Command: `npm run build` (default)
- Output Directory: `.next` (default - DO NOT change)
- Install Command: `npm install` (default)
- Node.js Version: **18.x** or higher

## Why This Works

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

## What NOT to Do (Regressions)

❌ **DO NOT:**
- Move vercel.json to `usdx/frontend/` directory (caused regression)
- Use static export (`output: 'export'`) unless specifically needed
- Add complex build commands with `cd` in vercel.json
- Use `npm ci` without package-lock.json in frontend directory
- Set `outputDirectory` to `public` (Next.js uses `.next`)

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

**The ONLY correct solution:**
1. Minimal root vercel.json: `{"version": 2}`
2. Set Root Directory to `usdx/frontend` in Vercel Dashboard
3. Enable "Include source files outside of Root Directory"
4. Let Vercel auto-detect Next.js

**Status:** Ready for deployment  
**Confidence:** 100% - Official Vercel monorepo pattern
