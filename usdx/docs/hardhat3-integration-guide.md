# Hardhat3 Integration Guide

## Overview

This project now uses **both Hardhat3 and Foundry** as complementary build tools:

- **Foundry**: Primary tool for Solidity testing and deployment scripts
- **Hardhat3**: Secondary tool for TypeScript integration, Hardhat Ignition deployments, and contract verification

## Why Both Tools?

### Foundry Advantages
- ✅ Faster Solidity compilation and testing
- ✅ Excellent fuzz testing and invariant testing
- ✅ Native Solidity scripting
- ✅ Better gas optimization tools

### Hardhat3 Advantages
- ✅ TypeScript/JavaScript integration
- ✅ Hardhat Ignition for deployment orchestration
- ✅ Contract verification on Etherscan
- ✅ Better IDE integration with TypeScript
- ✅ Native Solidity testing (complementary to Foundry)

## Installation

Hardhat3 is already installed. To verify:

```bash
cd contracts
npm install
npx hardhat --version  # Should show 3.0.15+
```

## Project Structure

```
contracts/
├── contracts/          # Solidity source files (shared)
├── test/
│   ├── forge/          # Foundry tests (*.t.sol)
│   └── hardhat/        # Hardhat3 tests (*.test.sol)
├── script/             # Foundry deployment scripts (*.s.sol)
├── ignition/
│   └── modules/        # Hardhat Ignition modules (*.ts)
├── foundry.toml        # Foundry configuration
└── hardhat.config.ts   # Hardhat3 configuration
```

## Usage

### Compilation

**Foundry:**
```bash
npm run compile:foundry
# or
forge build
```

**Hardhat3:**
```bash
npm run compile
# or
npx hardhat compile
```

Both tools compile the same contracts from `contracts/` directory.

### Testing

**Foundry Tests:**
```bash
npm run test:foundry
# or
forge test
```

**Hardhat3 Tests:**
```bash
npm run test
# or
npx hardhat test
```

**Run All Tests:**
```bash
npm run test:all
```

### Deployment

**Foundry Scripts:**
```bash
# Deploy using Foundry
forge script script/DeployHub.s.sol:DeployHub \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Hardhat Ignition:**
```bash
# Deploy using Hardhat Ignition
npx hardhat ignition deploy ignition/modules/DeployHub.ts \
  --network sepolia \
  --parameters '{"DeployHub":{"usdcAddress":"0x..."}}'
```

### Contract Verification

**Hardhat3:**
```bash
npm run verify
# or
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

## Hardhat3 Features

### 1. Solidity Tests

Hardhat3 supports native Solidity testing similar to Foundry. Example:

```solidity
// test/hardhat/USDXToken.test.sol
pragma solidity ^0.8.23;

import "hardhat/console.sol";
import "../../contracts/USDXToken.sol";

contract USDXTokenTest {
    USDXToken public token;
    
    function setUp() public {
        token = new USDXToken(msg.sender);
    }
    
    function testDeployment() public view {
        require(keccak256(bytes(token.name())) == keccak256(bytes("USDX Stablecoin")));
    }
}
```

### 2. Hardhat Ignition

Hardhat Ignition provides deployment orchestration with dependency management:

```typescript
// ignition/modules/DeployHub.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("DeployHub", (m) => {
  const deployer = m.getAccount(0);
  const token = m.contract("USDXToken", [deployer]);
  const vault = m.contract("USDXVault", [token, ...]);
  
  // Automatically handles dependencies and ordering
  m.call(token, "grantRole", [ROLE, vault], { after: [vault] });
  
  return { token, vault };
});
```

**Benefits:**
- Automatic dependency resolution
- Deployment state management
- Resumable deployments
- Parameterized deployments

### 3. TypeScript Integration

Hardhat3 provides excellent TypeScript support:

```typescript
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const Token = await ethers.getContractFactory("USDXToken");
  const token = await Token.deploy(deployer.address);
  await token.waitForDeployment();
  console.log("Token deployed to:", await token.getAddress());
}
```

### 4. Network Forking

Hardhat3 supports mainnet forking:

```bash
# Fork mainnet for testing
npx hardhat test --network hardhat
```

