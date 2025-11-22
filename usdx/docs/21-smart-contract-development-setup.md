# Smart Contract Development Setup

## Development Tools

### Primary Framework: Foundry (Forge)

**Why Foundry?**
- Fast compilation and testing
- Built-in fuzzing
- Gas optimization tools
- Mainnet forking support
- Solidity-native testing

**Installation**:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Secondary Framework: Hardhat

**Why Hardhat?**
- Mature ecosystem
- Extensive plugins
- Better TypeScript support
- Deployment scripts
- Debugging tools

**Installation**:
```bash
npm install --save-dev hardhat
npx hardhat init
```

### Recommended Approach: Dual Setup

Use **Foundry for testing** (faster, better for fuzzing) and **Hardhat for deployment** (better scripts and tooling).

## Project Structure

```
usdx-contracts/
├── contracts/
│   ├── core/
│   │   ├── USDXToken.sol
│   │   ├── USDXVault.sol
│   │   ├── USDXSpokeMinter.sol
│   │   └── CrossChainBridge.sol
│   ├── adapters/
│   │   ├── LayerZeroAdapter.sol
│   │   └── HyperlaneAdapter.sol
│   └── interfaces/
│       ├── IUSDXToken.sol
│       ├── IUSDXVault.sol
│       ├── IOVault.sol
│       └── IYieldRoutes.sol
├── test/
│   ├── forge/
│   │   ├── USDXToken.t.sol
│   │   ├── USDXVault.t.sol
│   │   └── CrossChainBridge.t.sol
│   └── hardhat/
│       └── integration/
│           └── end-to-end.test.ts
├── script/
│   ├── deploy/
│   │   ├── DeployUSDXToken.s.sol (Foundry)
│   │   └── deploy.ts (Hardhat)
│   └── fork/
│       └── fork-test.ts
├── foundry.toml
├── hardhat.config.ts
└── package.json
```

## Foundry Configuration

### `foundry.toml`

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
test = "test/forge"
script = "script"
broadcast = "broadcast"
gas_limit = "9223372036854775807"
gas_price = 0
optimizer = true
optimizer_runs = 200
via_ir = false
evm_version = "paris"
remappings = [
    "@openzeppelin/=lib/openzeppelin-contracts/",
    "@layerzero/=lib/layerzero-contracts/",
    "@hyperlane/=lib/hyperlane-contracts/",
    "@circle/=lib/circle-contracts/",
]

[profile.ci]
fuzz = { runs = 10000 }
invariant = { runs = 1000 }

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
sepolia = "${SEPOLIA_RPC_URL}"
polygon = "${POLYGON_RPC_URL}"
arbitrum = "${ARBITRUM_RPC_URL}"
optimism = "${OPTIMISM_RPC_URL}"
base = "${BASE_RPC_URL}"
```

## Hardhat Configuration

### `hardhat.config.ts`

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "hardhat-gas-reporter";
import "solidity-coverage";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: false,
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.MAINNET_RPC_URL || "",
        enabled: true,
        blockNumber: undefined, // Use latest block
      },
      chainId: 31337,
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111,
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 137,
    },
    arbitrum: {
      url: process.env.ARBITRUM_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 42161,
    },
    optimism: {
      url: process.env.OPTIMISM_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 10,
    },
    base: {
      url: process.env.BASE_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 8453,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      arbitrum: process.env.ARBISCAN_API_KEY || "",
      optimism: process.env.OPTIMISTIC_ETHERSCAN_API_KEY || "",
      base: process.env.BASESCAN_API_KEY || "",
    },
  },
  mocha: {
    timeout: 40000,
  },
};

export default config;
```

## Mainnet Forking Setup

### Why Fork Mainnet?

1. **Test with real contracts**: Test against actual deployed contracts (Yearn, OVault, Yield Routes)
2. **Real data**: Use real token balances, prices, and state
3. **Integration testing**: Test integrations with external protocols
4. **Gas estimation**: More accurate gas estimates
5. **Security**: Test against real-world conditions

### Foundry Forking

#### Basic Fork Test

