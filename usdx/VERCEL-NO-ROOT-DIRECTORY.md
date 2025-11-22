# Vercel Configuration - No Root Directory Setting

## Configuration

This setup works **without** setting Root Directory in Vercel dashboard.

### Root vercel.json

```json
{
  "buildCommand": "cd frontend && npm install --legacy-peer-deps && npm run build",
  "installCommand": "cd frontend && npm install --legacy-peer-deps"
}
```

**Key points**:
- No `outputDirectory` - Vercel auto-detects `.next` for Next.js apps
- Commands change directory to `frontend` before running
- Uses `--legacy-peer-deps` for dependency installation

### How It Works

1. Vercel runs from repository root
2. `installCommand` changes to `frontend/` and installs dependencies
3. `buildCommand` changes to `frontend/` and builds the Next.js app
4. Vercel auto-detects Next.js and serves from `frontend/.next`

## Setup Steps

1. **Make sure `vercel.json` is in repository root** ✅ (already done)
2. **Import repository in Vercel**
3. **Do NOT set Root Directory** - leave it empty/default
4. **Vercel will auto-detect Next.js** from the build output
5. **Deploy**

## Why This Works

- Vercel detects Next.js framework automatically from build output
- Next.js apps don't need explicit `outputDirectory` - Vercel handles it
- The `cd frontend` commands ensure we build in the right directory
- Vercel will serve the app from `frontend/.next` automatically

## Troubleshooting

### If build fails:
- Check build logs in Vercel
- Verify `frontend/package.json` exists
- Ensure Node.js version is 20+ (Settings → General → Node.js Version)

### If 404 persists:
- Check that build completed successfully
- Verify Next.js was detected (check build logs)
- Make sure `frontend/.next` directory was created during build

### Verify locally:
```bash
cd frontend
npm install --legacy-peer-deps
npm run build
# Should create .next directory
```

## Benefits

- ✅ No need to configure root directory in dashboard
- ✅ Works automatically
- ✅ Simpler setup
- ✅ Less configuration to maintain
