# GitHub Actions Workflows

## Workflows

### 1. CI (`ci.yml`)

Runs on every push/PR:
- Tests smart contracts (Foundry)
- Builds frontend
- Type checks frontend
- Lints frontend

**Purpose**: Verify code quality before merging

### 2. Build Check (`deploy-frontend.yml`)

Runs on push to `main`:
- Builds frontend
- Verifies build succeeds
- Uploads build artifacts

**Purpose**: Ensure frontend builds successfully before deployment

**Note**: Actual deployment happens via Vercel/Netlify integration (simpler than GitHub Actions deployment)

## Setup

### For Vercel Deployment

1. Connect repository in Vercel dashboard
2. Vercel handles deployment automatically
3. GitHub Actions just verify builds succeed

### For Manual Deployment

Workflows verify builds succeed. Deploy manually using:
- Vercel CLI: `vercel`
- Netlify CLI: `netlify deploy`
- Or upload `.next` folder to your hosting provider

## Secrets (Optional)

Only needed if using GitHub Actions for deployment (not recommended - use Vercel instead):

- `VERCEL_TOKEN` - Vercel API token
- `VERCEL_ORG_ID` - Vercel organization ID
- `VERCEL_PROJECT_ID` - Vercel project ID
- `WALLETCONNECT_PROJECT_ID` - WalletConnect project ID (optional)

## Status Badges

Add to README.md:

```markdown
![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)
![Build](https://github.com/YOUR_REPO/actions/workflows/deploy-frontend.yml/badge.svg)
```
