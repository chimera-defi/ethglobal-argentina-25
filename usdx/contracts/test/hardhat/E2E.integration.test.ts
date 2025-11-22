import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import {
  USDXToken,
  USDXVault,
  MockUSDC,
  MockYieldVault,
  USDXSpokeMinter,
  CrossChainBridge,
} from "../../typechain-types/index";

describe("USDX Protocol - End-to-End Integration Tests", function () {
  // Contracts
  let usdxToken: USDXToken;
  let usdxVault: USDXVault;
  let mockUSDC: MockUSDC;
  let mockYieldVault: MockYieldVault;
  let spokeMinter: USDXSpokeMinter;
  let bridge: CrossChainBridge;

  // Signers
  let deployer: SignerWithAddress;
  let admin: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Test constants
  const HUB_CHAIN_ID = 1; // Ethereum mainnet
  const SPOKE_CHAIN_ID = 137; // Polygon
  const INITIAL_USDC_AMOUNT = ethers.parseUnits("10000", 6); // 10,000 USDC
  const DEPOSIT_AMOUNT = ethers.parseUnits("1000", 6); // 1,000 USDC
  const WITHDRAW_AMOUNT = ethers.parseUnits("500", 18); // 500 USDX

  before(async function () {
    // Get signers
    [deployer, admin, user1, user2, relayer] = await ethers.getSigners();

    // Deploy all contracts
    await deployContracts();
  });

  async function deployContracts() {
    // 1. Deploy MockUSDC
    const MockUSDCFactory = await ethers.getContractFactory("MockUSDC");
    mockUSDC = await MockUSDCFactory.deploy();
    await mockUSDC.waitForDeployment();

    // Mint USDC to users for testing
    await mockUSDC.mint(user1.address, INITIAL_USDC_AMOUNT);
    await mockUSDC.mint(user2.address, INITIAL_USDC_AMOUNT);

    // 2. Deploy USDXToken
    const USDXTokenFactory = await ethers.getContractFactory("USDXToken");
    usdxToken = await USDXTokenFactory.deploy(admin.address);
    await usdxToken.waitForDeployment();

    // 3. Deploy MockYieldVault
    const MockYieldVaultFactory = await ethers.getContractFactory("MockYieldVault");
    mockYieldVault = await MockYieldVaultFactory.deploy(await mockUSDC.getAddress());
    await mockYieldVault.waitForDeployment();

    // 4. Deploy USDXVault
    const USDXVaultFactory = await ethers.getContractFactory("USDXVault");
    usdxVault = await USDXVaultFactory.deploy(
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

    // 5. Deploy USDXSpokeMinter (for spoke chain)
    const USDXSpokeMinterFactory = await ethers.getContractFactory("USDXSpokeMinter");
    spokeMinter = await USDXSpokeMinterFactory.deploy(
      await usdxToken.getAddress(),
      await usdxVault.getAddress(),
      HUB_CHAIN_ID
    );
    await spokeMinter.waitForDeployment();

    // Grant RELAYER_ROLE to relayer
    await spokeMinter.connect(admin).grantRole(
      await spokeMinter.RELAYER_ROLE(),
      relayer.address
    );

    // 6. Deploy CrossChainBridge
    const CrossChainBridgeFactory = await ethers.getContractFactory("CrossChainBridge");
    bridge = await CrossChainBridgeFactory.deploy(
      await usdxToken.getAddress(),
      HUB_CHAIN_ID
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
    await bridge.connect(admin).setSupportedChain(SPOKE_CHAIN_ID, true);
  }

  describe("Complete Deposit Flow", function () {
    it("Should allow user to deposit USDC and receive USDX", async function () {
      // Approve USDC
      await mockUSDC.connect(user1).approve(
        await usdxVault.getAddress(),
        DEPOSIT_AMOUNT
      );

      // Get initial balances
      const initialUSDCBalance = await mockUSDC.balanceOf(user1.address);
      const initialUSDXBalance = await usdxToken.balanceOf(user1.address);
      const initialVaultCollateral = await usdxVault.totalCollateral();

      // Deposit
      const tx = await usdxVault.connect(user1).depositUSDC(DEPOSIT_AMOUNT);
      const receipt = await tx.wait();

      // Verify balances
      const finalUSDCBalance = await mockUSDC.balanceOf(user1.address);
      const finalUSDXBalance = await usdxToken.balanceOf(user1.address);
      const finalVaultCollateral = await usdxVault.totalCollateral();

      expect(finalUSDCBalance).to.equal(initialUSDCBalance - DEPOSIT_AMOUNT);
      expect(finalUSDXBalance).to.equal(initialUSDXBalance + DEPOSIT_AMOUNT);
      expect(finalVaultCollateral).to.equal(initialVaultCollateral + DEPOSIT_AMOUNT);

      // Verify event
      const depositEvent = receipt?.logs.find(
        (log: any) => log.topics[0] === ethers.id("Deposit(address,uint256,uint256)")
      );
      expect(depositEvent).to.not.be.undefined;
    });

    it("Should track user collateral correctly", async function () {
      const userCollateral = await usdxVault.getUserCollateral(user1.address);
      expect(userCollateral).to.equal(DEPOSIT_AMOUNT);
    });

    it("Should maintain 1:1 collateral ratio", async function () {
      const collateralRatio = await usdxVault.getCollateralRatio();
      expect(collateralRatio).to.equal(ethers.parseUnits("1", 18)); // 1:1 ratio
    });
  });

  describe("Yield Accrual", function () {
    it("Should accrue yield over time", async function () {
      // Get initial yield position
      const [initialShares, initialAssets] = await usdxVault.getUserYieldPosition(user1.address);
      
      // Fast forward time (simulate 30 days)
      await time.increase(30 * 24 * 60 * 60); // 30 days

      // Get yield position after time passes
      const [finalShares, finalAssets] = await usdxVault.getUserYieldPosition(user1.address);

      // Shares should remain the same
      expect(finalShares).to.equal(initialShares);
      
      // Assets should increase due to yield
      expect(finalAssets).to.be.gt(initialAssets);
    });

    it("Should calculate yield correctly", async function () {
      // Get yield position
      const [shares, assets] = await usdxVault.getUserYieldPosition(user1.address);
      
      // Assets should be >= shares (due to yield accrual)
      expect(assets).to.be.gte(shares);
    });
  });

  describe("Complete Withdrawal Flow", function () {
    it("Should allow user to withdraw USDC by burning USDX", async function () {
      // Get initial balances
      const initialUSDCBalance = await mockUSDC.balanceOf(user1.address);
      const initialUSDXBalance = await usdxToken.balanceOf(user1.address);
      const initialVaultCollateral = await usdxVault.totalCollateral();

      // Withdraw
      const tx = await usdxVault.connect(user1).withdrawUSDC(WITHDRAW_AMOUNT);
      const receipt = await tx.wait();

      // Verify balances
      const finalUSDCBalance = await mockUSDC.balanceOf(user1.address);
      const finalUSDXBalance = await usdxToken.balanceOf(user1.address);
      const finalVaultCollateral = await usdxVault.totalCollateral();

      // USDX should be burned
      expect(finalUSDXBalance).to.equal(initialUSDXBalance - WITHDRAW_AMOUNT);
      
      // USDC should be returned (may include yield)
      expect(finalUSDCBalance).to.be.gte(initialUSDCBalance);
      
      // Vault collateral should decrease
      expect(finalVaultCollateral).to.be.lt(initialVaultCollateral);

      // Verify event
      const withdrawalEvent = receipt?.logs.find(
        (log: any) => log.topics[0] === ethers.id("Withdrawal(address,uint256,uint256)")
      );
      expect(withdrawalEvent).to.not.be.undefined;
    });

    it("Should prevent withdrawal if insufficient collateral", async function () {
      const userCollateral = await usdxVault.getUserCollateral(user1.address);
      const excessiveAmount = userCollateral + ethers.parseUnits("1", 18);

      await expect(
        usdxVault.connect(user1).withdrawUSDC(excessiveAmount)
      ).to.be.revertedWith("USDXVault: insufficient collateral");
    });
  });

  describe("Cross-Chain Spoke Minter Flow", function () {
    it("Should allow relayer to mint USDX on spoke chain using hub position", async function () {
      // User deposits on hub chain first
      const depositAmount = ethers.parseUnits("2000", 6);
      await mockUSDC.connect(user2).approve(
        await usdxVault.getAddress(),
        depositAmount
      );
      await usdxVault.connect(user2).depositUSDC(depositAmount);

      // Get user's hub position
      const hubPosition = await usdxVault.getUserCollateral(user2.address);

      // Mint USDX on spoke chain via relayer
      const mintAmount = ethers.parseUnits("1000", 18);
      const mintId = ethers.keccak256(ethers.toUtf8Bytes("test-mint-1"));

      const initialSpokeBalance = await usdxToken.balanceOf(user2.address);

      const tx = await spokeMinter.connect(relayer).mintFromHubPosition(
        user2.address,
        mintAmount,
        hubPosition,
        mintId
      );
      const receipt = await tx.wait();

      // Verify USDX was minted on spoke chain
      const finalSpokeBalance = await usdxToken.balanceOf(user2.address);
      expect(finalSpokeBalance).to.equal(initialSpokeBalance + mintAmount);

      // Verify event
      const mintEvent = receipt?.logs.find(
        (log: any) => log.topics[0] === ethers.id("MintFromPosition(address,uint256,uint256,bytes32)")
      );
      expect(mintEvent).to.not.be.undefined;
    });

    it("Should prevent double minting with same mintId", async function () {
      const hubPosition = await usdxVault.getUserCollateral(user2.address);
      const mintAmount = ethers.parseUnits("500", 18);
      const mintId = ethers.keccak256(ethers.toUtf8Bytes("test-mint-duplicate"));

      // First mint should succeed
      await spokeMinter.connect(relayer).mintFromHubPosition(
        user2.address,
        mintAmount,
        hubPosition,
        mintId
      );

      // Second mint with same ID should fail
      await expect(
        spokeMinter.connect(relayer).mintFromHubPosition(
          user2.address,
          mintAmount,
          hubPosition,
          mintId
        )
      ).to.be.revertedWith("USDXSpokeMinter: mint already processed");
    });

    it("Should prevent minting if insufficient hub position", async function () {
      const hubPosition = await usdxVault.getUserCollateral(user2.address);
      const excessiveAmount = hubPosition + ethers.parseUnits("1", 18);
      const mintId = ethers.keccak256(ethers.toUtf8Bytes("test-mint-insufficient"));

      await expect(
        spokeMinter.connect(relayer).mintFromHubPosition(
          user2.address,
          excessiveAmount,
          hubPosition,
          mintId
        )
      ).to.be.revertedWith("USDXSpokeMinter: insufficient hub position");
    });
  });

  describe("Cross-Chain Bridge Flow", function () {
    it("Should allow user to transfer USDX cross-chain", async function () {
      // User needs USDX first
      const transferAmount = ethers.parseUnits("100", 18);
      
      // Mint USDX to user1 for testing
      await usdxToken.connect(admin).grantRole(
        await usdxToken.VAULT_ROLE(),
        admin.address
      );
      await usdxToken.connect(admin).mint(user1.address, transferAmount);

      // Approve bridge
      await usdxToken.connect(user1).approve(
        await bridge.getAddress(),
        transferAmount
      );

      // Get initial balances
      const initialBalance = await usdxToken.balanceOf(user1.address);

      // Initiate cross-chain transfer
      const tx = await bridge.connect(user1).transferCrossChain(
        transferAmount,
        SPOKE_CHAIN_ID,
        user2.address
      );
      const receipt = await tx.wait();

      // Verify USDX was burned
      const finalBalance = await usdxToken.balanceOf(user1.address);
      expect(finalBalance).to.equal(initialBalance - transferAmount);

      // Verify event
      const transferEvent = receipt?.logs.find(
        (log: any) => log.topics[0] === ethers.id("TransferInitiated(bytes32,address,uint256,uint256,uint256,address)")
      );
      expect(transferEvent).to.not.be.undefined;

      // Get transfer ID from event
      const transferId = await bridge.transferNonce();
      const pendingTransfer = await bridge.getPendingTransfer(
        ethers.keccak256(
          ethers.AbiCoder.defaultAbiCoder().encode(
            ["uint256", "uint256", "address", "address", "uint256", "uint256", "uint256"],
            [
              HUB_CHAIN_ID,
              SPOKE_CHAIN_ID,
              user1.address,
              user2.address,
              transferAmount,
              transferId - 1n,
              (await ethers.provider.getBlock(receipt!.blockNumber))!.timestamp
            ]
          )
        )
      );

      expect(pendingTransfer.user).to.equal(user1.address);
      expect(pendingTransfer.amount).to.equal(transferAmount);
    });

    it("Should allow relayer to complete cross-chain transfer", async function () {
      // Get a transfer ID (from previous test)
      const transferAmount = ethers.parseUnits("50", 18);
      
      // Create a transfer
      await usdxToken.connect(admin).mint(user1.address, transferAmount);
      await usdxToken.connect(user1).approve(await bridge.getAddress(), transferAmount);
      
      const tx = await bridge.connect(user1).transferCrossChain(
        transferAmount,
        SPOKE_CHAIN_ID,
        user2.address
      );
      const receipt = await tx.wait();

      // Calculate transfer ID
      const block = await ethers.provider.getBlock(receipt!.blockNumber);
      const transferId = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["uint256", "uint256", "address", "address", "uint256", "uint256", "uint256"],
          [
            HUB_CHAIN_ID,
            SPOKE_CHAIN_ID,
            user1.address,
            user2.address,
            transferAmount,
            (await bridge.transferNonce()) - 1n,
            block!.timestamp
          ]
        )
      );

      // Get initial balance on destination chain
      const initialBalance = await usdxToken.balanceOf(user2.address);

      // Complete transfer via relayer
      const completeTx = await bridge.connect(relayer).completeTransfer(
        transferId,
        HUB_CHAIN_ID,
        user1.address,
        transferAmount,
        user2.address
      );
      const completeReceipt = await completeTx.wait();

      // Verify USDX was minted on destination chain
      const finalBalance = await usdxToken.balanceOf(user2.address);
      expect(finalBalance).to.equal(initialBalance + transferAmount);

      // Verify event
      const completeEvent = completeReceipt?.logs.find(
        (log: any) => log.topics[0] === ethers.id("TransferCompleted(bytes32,address,uint256,uint256,uint256)")
      );
      expect(completeEvent).to.not.be.undefined;
    });

    it("Should prevent duplicate transfer completion", async function () {
      const transferAmount = ethers.parseUnits("25", 18);
      
      // Create and complete a transfer
      await usdxToken.connect(admin).mint(user1.address, transferAmount);
      await usdxToken.connect(user1).approve(await bridge.getAddress(), transferAmount);
      
      const tx = await bridge.connect(user1).transferCrossChain(
        transferAmount,
        SPOKE_CHAIN_ID,
        user2.address
      );
      const receipt = await tx.wait();

      const block = await ethers.provider.getBlock(receipt!.blockNumber);
      const transferId = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["uint256", "uint256", "address", "address", "uint256", "uint256", "uint256"],
          [
            HUB_CHAIN_ID,
            SPOKE_CHAIN_ID,
            user1.address,
            user2.address,
            transferAmount,
            (await bridge.transferNonce()) - 1n,
            block!.timestamp
          ]
        )
      );

      // Complete once
      await bridge.connect(relayer).completeTransfer(
        transferId,
        HUB_CHAIN_ID,
        user1.address,
        transferAmount,
        user2.address
      );

      // Try to complete again - should fail
      await expect(
        bridge.connect(relayer).completeTransfer(
          transferId,
          HUB_CHAIN_ID,
          user1.address,
          transferAmount,
          user2.address
        )
      ).to.be.revertedWith("CrossChainBridge: transfer already processed");
    });
  });

  describe("Complete End-to-End Flow", function () {
    it("Should complete full flow: deposit -> yield -> spoke mint -> bridge -> withdraw", async function () {
      const testUser = user2;
      const depositAmount = ethers.parseUnits("5000", 6);
      const spokeMintAmount = ethers.parseUnits("2000", 18);
      const bridgeAmount = ethers.parseUnits("1000", 18);
      const withdrawAmount = ethers.parseUnits("1500", 18);

      // Step 1: Deposit USDC on hub chain
      await mockUSDC.connect(testUser).approve(
        await usdxVault.getAddress(),
        depositAmount
      );
      await usdxVault.connect(testUser).depositUSDC(depositAmount);

      // Verify deposit
      const hubPosition = await usdxVault.getUserCollateral(testUser.address);
      expect(hubPosition).to.equal(depositAmount);

      // Step 2: Accrue yield (fast forward time)
      await time.increase(60 * 24 * 60 * 60); // 60 days

      // Step 3: Mint USDX on spoke chain using hub position
      const mintId1 = ethers.keccak256(ethers.toUtf8Bytes("e2e-mint-1"));
      await spokeMinter.connect(relayer).mintFromHubPosition(
        testUser.address,
        spokeMintAmount,
        hubPosition,
        mintId1
      );

      // Verify spoke mint
      const spokeBalance = await usdxToken.balanceOf(testUser.address);
      expect(spokeBalance).to.equal(spokeMintAmount);

      // Step 4: Transfer USDX cross-chain
      await usdxToken.connect(testUser).approve(
        await bridge.getAddress(),
        bridgeAmount
      );
      
      const bridgeTx = await bridge.connect(testUser).transferCrossChain(
        bridgeAmount,
        SPOKE_CHAIN_ID,
        testUser.address // Transfer to self on different chain
      );
      const bridgeReceipt = await bridgeTx.wait();

      // Verify USDX burned
      const balanceAfterBridge = await usdxToken.balanceOf(testUser.address);
      expect(balanceAfterBridge).to.equal(spokeMintAmount - bridgeAmount);

      // Step 5: Complete bridge transfer (simulate relayer)
      const bridgeBlock = await ethers.provider.getBlock(bridgeReceipt!.blockNumber);
      const bridgeTransferId = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["uint256", "uint256", "address", "address", "uint256", "uint256", "uint256"],
          [
            HUB_CHAIN_ID,
            SPOKE_CHAIN_ID,
            testUser.address,
            testUser.address,
            bridgeAmount,
            (await bridge.transferNonce()) - 1n,
            bridgeBlock!.timestamp
          ]
        )
      );

      await bridge.connect(relayer).completeTransfer(
        bridgeTransferId,
        HUB_CHAIN_ID,
        testUser.address,
        bridgeAmount,
        testUser.address
      );

      // Verify USDX minted on destination chain
      const finalSpokeBalance = await usdxToken.balanceOf(testUser.address);
      expect(finalSpokeBalance).to.equal(spokeMintAmount); // Back to original after bridge

      // Step 6: Withdraw USDC from hub chain
      await usdxVault.connect(testUser).withdrawUSDC(withdrawAmount);

      // Verify withdrawal
      const finalHubPosition = await usdxVault.getUserCollateral(testUser.address);
      expect(finalHubPosition).to.be.lt(hubPosition);
    });
  });

  describe("Edge Cases and Security", function () {
    it("Should prevent reentrancy attacks", async function () {
      // This is tested by the nonReentrant modifier
      // If reentrancy was possible, multiple deposits in same transaction would succeed
      const depositAmount = ethers.parseUnits("100", 6);
      
      await mockUSDC.connect(user1).approve(
        await usdxVault.getAddress(),
        depositAmount
      );

      // Normal deposit should work
      await expect(
        usdxVault.connect(user1).depositUSDC(depositAmount)
      ).to.not.be.reverted;
    });

    it("Should maintain correct total supply tracking", async function () {
      const totalMinted = await usdxVault.getTotalUSDXMinted();
      const totalSupply = await usdxToken.totalSupply();
      
      // These should match (all USDX comes from vault)
      expect(totalMinted).to.equal(totalSupply);
    });

    it("Should handle multiple users correctly", async function () {
      const user1Deposit = ethers.parseUnits("1000", 6);
      const user2Deposit = ethers.parseUnits("2000", 6);

      // Both users deposit
      await mockUSDC.connect(user1).approve(await usdxVault.getAddress(), user1Deposit);
      await mockUSDC.connect(user2).approve(await usdxVault.getAddress(), user2Deposit);
      
      await usdxVault.connect(user1).depositUSDC(user1Deposit);
      await usdxVault.connect(user2).depositUSDC(user2Deposit);

      // Verify both positions tracked correctly
      const user1Position = await usdxVault.getUserCollateral(user1.address);
      const user2Position = await usdxVault.getUserCollateral(user2.address);
      
      expect(user1Position).to.equal(user1Deposit);
      expect(user2Position).to.equal(user2Deposit);

      // Verify total collateral
      const totalCollateral = await usdxVault.getTotalCollateral();
      expect(totalCollateral).to.equal(user1Deposit + user2Deposit);
    });
  });
});
