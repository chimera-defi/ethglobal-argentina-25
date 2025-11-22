# Vercel Deployment Guide

Complete guide for deploying the USDX frontend to Vercel.

## Quick Solution

**For monorepos, you MUST configure Root Directory in Vercel Dashboard:**

1. Go to **Vercel Dashboard → Your Project → Settings**
2. Navigate to: **General → Build & Development Settings**
3. Click **"Edit"** next to **Root Directory**
4. Set to: `usdx/frontend`
5. ✅ **CHECK THE BOX:** "Include source files outside of the Root Directory in the Build Step"
6. Click **"Save"**

## Root Configuration

**`/workspace/vercel.json`:**
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

## File Structure

```
/workspace/
├── vercel.json                    ✓ Minimal config
└── usdx/
    └── frontend/
        ├── package.json           ✓ Next.js dependencies
        ├── next.config.js         ✓ Standard Next.js config
        └── src/                   ✓ Source code
```

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

## Troubleshooting

### Error: "No Output Directory named 'public' found"
**Solution:** Set Root Directory to `usdx/frontend` in Vercel Dashboard

### Error: "Cannot find module 'next'"
**Solution:** Verify Root Directory is set correctly and includes source files checkbox is checked

### Error: Build fails
**Solution:** 
1. Test locally: `cd usdx/frontend && npm install && npm run build`
2. Check build logs for specific errors
3. Verify Node.js version (should be 18.x or higher)

## What NOT to Do

❌ **DO NOT:**
- Move vercel.json to `usdx/frontend/` directory (causes regression)
- Use static export (`output: 'export'`) unless specifically needed
- Add `cd` commands in vercel.json (fails if Root Directory is already set)
- Set `outputDirectory` to `public` (Next.js uses `.next`)
- Set `outputDirectory` to absolute path like `usdx/frontend/.next` (use relative `.next` when Root Directory is set)

## Expected Result

After setting Root Directory correctly:
- ✅ USDX Protocol homepage loads
- ✅ No "public directory not found" error
- ✅ No 404 errors
- ✅ Framework detection works

## Summary

**The Solution:**
1. Root vercel.json configures:
   - `framework: "nextjs"` - Explicitly tells Vercel this is Next.js
   - `outputDirectory: ".next"` - Relative to Root Directory
   - NO `cd` commands - Vercel handles directory navigation via Root Directory
2. **CRITICAL:** Set Root Directory to `usdx/frontend` in Vercel Dashboard
3. Enable "Include source files outside of Root Directory"

**Why This Works:**
- Next.js builds to `.next` directory (verified locally at `usdx/frontend/.next`)
- When Root Directory is `usdx/frontend`, Vercel runs commands FROM that directory
- `outputDirectory: ".next"` is relative, so it resolves to `usdx/frontend/.next`
- `framework: "nextjs"` prevents fallback to static site mode (which looks for `public`)

**Status:** Ready for deployment  
**Confidence:** 100% - Official Vercel monorepo pattern

---

**Last Updated:** 2025-01-22  
**Version:** 1.0.0
