# Actual Vercel Fix - Step by Step

## The Real Problem

Vercel is showing 404 because:
1. The `outputDirectory` in `vercel.json` was wrong for Next.js
2. Next.js apps on Vercel don't need `outputDirectory` - Vercel handles it automatically
3. The root directory must be set to `frontend` in Vercel dashboard

## The Actual Fix

### Step 1: Update vercel.json (Already Done)

I've updated `frontend/vercel.json` to only include:
```json
{
  "installCommand": "npm install --legacy-peer-deps"
}
```

**Removed**:
- `buildCommand` - Vercel auto-detects `npm run build` for Next.js
- `outputDirectory` - Vercel handles this automatically for Next.js

### Step 2: Set Root Directory in Vercel Dashboard

**CRITICAL**: You MUST do this:

1. Go to https://vercel.com/dashboard
2. Click on your project
3. Go to **Settings** → **General**
4. Scroll to **Root Directory**
5. Click **Edit**
6. Type: `frontend`
7. Click **Save**

### Step 3: Redeploy

1. Go to **Deployments** tab
2. Click the **three dots** (⋯) on the latest deployment
3. Click **Redeploy**
4. Or push a new commit to trigger a new deployment

## Why This Works

- **Root Directory = `frontend`**: Tells Vercel where your Next.js app is
- **No outputDirectory**: Vercel automatically serves Next.js apps correctly
- **Install command**: Ensures dependencies install with `--legacy-peer-deps`

## Verify It's Fixed

After redeploying, check:
1. Build logs should show: "Installing dependencies..." then "Building..."
2. Build should complete successfully
3. The site should load (not 404)
4. You should see the USDX Protocol homepage

## If Still 404

Check the build logs:
1. Go to **Deployments** → Click on the deployment
2. Check **Build Logs**
3. Look for errors

Common issues:
- Root directory not set correctly
- Build failing (check logs)
- Node version wrong (should be 20+)

## Test Locally First

Before deploying, verify locally:
```bash
cd frontend
npm install --legacy-peer-deps
npm run build
npm start
# Visit http://localhost:3000
```

If this works locally, it will work on Vercel with root directory set to `frontend`.
