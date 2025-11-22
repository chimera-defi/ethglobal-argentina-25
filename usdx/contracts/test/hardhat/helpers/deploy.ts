import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  USDXToken,
  USDXVault,
  MockUSDC,
  MockYieldVault,
  USDXSpokeMinter,
  CrossChainBridge,
} from "../../../typechain-types/index";

export interface DeployedContracts {
  usdxToken: USDXToken;
  usdxVault: USDXVault;
  mockUSDC: MockUSDC;
  mockYieldVault: MockYieldVault;
  spokeMinter: USDXSpokeMinter;
  bridge: CrossChainBridge;
}

export interface DeployConfig {
  deployer: HardhatEthersSigner;
  admin: HardhatEthersSigner;
  relayer: HardhatEthersSigner;
  hubChainId?: number;
  spokeChainId?: number;
}

/**
 * Deploy all USDX protocol contracts
 */
export async function deployUSDXContracts(
  config: DeployConfig
): Promise<DeployedContracts> {
  const { deployer, admin, relayer, hubChainId = 1, spokeChainId = 137 } = config;

  // 1. Deploy MockUSDC
  const MockUSDCFactory = await ethers.getContractFactory("MockUSDC");
  const mockUSDC = await MockUSDCFactory.connect(deployer).deploy();
  await mockUSDC.waitForDeployment();

  // 2. Deploy USDXToken
  const USDXTokenFactory = await ethers.getContractFactory("USDXToken");
  const usdxToken = await USDXTokenFactory.connect(deployer).deploy(admin.address);
  await usdxToken.waitForDeployment();

  // 3. Deploy MockYieldVault
  const MockYieldVaultFactory = await ethers.getContractFactory("MockYieldVault");
  const mockYieldVault = await MockYieldVaultFactory.connect(deployer).deploy(
    await mockUSDC.getAddress()
  );
  await mockYieldVault.waitForDeployment();

  // 4. Deploy USDXVault
  const USDXVaultFactory = await ethers.getContractFactory("USDXVault");
  const usdxVault = await USDXVaultFactory.connect(deployer).deploy(
    await mockUSDC.getAddress(),
    await usdxToken.getAddress(),
    await mockYieldVault.getAddress()
  );
  await usdxVault.waitForDeployment();

  // Grant VAULT_ROLE to vault
  await usdxToken.connect(admin).grantRole(
    await usdxToken.VAULT_ROLE(),
    await usdxVault.getAddress()
  );

  // 5. Deploy USDXSpokeMinter
  const USDXSpokeMinterFactory = await ethers.getContractFactory("USDXSpokeMinter");
  const spokeMinter = await USDXSpokeMinterFactory.connect(deployer).deploy(
    await usdxToken.getAddress(),
    await usdxVault.getAddress(),
    hubChainId
  );
  await spokeMinter.waitForDeployment();

  // Grant RELAYER_ROLE to relayer
  await spokeMinter.connect(admin).grantRole(
    await spokeMinter.RELAYER_ROLE(),
    relayer.address
  );

  // 6. Deploy CrossChainBridge
  const CrossChainBridgeFactory = await ethers.getContractFactory("CrossChainBridge");
  const bridge = await CrossChainBridgeFactory.connect(deployer).deploy(
    await usdxToken.getAddress(),
    hubChainId
  );
  await bridge.waitForDeployment();

  // Grant RELAYER_ROLE to relayer
  await bridge.connect(admin).grantRole(
    await bridge.RELAYER_ROLE(),
    relayer.address
  );

  // Grant BRIDGE_ROLE to bridge
  await usdxToken.connect(admin).grantRole(
    await usdxToken.BRIDGE_ROLE(),
    await bridge.getAddress()
  );

  // Set supported chains
  await bridge.connect(admin).setSupportedChain(spokeChainId, true);

  return {
    usdxToken,
    usdxVault,
    mockUSDC,
    mockYieldVault,
    spokeMinter,
    bridge,
  };
}

/**
 * Setup test environment with funded users
 */
export async function setupTestEnvironment(
  contracts: DeployedContracts,
  users: HardhatEthersSigner[],
  amountPerUser: bigint = ethers.parseUnits("10000", 6)
) {
  // Mint USDC to users
  for (const user of users) {
    await contracts.mockUSDC.mint(user.address, amountPerUser);
  }
}
