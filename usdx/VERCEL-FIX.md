# Fix Vercel Build Error

## The Problem

Vercel is trying to run commands from the root directory, but your Next.js app is in the `frontend/` subdirectory.

## The Solution (Choose One)

### ✅ Option 1: Set Root Directory in Vercel Dashboard (Easiest)

1. Go to your Vercel project: https://vercel.com/dashboard
2. Click on your project
3. Go to **Settings** → **General**
4. Scroll down to **Root Directory**
5. Click **Edit**
6. Enter: `frontend`
7. Click **Save**
8. Go to **Deployments** tab
9. Click **Redeploy** on the latest deployment (or push a new commit)

**That's it!** Vercel will now:
- Use `frontend/vercel.json` automatically
- Run commands from the `frontend/` directory
- Build your Next.js app correctly

### Option 2: Use Root vercel.json (If Option 1 doesn't work)

If you can't set root directory, the root `vercel.json` is now empty `{}`, which tells Vercel to auto-detect. But **Option 1 is recommended**.

## Verify It Works

After setting root directory to `frontend`:

1. Check the build logs - should show:
   ```
   Installing dependencies...
   Running "npm install --legacy-peer-deps"
   Running "npm run build"
   ```

2. Build should complete successfully

3. Your site should be live!

## Still Having Issues?

Check the Vercel build logs for specific errors:
1. Go to **Deployments** tab
2. Click on the failed deployment
3. Check **Build Logs** for the exact error

Common issues:
- **Node version**: Set to Node.js 20+ in Settings → General → Node.js Version
- **Missing dependencies**: Check `frontend/package.json`
- **TypeScript errors**: Run `npm run type-check` locally first

## Quick Test Locally

Before deploying, verify it builds locally:

```bash
cd frontend
npm install --legacy-peer-deps
npm run build
```

If this works, it will work on Vercel with root directory set to `frontend`.
