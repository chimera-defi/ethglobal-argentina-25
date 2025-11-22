# Vercel Deployment Setup

## Quick Fix for Build Errors

If you're getting build errors, follow these steps:

### Option 1: Set Root Directory in Vercel Dashboard (Recommended)

1. Go to your Vercel project dashboard
2. Click **Settings** → **General**
3. Scroll to **Root Directory**
4. Set it to: `frontend`
5. Click **Save**
6. Redeploy

This will use `frontend/vercel.json` automatically.

### Option 2: Use Root vercel.json (Current Setup)

The root `vercel.json` uses `--prefix frontend` to run commands in the frontend directory.

If this still fails, try Option 1 above.

## Troubleshooting

### Build Command Fails

**Error**: `Command "cd frontend && npm install..." exited with 1`

**Solution**: 
1. Set Root Directory to `frontend` in Vercel dashboard (Option 1 above)
2. Or check Vercel build logs for specific errors

### Common Issues

1. **Missing dependencies**: Check `frontend/package.json` has all required packages
2. **TypeScript errors**: Run `npm run type-check` locally first
3. **Node version**: Ensure Vercel uses Node.js 20+ (check in Settings → General)

## Verify Locally

Before deploying, test locally:

```bash
cd frontend
npm install --legacy-peer-deps
npm run build
```

If this works locally, it should work on Vercel with the correct root directory setting.
