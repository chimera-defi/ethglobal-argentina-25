# USDX Protocol - Deployment Guide

## 🚀 Quick Start - View Live Website

### Option 1: Vercel (Recommended - Easiest)

**One-Time Setup** (5 minutes):

1. **Go to [vercel.com](https://vercel.com)** and sign in with GitHub
2. **Click "Add New Project"**
3. **Import this repository** from GitHub
4. **Configure project**:
   - Framework Preset: **Next.js**
   - Root Directory: **`frontend`**
   - Build Command: `npm install --legacy-peer-deps && npm run build`
   - Output Directory: `.next`
   - Install Command: `npm install --legacy-peer-deps`
5. **Click "Deploy"**

**That's it!** Vercel will:
- Automatically deploy on every push to `main`
- Give you a URL like: `https://usdx-protocol.vercel.app`
- Update automatically on every commit

**Environment Variables** (Optional - add in Vercel dashboard):
```
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

### Option 2: Netlify

1. Go to [netlify.com](https://netlify.com) and sign in with GitHub
2. Click "Add new site" → "Import an existing project"
3. Select this repository
4. Configure:
   - Base directory: `frontend`
   - Build command: `npm install --legacy-peer-deps && npm run build`
   - Publish directory: `frontend/.next`
5. Deploy!

### Option 3: GitHub Pages (Static Export)

For static hosting, update `next.config.js`:
```js
output: 'export'
```

Then deploy the `out` folder to GitHub Pages.

## 📋 Local Development Setup

### Prerequisites

- **Node.js 20+** installed ([download](https://nodejs.org/))
- **MetaMask** browser extension ([download](https://metamask.io/))

### Step 1: Install Dependencies

```bash
cd frontend
npm install --legacy-peer-deps
```

### Step 2: Configure Environment (Optional)

Create `frontend/.env.local`:

```env
# Optional: WalletConnect Project ID
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id

# Contract addresses (update after deployment)
NEXT_PUBLIC_USDX_TOKEN_ADDRESS=0x...
NEXT_PUBLIC_USDX_VAULT_ADDRESS=0x...
NEXT_PUBLIC_USDC_ADDRESS=0x...
```

### Step 3: Run Development Server

```bash
npm run dev
```

Visit **[http://localhost:3000](http://localhost:3000)**

### Step 4: Connect Wallet

1. Click **"Connect Wallet"** button
2. Select **MetaMask** (or your preferred wallet)
3. Approve connection
4. You should see your wallet address in the header

## 🔧 Build Commands

```bash
# Development
npm run dev          # Start dev server (http://localhost:3000)

# Production
npm run build        # Build for production
npm start            # Start production server

# Quality
npm run lint         # Run ESLint
npm run type-check   # TypeScript type checking
```

## 🌐 Deployment Platforms

### Vercel (Recommended)

**Why Vercel?**
- ✅ Best Next.js support
- ✅ Automatic deployments
- ✅ Free tier
- ✅ Easy setup

**Setup**:
1. Connect GitHub repo in Vercel dashboard
2. Vercel auto-detects Next.js
3. Deploy!

**Automatic Deployments**:
- Every push to `main` → Production
- Every PR → Preview deployment

### Netlify

**Setup**:
1. Connect GitHub repo
2. Configure build:
   - Build command: `cd frontend && npm install --legacy-peer-deps && npm run build`
   - Publish directory: `frontend/.next`
3. Deploy!

### AWS Amplify

**Setup**:
1. Connect repository in AWS Amplify console
2. Configure build settings (see `amplify.yml` example below)
3. Deploy!

**amplify.yml**:
```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - cd frontend
        - npm install --legacy-peer-deps
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: frontend/.next
    files:
      - '**/*'
  cache:
    paths:
      - frontend/node_modules/**/*
```

## 🔄 CI/CD Pipeline

### GitHub Actions

Two workflows are configured:

1. **CI** (`.github/workflows/ci.yml`):
   - Runs on every push/PR
   - Tests smart contracts (Foundry)
   - Tests frontend build
   - No deployment

2. **Build Check** (`.github/workflows/deploy-frontend.yml`):
   - Runs on push to `main`
   - Builds frontend
   - Verifies build succeeds
   - Uploads artifacts

**Note**: Actual deployment happens via Vercel/Netlify integration, not GitHub Actions (simpler setup).

### Manual Deployment

If you prefer manual deployment:

```bash
cd frontend
npm install --legacy-peer-deps
npm run build
# Deploy .next folder to your hosting provider
```

## 📝 Environment Variables

### Required
None required for MVP (uses demo values)

### Optional

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` | WalletConnect project ID | No (uses demo) |
| `NEXT_PUBLIC_USDX_TOKEN_ADDRESS` | Deployed USDX token | No (mock addresses) |
| `NEXT_PUBLIC_USDX_VAULT_ADDRESS` | Deployed vault address | No (mock addresses) |
| `NEXT_PUBLIC_USDC_ADDRESS` | USDC token address | No (mock addresses) |

### Getting WalletConnect Project ID

1. Go to [cloud.walletconnect.com](https://cloud.walletconnect.com)
2. Create account
3. Create new project
4. Copy Project ID
5. Add to environment variables

## 🐛 Troubleshooting

### Build Fails

**Error**: `Cannot find module 'ethers'`
```bash
cd frontend
npm install --legacy-peer-deps
```

**Error**: TypeScript errors
```bash
npm run type-check
# Fix errors shown
```

**Error**: Build fails in CI
- Check GitHub Actions logs
- Ensure Node.js 20+ is used
- Verify `package-lock.json` is committed

### Wallet Connection Issues

**Error**: "MetaMask not installed"
- Install MetaMask browser extension
- Refresh page

**Error**: "User rejected request"
- User needs to approve connection in MetaMask
- Try again

**Error**: Wrong network
- Switch to correct network in MetaMask
- Or add network configuration

### Deployment Issues

**Vercel build fails**:
- Check build logs in Vercel dashboard
- Ensure `package.json` has correct scripts
- Verify Node.js version (should be 20+)
- Check environment variables

**GitHub Actions fails**:
- Check workflow logs
- Verify Node.js version
- Check for dependency issues

## 🔗 Quick Links

- **Local Dev**: [http://localhost:3000](http://localhost:3000) (after `npm run dev`)
- **Vercel Dashboard**: https://vercel.com/dashboard
- **GitHub Actions**: https://github.com/YOUR_REPO/actions
- **WalletConnect**: https://cloud.walletconnect.com

## 📚 Next Steps After Deployment

1. ✅ Website deployed and accessible
2. ⏳ Update contract addresses in environment variables
3. ⏳ Test wallet connection
4. ⏳ Test deposit flow (once contracts deployed)
5. ⏳ Test mint flow (once contracts deployed)
6. ⏳ Test transfer flow (once contracts deployed)

## 🎯 Deployment Checklist

- [ ] Repository pushed to GitHub
- [ ] Vercel/Netlify connected to repository
- [ ] Build succeeds (check logs)
- [ ] Website accessible via URL
- [ ] Wallet connection works
- [ ] Environment variables set (if needed)
- [ ] Contract addresses updated (after deployment)

## 💡 Tips

1. **Use Vercel** - Easiest for Next.js, automatic deployments
2. **Check build logs** - If deployment fails, check logs first
3. **Test locally first** - Run `npm run build` locally before deploying
4. **Environment variables** - Set in hosting provider dashboard, not in code
5. **Preview deployments** - Vercel/Netlify create preview URLs for PRs

## 🆘 Getting Help

- **Build issues**: Check `DEPLOYMENT.md` troubleshooting section
- **Wallet issues**: Ensure MetaMask is installed
- **Deployment issues**: Check hosting provider logs
- **Architecture questions**: See `docs/02-architecture.md`

---

**Ready to deploy?** Follow Option 1 (Vercel) above - it's the fastest way to get your site live! 🚀
