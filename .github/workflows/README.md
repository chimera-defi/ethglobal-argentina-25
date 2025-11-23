# GitHub Actions Workflows

## Workflows

### 1. CI (`ci.yml`)

Runs on every push/PR:
- Tests smart contracts (Foundry)

**Purpose**: Verify code quality before merging

## Setup

### For Vercel Deployment

1. Connect repository in Vercel dashboard
2. Vercel handles deployment automatically
3. GitHub Actions verify contracts build and test successfully

### For Manual Deployment

Workflows verify contracts build and test successfully. Deploy manually using:
- Foundry: `forge script`
- Hardhat: `npx hardhat deploy`
- Or use your preferred deployment tool

## Secrets (Optional)

Only needed if using GitHub Actions for deployment (not recommended - use Vercel instead):

- `VERCEL_TOKEN` - Vercel API token
- `VERCEL_ORG_ID` - Vercel organization ID
- `VERCEL_PROJECT_ID` - Vercel project ID

## Status Badges

Add to README.md:

```markdown
![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)
```
