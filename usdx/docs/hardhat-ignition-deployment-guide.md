# Hardhat Ignition Deployment Guide

## Overview

This project uses **Hardhat Ignition** for multi-step contract deployments and local testnet setup. Hardhat Ignition provides:

- ✅ Automatic dependency management
- ✅ Resumable deployments
- ✅ Parameterized deployments
- ✅ Deployment state tracking
- ✅ Better error handling and rollback

## Quick Start

### Local Testnet Setup

The easiest way to get started is with the local testnet setup script:

```bash
npm run setup:local
```

This single command will:
1. Deploy all mock contracts (USDC, Yearn Vault, LayerZero Endpoint)
2. Deploy USDX contracts (Token and Vault)
3. Set up all permissions and configurations
4. Fund a user account with:
   - 10 ETH
   - 100,000 USDC
   - 50,000 USDX
5. Report all addresses and balances

### Manual Deployment

#### Deploy Mocks Only

```bash
npm run deploy:mocks sepolia
# or
npx hardhat ignition deploy ignition/modules/DeployMocks.ts --network sepolia
```

#### Deploy Hub Contracts

```bash
npm run deploy:hub sepolia
# or
npx hardhat ignition deploy ignition/modules/DeployHub.ts --network sepolia \
  --parameters '{"DeployHub":{"usdcAddress":"0x...","treasuryAddress":"0x..."}}'
```

#### Deploy Complete Local Setup

```bash
npm run deploy:local
# or
npx hardhat ignition deploy ignition/modules/LocalTestnetSetup.ts --network hardhat
```

## Ignition Modules

### 1. DeployMocks

Deploys mock contracts for testing:
- `MockUSDC` - Mock USDC token
- `MockYearnVault` - Mock Yearn vault
- `MockLayerZeroEndpoint` - Mock LayerZero endpoint

**Usage:**
```bash
npx hardhat ignition deploy ignition/modules/DeployMocks.ts --network hardhat
```

**Parameters:**
- `localEid` (default: 30101) - LayerZero endpoint ID

**Returns:**
- `mockUSDC` - MockUSDC contract address
- `mockYearnVault` - MockYearnVault contract address
- `mockLayerZeroEndpoint` - MockLayerZeroEndpoint contract address

### 2. DeployHub

Deploys USDX hub chain contracts:
- `USDXToken` - USDX token contract
- `USDXVault` - USDX vault contract

**Usage:**
```bash
npx hardhat ignition deploy ignition/modules/DeployHub.ts --network sepolia \
  --parameters '{
    "DeployHub": {
      "usdcAddress": "0x...",
      "treasuryAddress": "0x...",
      "yearnVaultAddress": "0x...",
      "lzEndpointAddress": "0x...",
      "localEid": 30101
    }
  }'
```

**Parameters:**
- `usdcAddress` (required) - USDC token address
- `treasuryAddress` (default: deployer) - Treasury address
- `yearnVaultAddress` (optional) - Yearn vault address
- `lzEndpointAddress` (optional) - LayerZero endpoint address
- `localEid` (default: 30101) - LayerZero endpoint ID

**Returns:**
- `usdxToken` - USDXToken contract address
- `usdxVault` - USDXVault contract address

**What it does:**
1. Deploys USDXToken
2. Deploys USDXVault
3. Grants MINTER_ROLE to vault
4. Grants BURNER_ROLE to vault
5. Sets LayerZero endpoint (if provided)
6. Sets Yearn vault (if provided)

### 3. LocalTestnetSetup

Complete local testnet setup with funding:

**Usage:**
```bash
npx hardhat ignition deploy ignition/modules/LocalTestnetSetup.ts --network hardhat \
  --parameters '{
    "LocalTestnetSetup": {
      "userAddress": "0x...",
      "ethAmount": "10000000000000000000",
      "usdcAmount": "100000000000",
      "usdxAmount": "50000000000",
      "localEid": 30101
    }
  }'
```

**Parameters:**
- `userAddress` (default: second account) - Address to fund
- `ethAmount` (default: 10 ETH) - Amount of ETH to send
- `usdcAmount` (default: 100,000 USDC) - Amount of USDC to mint
- `usdxAmount` (default: 50,000 USDX) - Amount of USDX to mint
- `localEid` (default: 30101) - LayerZero endpoint ID

**Returns:**
- `mockUSDC` - MockUSDC contract address
- `mockYearnVault` - MockYearnVault contract address
- `mockLayerZeroEndpoint` - MockLayerZeroEndpoint contract address
- `usdxToken` - USDXToken contract address
- `usdxVault` - USDXVault contract address
- `userAddress` - Funded user address

**What it does:**
1. Deploys all mock contracts
2. Deploys USDX contracts
3. Sets up permissions
4. Mints USDC to user
5. Mints USDX to user
6. Sets up LayerZero endpoint
7. Sets up Yearn vault

## Using the Setup Script

The `setup-local-testnet.ts` script provides a complete setup with reporting:

```bash
npm run setup:local
```

