# Quick Deploy Guide - Get Your Site Live in 5 Minutes

## 🚀 Fastest Way: Vercel

### Step 1: Connect to Vercel (2 minutes)

1. Go to **[vercel.com](https://vercel.com)**
2. Click **"Sign Up"** → Sign in with **GitHub**
3. Click **"Add New Project"**
4. Select **this repository** from the list
5. Click **"Import"**

### Step 2: Configure (1 minute)

**IMPORTANT**: After importing, you MUST set the root directory:

1. Click **Settings** → **General**
2. Scroll to **Root Directory**
3. Click **Edit** → Enter: `frontend`
4. Click **Save**

Vercel will auto-detect Next.js! Verify:

- **Framework Preset**: Next.js ✅
- **Root Directory**: `frontend` ✅ (Set this in Settings!)
- **Build Command**: Auto-detected from `frontend/vercel.json` ✅
- **Output Directory**: Auto-detected as `.next` ✅

### Step 3: Deploy (2 minutes)

1. Click **"Deploy"**
2. Wait ~2 minutes for build
3. **Done!** You'll get a URL like: `https://usdx-protocol.vercel.app`

### Step 4: Test

1. Click the deployment URL
2. Click **"Connect Wallet"**
3. Connect MetaMask
4. **Success!** 🎉

## 🔄 Automatic Updates

**Every time you push to `main` branch:**
- Vercel automatically rebuilds
- New version goes live
- Old version stays available (for rollback)

**For Pull Requests:**
- Vercel creates preview deployments
- Each PR gets its own URL
- Test before merging!

## 📱 View Your Site

After deployment, you'll see:
- **Production URL**: `https://your-project.vercel.app`
- **Preview URLs**: For each PR

**Bookmark it!** Share it! Test it!

## 🐛 Troubleshooting

**Build fails?**
- Check Vercel build logs
- Ensure `package.json` has correct scripts
- Verify Node.js 20+ is selected

**Site doesn't load?**
- Check deployment status in Vercel dashboard
- Verify build succeeded
- Check browser console for errors

**Wallet doesn't work?**
- Ensure MetaMask is installed
- Check browser console for errors
- Try refreshing the page

## 🎯 Next Steps

1. ✅ Site is live!
2. ⏳ Deploy contracts to testnet
3. ⏳ Update contract addresses in Vercel environment variables
4. ⏳ Test full flow (deposit → mint → transfer)

## 💡 Pro Tips

- **Preview deployments**: Test changes before merging
- **Environment variables**: Set in Vercel dashboard (Settings → Environment Variables)
- **Custom domain**: Add your domain in Vercel settings
- **Analytics**: Enable Vercel Analytics for insights

---

**That's it!** Your site is live. Click the Vercel URL to see it! 🚀

For more details, see [DEPLOYMENT.md](./DEPLOYMENT.md)