```solidity
// test/forge/ForkTest.t.sol
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/core/USDXVault.sol";

contract ForkTest is Test {
    USDXVault vault;
    address constant MAINNET_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant MAINNET_YEARN_VAULT = 0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9;
    
    function setUp() public {
        // Fork mainnet at latest block
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        
        // Deploy vault
        vault = new USDXVault(
            MAINNET_USDC,
            MAINNET_YEARN_VAULT
        );
    }
    
    function testDepositWithRealUSDC() public {
        // Get some USDC from mainnet
        deal(MAINNET_USDC, address(this), 1000e6);
        
        // Approve vault
        IERC20(MAINNET_USDC).approve(address(vault), 1000e6);
        
        // Deposit
        uint256 usdxAmount = vault.depositUSDC(1000e6);
        
        assertEq(usdxAmount, 1000e6);
    }
}
```

#### Run Fork Tests

```bash
# Fork mainnet and run tests
forge test --fork-url $MAINNET_RPC_URL

# Fork at specific block
forge test --fork-url $MAINNET_RPC_URL --fork-block-number 18000000

# Fork multiple chains
forge test --fork-url $MAINNET_RPC_URL --fork-url $POLYGON_RPC_URL
```

### Hardhat Forking

#### Fork Configuration

```typescript
// hardhat.config.ts
networks: {
  hardhat: {
    forking: {
      url: process.env.MAINNET_RPC_URL || "",
      enabled: true,
      blockNumber: undefined, // Use latest block
    },
  },
}
```

#### Fork Test Example

```typescript
// test/hardhat/fork/vault-fork.test.ts
import { expect } from "chai";
import { ethers } from "hardhat";
import { USDXVault } from "../../typechain-types";

describe("USDXVault Fork Tests", function () {
  let vault: USDXVault;
  const MAINNET_USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const MAINNET_YEARN_VAULT = "0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9";
  
  beforeEach(async function () {
    // Hardhat automatically forks when forking is enabled
    const USDXVaultFactory = await ethers.getContractFactory("USDXVault");
    vault = await USDXVaultFactory.deploy(
      MAINNET_USDC,
      MAINNET_YEARN_VAULT
    );
    await vault.waitForDeployment();
  });
  
  it("Should deposit USDC on forked mainnet", async function () {
    const [user] = await ethers.getSigners();
    const usdcAmount = ethers.parseUnits("1000", 6);
    
    // Get USDC from mainnet
    const usdc = await ethers.getContractAt("IERC20", MAINNET_USDC);
    await network.provider.send("hardhat_impersonateAccount", [
      "0x...", // Some account with USDC
    ]);
    const whale = await ethers.getSigner("0x...");
    await usdc.connect(whale).transfer(user.address, usdcAmount);
    
    // Approve and deposit
    await usdc.approve(await vault.getAddress(), usdcAmount);
    await vault.depositUSDC(usdcAmount);
    
    // Verify deposit
    const balance = await vault.getUserOVaultShares(user.address);
    expect(balance).to.be.gt(0);
  });
});
```

#### Run Fork Tests

```bash
# Run tests with forking enabled
npx hardhat test test/hardhat/fork/

# Fork at specific block
# Update hardhat.config.ts fork blockNumber
npx hardhat test test/hardhat/fork/
```

## Testing Strategy

### Unit Tests (Foundry)

**Location**: `test/forge/`

**Coverage**: 90%+ for all contracts

**Example**:
```solidity
// test/forge/USDXToken.t.sol
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/USDXToken.sol";

contract USDXTokenTest is Test {
    USDXToken token;
    address vault;
    address user;
    
    function setUp() public {
        vault = address(0x1);
        user = address(0x2);
        token = new USDXToken(vault);
    }
    
    function testMint() public {
        vm.prank(vault);
        token.mint(user, 1000e18);
        assertEq(token.balanceOf(user), 1000e18);
    }
    
    function testMintRevertsIfNotVault() public {
        vm.prank(user);
        vm.expectRevert("USDXToken: only vault");
        token.mint(user, 1000e18);
    }
}
```

### Integration Tests (Foundry + Hardhat)

**Location**: `test/forge/integration/` and `test/hardhat/integration/`

**Coverage**: Cross-contract interactions, external protocol integrations

### Fork Tests (Foundry + Hardhat)

**Location**: `test/forge/fork/` and `test/hardhat/fork/`

**Coverage**: Real-world scenarios with mainnet contracts

### Fuzz Tests (Foundry)

**Location**: `test/forge/`