**Output includes:**
- All contract addresses
- User account address and balances
- Permission verification
- JSON summary of all addresses

**Example output:**
```
=== USDX Local Testnet Setup ===

Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
User: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

=== Deployment Summary ===

Mock Contracts:
  MockUSDC: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  MockYearnVault: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  MockLayerZeroEndpoint: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

USDX Contracts:
  USDXToken: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
  USDXVault: 0xDc64a140Aa3E981100a9becA8E57F7F8E8C2D3d0

=== User Account Funding ===

User Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
  ETH Balance: 10.0 ETH
  USDC Balance: 100000.0 USDC
  USDX Balance: 50000.0 USDX
```

## Deployment Workflow

### For Local Testing

1. **Quick Setup** (recommended):
   ```bash
   npm run setup:local
   ```

2. **Step-by-step**:
   ```bash
   # Deploy mocks
   npm run deploy:mocks hardhat
   
   # Deploy hub with mocks
   npm run deploy:hub hardhat --parameters '{"DeployHub":{"usdcAddress":"<from mocks>"}}'
   ```

### For Testnet Deployment

1. **Deploy mocks first** (if needed):
   ```bash
   npm run deploy:mocks sepolia
   ```

2. **Deploy hub contracts**:
   ```bash
   npm run deploy:hub sepolia --parameters '{
     "DeployHub": {
       "usdcAddress": "0x...",
       "treasuryAddress": "0x...",
       "yearnVaultAddress": "0x...",
       "lzEndpointAddress": "0x..."
     }
   }'
   ```

### For Mainnet Deployment

⚠️ **Use with caution!**

```bash
npm run deploy:hub mainnet --parameters '{
  "DeployHub": {
    "usdcAddress": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    "treasuryAddress": "0x...",
    "yearnVaultAddress": "0xBe53A109B494E5c9f97b9Cd39Fe969BE68BF6204",
    "lzEndpointAddress": "0x..."
  }
}'
```

## Resuming Deployments

Hardhat Ignition automatically tracks deployment state. If a deployment fails:

1. Fix the issue
2. Run the same command again
3. Ignition will resume from where it left off

Deployment state is stored in `ignition/deployments/`.

## Forking Mainnet

To test with mainnet forks:

1. Set `MAINNET_RPC_URL` in your `.env`:
   ```bash
   MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
   ```

2. Run setup with forking:
   ```bash
   npm run setup:local
   ```

The Hardhat network will automatically fork mainnet if `MAINNET_RPC_URL` is set.

## Customizing Funding Amounts

You can customize the amounts funded to the user:

```bash
npx hardhat ignition deploy ignition/modules/LocalTestnetSetup.ts --network hardhat \
  --parameters '{
    "LocalTestnetSetup": {
      "userAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "ethAmount": "20000000000000000000",
      "usdcAmount": "500000000000",
      "usdxAmount": "100000000000"
    }
  }'
```

## Troubleshooting

### Deployment Fails

1. Check network configuration in `hardhat.config.ts`
2. Verify environment variables are set
3. Check deployment logs for specific errors
4. Try resuming the deployment

### Contracts Not Found

Ensure contracts are compiled:
```bash
npm run compile
```

### Permission Errors

Verify that the deployer account has the necessary permissions and sufficient balance.

### Network Issues

- Check RPC URL is correct
- Verify network is accessible
- For local networks, ensure Hardhat node is running

## Best Practices

1. **Always test locally first**: Use `npm run setup:local` before deploying to testnets
2. **Use parameters**: Don't hardcode addresses, use parameters for flexibility
3. **Verify deployments**: Check all addresses and permissions after deployment
4. **Save addresses**: Keep a record of deployed addresses for reference
5. **Use version control**: Commit deployment state for reproducibility

## Comparison: Ignition vs Foundry Scripts

| Feature | Hardhat Ignition | Foundry Scripts |
|---------|------------------|-----------------|
| Dependency Management | ✅ Automatic | Manual |
| Resumable Deployments | ✅ Yes | ❌ No |
| State Tracking | ✅ Yes | ❌ No |
| TypeScript Support | ✅ Yes | ❌ No |
| Solidity Scripts | ❌ No | ✅ Yes |
| Gas Estimation | ✅ Yes | ✅ Yes |
| Verification | ✅ Built-in | Via plugins |

**Recommendation**: Use Hardhat Ignition for complex multi-step deployments, Foundry Scripts for simple deployments or when you prefer Solidity.

## Next Steps

1. ✅ Set up local testnet: `npm run setup:local`
2. ✅ Test contracts with funded account
3. ✅ Deploy to testnet when ready
4. ✅ Verify contracts on Etherscan
5. ✅ Deploy to mainnet (when ready)

## Resources

- [Hardhat Ignition Documentation](https://hardhat.org/ignition/docs)
- [Hardhat Ignition API Reference](https://hardhat.org/ignition/docs/reference/api)
- [Deployment Best Practices](https://hardhat.org/ignition/docs/guides/deployment-best-practices)
