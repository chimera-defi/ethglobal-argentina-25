# Fix: "Root Directory frontend does not exist" Error

## The Problem

Vercel says the `frontend` directory doesn't exist, but it does exist in your repository. This usually means:

1. **Vercel is looking at the wrong branch** - Check which branch Vercel is deploying
2. **Files aren't pushed to GitHub** - The vercel.json changes might not be committed/pushed
3. **Vercel cache** - Vercel might be using cached repository state

## The Solution

### Step 1: Verify Files Are Committed and Pushed

Make sure both `vercel.json` files are committed:

```bash
# Check if files are tracked
git ls-files | grep vercel.json

# If not, add and commit them
git add vercel.json frontend/vercel.json
git commit -m "Fix Vercel configuration"
git push
```

### Step 2: Check Vercel Branch Settings

1. Go to Vercel dashboard → Your project
2. Go to **Settings** → **Git**
3. Check **Production Branch** - should be `main` or `master`
4. Make sure you're pushing to that branch

### Step 3: Set Root Directory Correctly

**IMPORTANT**: After pushing the files:

1. Go to **Settings** → **General**
2. Scroll to **Root Directory**
3. Click **Edit**
4. **Clear the field** (leave empty) first
5. Click **Save**
6. Then click **Edit** again
7. Type: `frontend` (lowercase, no trailing slash)
8. Click **Save**

### Step 4: Trigger New Deployment

After setting root directory:

1. Go to **Deployments** tab
2. Click **Redeploy** on latest deployment
3. Or push a new commit to trigger deployment

## Alternative: Don't Use Root Directory

If setting root directory keeps failing, try this:

1. **Remove root directory setting** (leave empty)
2. **Move vercel.json to root** with proper paths:

```json
{
  "buildCommand": "cd frontend && npm install --legacy-peer-deps && npm run build",
  "outputDirectory": "frontend/.next",
  "installCommand": "cd frontend && npm install --legacy-peer-deps"
}
```

But this is less ideal - setting root directory is better.

## Verify Repository Structure

Make sure your GitHub repository has:
```
your-repo/
├── frontend/
│   ├── app/
│   ├── package.json
│   ├── next.config.js
│   └── vercel.json
├── contracts/
├── vercel.json (root)
└── ...
```

## Debug Steps

1. **Check Vercel build logs** - Look for what directory it's trying to use
2. **Check GitHub** - Verify `frontend/` directory exists in your repo
3. **Check branch** - Make sure Vercel is deploying the correct branch
4. **Clear Vercel cache** - In Settings → General → Clear Build Cache

## Most Likely Fix

The issue is probably that:
1. The `vercel.json` changes aren't pushed to GitHub yet
2. Or Vercel is deploying a branch that doesn't have the frontend directory

**Solution**: 
1. Commit and push all changes
2. Make sure Vercel is connected to the correct branch
3. Set root directory to `frontend` in Vercel dashboard
4. Redeploy