**Example**:
```solidity
function testFuzzDeposit(uint256 amount) public {
    amount = bound(amount, 1e6, 1000000e6); // Between 1 USDC and 1M USDC
    deal(USDC_ADDRESS, address(this), amount);
    
    IERC20(USDC_ADDRESS).approve(address(vault), amount);
    uint256 usdxAmount = vault.depositUSDC(amount);
    
    assertEq(usdxAmount, amount);
}
```

### Invariant Tests (Foundry)

**Location**: `test/forge/invariants/`

**Example**:
```solidity
contract USDXVaultInvariants is Test {
    USDXVault vault;
    
    function invariant_totalCollateralEqualsTotalUSDX() public {
        assertEq(
            vault.getTotalCollateral(),
            vault.getTotalUSDXMinted()
        );
    }
}
```

## Gas Optimization

### Foundry Gas Reports

```bash
# Generate gas report
forge test --gas-report

# Compare gas usage
forge snapshot
forge test --gas-report
```

### Hardhat Gas Reporter

Already configured in `hardhat.config.ts`:
```typescript
gasReporter: {
  enabled: process.env.REPORT_GAS !== undefined,
  currency: "USD",
}
```

## Deployment Scripts

### Foundry Deployment

```solidity
// script/deploy/DeployUSDXToken.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../contracts/core/USDXToken.sol";

contract DeployUSDXToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        USDXToken token = new USDXToken(address(0x...)); // vault address
        
        console.log("USDXToken deployed at:", address(token));
        
        vm.stopBroadcast();
    }
}
```

**Run**:
```bash
forge script script/deploy/DeployUSDXToken.s.sol:DeployUSDXToken \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Hardhat Deployment

```typescript
// scripts/deploy.ts
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  
  const USDXTokenFactory = await ethers.getContractFactory("USDXToken");
  const token = await USDXTokenFactory.deploy(vaultAddress);
  await token.waitForDeployment();
  
  console.log("USDXToken deployed to:", await token.getAddress());
  
  // Verify on Etherscan
  await hre.run("verify:verify", {
    address: await token.getAddress(),
    constructorArguments: [vaultAddress],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

**Run**:
```bash
npx hardhat run scripts/deploy.ts --network sepolia
```

## Environment Setup

### `.env` File

```env
# RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY
ARBITRUM_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY
OPTIMISM_RPC_URL=https://opt-mainnet.g.alchemy.com/v2/YOUR_KEY
BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY

# Private Keys (for deployment)
PRIVATE_KEY=your_private_key_here

# Etherscan API Keys
ETHERSCAN_API_KEY=your_etherscan_key
POLYGONSCAN_API_KEY=your_polygonscan_key
ARBISCAN_API_KEY=your_arbiscan_key
OPTIMISTIC_ETHERSCAN_API_KEY=your_optimistic_etherscan_key
BASESCAN_API_KEY=your_basescan_key

# Gas Reporting
REPORT_GAS=true
```

## Dependencies

### Foundry Dependencies

```bash
# Install OpenZeppelin
forge install OpenZeppelin/openzeppelin-contracts

# Install LayerZero contracts
forge install LayerZero-Labs/layerzero-contracts

# Install Hyperlane contracts
forge install hyperlane-xyz/hyperlane-monorepo

# Update remappings
forge remappings > remappings.txt
```

### Hardhat Dependencies

```json
{
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^4.0.0",
    "@nomicfoundation/hardhat-verify": "^2.0.0",
    "hardhat": "^2.19.0",
    "hardhat-gas-reporter": "^1.0.10",
    "solidity-coverage": "^0.8.11"
  }
}
```

## CI/CD Setup

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: foundry-actions/foundry-toolchain@v1
      - name: Run tests
        run: forge test
      - name: Generate coverage
        run: forge coverage
```

## Best Practices

1. **Use Foundry for testing**: Faster, better fuzzing
2. **Use Hardhat for deployment**: Better scripts and tooling
3. **Fork mainnet for integration tests**: Test against real contracts
4. **Use fuzzing**: Catch edge cases
5. **Gas optimization**: Regular gas reports
6. **Coverage**: Aim for 90%+ coverage
7. **Invariant testing**: Test protocol invariants
8. **Documentation**: NatSpec comments for all functions

## Next Steps

1. Set up Foundry project
2. Set up Hardhat project
3. Install dependencies
4. Configure forking
5. Write first tests
6. Set up CI/CD
7. Begin contract development