Configured in `hardhat.config.ts`:
```typescript
hardhat: {
  type: "edr-simulated",
  forking: {
    url: process.env.MAINNET_RPC_URL,
    enabled: true,
  },
}
```

## Configuration

### Hardhat3 Config (`hardhat.config.ts`)

Key settings:
- **Solidity**: v0.8.23 with optimizer (200 runs)
- **Networks**: Mainnet, Sepolia, Polygon, Arbitrum, Optimism, Base
- **Remappings**: OpenZeppelin, LayerZero, Hyperlane
- **Ignition**: Deployment configuration

### Foundry Config (`foundry.toml`)

Key settings:
- **Solidity**: v0.8.23 with optimizer (200 runs)
- **Remappings**: Same as Hardhat3
- **Test**: `test/forge/`
- **Script**: `script/`

## When to Use Which Tool?

### Use Foundry For:
- ✅ Writing new Solidity tests
- ✅ Fuzz testing and invariant testing
- ✅ Gas optimization analysis
- ✅ Quick deployment scripts
- ✅ Performance-critical testing

### Use Hardhat3 For:
- ✅ TypeScript/JavaScript integration
- ✅ Complex deployment orchestration (Ignition)
- ✅ Contract verification
- ✅ Integration with frontend/backend TypeScript code
- ✅ IDE autocomplete and type checking

## Migration Notes

### From Hardhat v2 to v3

Changes made:
1. ✅ Updated to Hardhat v3.0.15
2. ✅ Switched to ESM modules (`"type": "module"`)
3. ✅ Updated network configuration (added `type` field)
4. ✅ Updated plugins to Hardhat3-compatible versions
5. ✅ Added Hardhat Ignition support

### Breaking Changes
- Network configs now require `type: "http"` or `type: "edr-simulated"`
- ESM modules required (no CommonJS)
- Some plugins may not be compatible yet

## Troubleshooting

### Compilation Errors

**Missing Dependencies:**
```bash
# Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install LayerZero-Labs/layerzero-contracts

# Update remappings
forge remappings > remappings.txt
```

**Remapping Issues:**
Both Foundry and Hardhat3 use remappings. Ensure `remappings.txt` and `hardhat.config.ts` remappings match.

### Network Configuration

If networks aren't showing up, ensure environment variables are set:
```bash
export MAINNET_RPC_URL="https://..."
export SEPOLIA_RPC_URL="https://..."
export PRIVATE_KEY="0x..."
```

## Examples

### Example 1: Foundry Test
```solidity
// test/forge/USDXToken.t.sol
contract USDXTokenTest is Test {
    USDXToken public token;
    
    function setUp() public {
        token = new USDXToken(address(this));
    }
    
    function testMint() public {
        token.mint(address(1), 1000e6);
        assertEq(token.balanceOf(address(1)), 1000e6);
    }
}
```

### Example 2: Hardhat3 Test
```solidity
// test/hardhat/USDXToken.test.sol
contract USDXTokenTest {
    USDXToken public token;
    
    function setUp() public {
        token = new USDXToken(msg.sender);
    }
    
    function testMint() public {
        token.mint(address(1), 1000e6);
        require(token.balanceOf(address(1)) == 1000e6);
    }
}
```

### Example 3: Hardhat Ignition Deployment
```typescript
// ignition/modules/DeployHub.ts
export default buildModule("DeployHub", (m) => {
  const token = m.contract("USDXToken", [m.getAccount(0)]);
  const vault = m.contract("USDXVault", [token, ...]);
  return { token, vault };
});
```

## Resources

- [Hardhat3 Documentation](https://hardhat.org/docs/getting-started)
- [Hardhat Ignition Guide](https://hardhat.org/ignition/docs)
- [Foundry Documentation](https://book.getfoundry.sh/)
- [Migration Guide](https://hardhat.org/docs/migrate-from-hardhat2)

## Next Steps

1. ✅ Hardhat3 installed and configured
2. ✅ Example tests created
3. ✅ Ignition deployment module created
4. ⏳ Write more Hardhat3 tests as needed
5. ⏳ Use Ignition for complex deployments
6. ⏳ Integrate with TypeScript tooling
