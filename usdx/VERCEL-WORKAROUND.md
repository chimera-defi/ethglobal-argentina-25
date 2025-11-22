# Vercel Workaround - No Root Directory Setting

## The Problem

Vercel doesn't detect Next.js when it's in a subdirectory without root directory set. It also doesn't run install commands properly.

## The Solution

I've configured it so Vercel detects Next.js at the root level:

### Changes Made

1. **Root `package.json`** - Added Next.js dependencies so Vercel detects it
2. **Root `next.config.js`** - Added so Vercel knows it's Next.js
3. **Root `vercel.json`** - Uses `npm run build` which handles the subdirectory

### How It Works

1. Vercel sees `next` in root `package.json` → Detects Next.js ✅
2. Vercel sees `next.config.js` at root → Confirms Next.js ✅
3. `installCommand` installs dependencies in `frontend/`
4. `buildCommand` runs `npm run build` which calls frontend build
5. `outputDirectory` points to `frontend/.next`

## Files Changed

- ✅ `package.json` - Added Next.js deps for detection
- ✅ `next.config.js` - Added at root for detection
- ✅ `vercel.json` - Updated to use npm scripts

## Next Steps

1. **Commit and push**:
   ```bash
   git add package.json next.config.js vercel.json
   git commit -m "Configure Vercel to detect Next.js without root directory"
   git push
   ```

2. **Redeploy in Vercel**

3. **Check build logs** - Should now show:
   - "Detected Next.js"
   - Installing dependencies
   - Building successfully

## Why This Works

Vercel's detection looks for:
- ✅ `package.json` with `next` dependency (now at root)
- ✅ `next.config.js` (now at root)
- ✅ Framework detection works

But the actual build happens in `frontend/` via the npm scripts.

## If Still Not Working

If Vercel still doesn't detect it:
1. Check build logs - what does it say?
2. Verify `next` is in root `package.json`
3. Verify `next.config.js` exists at root
4. May need to actually install Next.js at root (not ideal but might be necessary)

Let me know what the build logs show!
