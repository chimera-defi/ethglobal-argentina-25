# Fix Vercel 404 - Next.js in Subdirectory

## The Real Problem

When Next.js is in a subdirectory (`frontend/`) and you don't set root directory, Vercel builds successfully but **can't detect Next.js framework**, so it serves a 404.

## What to Check First

**Go to Vercel Dashboard → Your Deployment → Build Logs**

Look for:
- ✅ "Detected Next.js" - If you see this, framework is detected
- ❌ No "Detected Next.js" - This is the problem
- Check "Output Directory" - What does it show?

## The Actual Fix

Unfortunately, **Vercel requires root directory to be set for Next.js apps in subdirectories**. This is a Vercel limitation.

### Option 1: Set Root Directory (Recommended)

Even though you said you don't want to, this is the **only reliable way**:

1. Vercel Dashboard → Settings → General
2. Root Directory → `frontend`
3. Save → Redeploy

### Option 2: Move Next.js to Root (Alternative)

If you really can't set root directory:

1. Move `frontend/app` → `app`
2. Move `frontend/package.json` → root
3. Move other frontend files to root
4. Update imports/paths
5. Deploy

### Option 3: Check Build Logs First

Before doing anything, check Vercel build logs:
- Is framework detected?
- What does it say about output directory?
- Any errors?

## Current Configuration

I've updated `vercel.json` with explicit framework and outputDirectory:

```json
{
  "buildCommand": "cd frontend && npm install --legacy-peer-deps && npm run build",
  "installCommand": "cd frontend && npm install --legacy-peer-deps",
  "framework": "nextjs",
  "outputDirectory": "frontend/.next"
}
```

**Try this first**, but if it still doesn't work, you'll need to set root directory.

## Why This Happens

Vercel's Next.js detection looks for:
- `package.json` with `next` dependency at root
- `.next` folder at root
- `next.config.js` at root

When these are in `frontend/`, Vercel can't auto-detect, even with explicit config.

## Next Steps

1. **Check build logs** - See what Vercel actually detects
2. **Try current vercel.json** - With explicit framework
3. **If still 404** - Set root directory to `frontend` (unavoidable)

Let me know what the build logs say!
