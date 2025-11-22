// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXVault} from "../../contracts/USDXVault.sol";
import {USDXToken} from "../../contracts/USDXToken.sol";
import {USDXYearnVaultWrapper} from "../../contracts/USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapter} from "../../contracts/USDXShareOFTAdapter.sol";
import {USDXVaultComposerSync} from "../../contracts/USDXVaultComposerSync.sol";
import {USDXShareOFT} from "../../contracts/USDXShareOFT.sol";
import {USDXSpokeMinter} from "../../contracts/USDXSpokeMinter.sol";
import {MockUSDC} from "../../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../../contracts/mocks/MockYearnVault.sol";
import {MockLayerZeroEndpoint} from "../../contracts/mocks/MockLayerZeroEndpoint.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IOVaultComposer} from "../../contracts/interfaces/IOVaultComposer.sol";

/**
 * @title IntegrationOVaultTest
 * @notice End-to-end integration tests for OVault flow
 */
contract IntegrationOVaultTest is Test {
    // Hub Chain Contracts
    USDXVault vault;
    USDXToken usdxHub;
    USDXYearnVaultWrapper vaultWrapper;
    USDXShareOFTAdapter shareOFTAdapter;
    USDXVaultComposerSync composer;
    MockUSDC usdc;
    MockYearnVault yearnVault;
    MockLayerZeroEndpoint lzEndpointHub;
    
    // Spoke Chain Contracts
    USDXToken usdxSpoke;
    USDXShareOFT shareOFTSpoke;
    USDXSpokeMinter spokeMinter;
    MockLayerZeroEndpoint lzEndpointSpoke;
    
    address admin = address(this);
    address user = address(0x1234);
    address treasury = address(0x5678);
    
    uint32 constant HUB_EID = 30101; // Ethereum
    uint32 constant SPOKE_EID = 30109; // Polygon
    
    uint256 constant INITIAL_BALANCE = 10000e6;
    uint256 constant DEPOSIT_AMOUNT = 1000e6;
    
    function setUp() public {
        // Deploy mocks
        usdc = new MockUSDC();
        yearnVault = new MockYearnVault(address(usdc));
        lzEndpointHub = new MockLayerZeroEndpoint(HUB_EID);
        lzEndpointSpoke = new MockLayerZeroEndpoint(SPOKE_EID);
        
        // Deploy hub chain contracts
        vaultWrapper = new USDXYearnVaultWrapper(
            address(usdc),
            address(yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        
        shareOFTAdapter = new USDXShareOFTAdapter(
            address(vaultWrapper),
            address(lzEndpointHub),
            HUB_EID,
            admin
        );
        
        composer = new USDXVaultComposerSync(
            address(vaultWrapper),
            address(shareOFTAdapter),
            address(usdc),
            address(lzEndpointHub),
            HUB_EID,
            admin
        );
        
        usdxHub = new USDXToken(admin);
        vault = new USDXVault(
            address(usdc),
            address(usdxHub),
            treasury,
            admin,
            address(composer),
            address(shareOFTAdapter),
            address(vaultWrapper)
        );
        
        // Deploy spoke chain contracts
        usdxSpoke = new USDXToken(admin);
        shareOFTSpoke = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            address(lzEndpointSpoke),
            SPOKE_EID,
            admin
        );
        
        spokeMinter = new USDXSpokeMinter(
            address(usdxSpoke),
            address(shareOFTSpoke),
            address(lzEndpointSpoke),
            HUB_EID,
            admin
        );
        
        // Grant roles
        vm.startPrank(admin);
        usdxHub.grantRole(keccak256("MINTER_ROLE"), address(vault));
        usdxSpoke.grantRole(keccak256("MINTER_ROLE"), address(spokeMinter));
        shareOFTSpoke.setMinter(address(composer));
        vm.stopPrank();
        
        // Configure LayerZero
        vm.startPrank(admin);
        usdxHub.setLayerZeroEndpoint(address(lzEndpointHub), HUB_EID);
        usdxSpoke.setLayerZeroEndpoint(address(lzEndpointSpoke), SPOKE_EID);
        
        // Set trusted remotes
        bytes32 hubRemote = bytes32(uint256(uint160(address(usdxHub))));
        bytes32 spokeRemote = bytes32(uint256(uint160(address(usdxSpoke))));
        usdxHub.setTrustedRemote(SPOKE_EID, spokeRemote);
        usdxSpoke.setTrustedRemote(HUB_EID, hubRemote);
        
        bytes32 adapterRemote = bytes32(uint256(uint160(address(shareOFTSpoke))));
        shareOFTAdapter.setTrustedRemote(SPOKE_EID, adapterRemote);
        shareOFTSpoke.setTrustedRemote(HUB_EID, bytes32(uint256(uint160(address(shareOFTAdapter)))));
        
        composer.setTrustedRemote(SPOKE_EID, adapterRemote);
        vm.stopPrank();
        
        // Set remote contracts on endpoints
        lzEndpointHub.setRemoteContract(SPOKE_EID, address(shareOFTSpoke));
        lzEndpointSpoke.setRemoteContract(HUB_EID, address(shareOFTAdapter));
        
        // Setup user
        usdc.mint(user, INITIAL_BALANCE);
        vm.startPrank(user);
        usdc.approve(address(vault), type(uint256).max);
        usdc.approve(address(composer), type(uint256).max);
        vm.stopPrank();
    }
    
    function testFullFlow_DepositViaOVault() public {
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        // User deposits via OVault
        vm.prank(user);
        vault.depositViaOVault{value: 0.001 ether}(
            DEPOSIT_AMOUNT,
            SPOKE_EID,
            receiver,
            options
        );
        
        // Verify deposit
        assertEq(vault.totalCollateral(), DEPOSIT_AMOUNT);
        assertGt(vaultWrapper.balanceOf(address(composer)), 0);
    }
    
    function testFullFlow_DepositAndMintUSDX() public {
        // Step 1: Deposit into vault (direct, not via OVault for simplicity)
        vm.prank(user);
        vault.deposit(DEPOSIT_AMOUNT);
        
        // Step 2: Get shares from vault wrapper
        uint256 shares = vaultWrapper.balanceOf(user);
        
        // Step 3: Lock shares in adapter (user needs to approve adapter first)
        vm.startPrank(user);
        IERC20(address(vaultWrapper)).approve(address(shareOFTAdapter), shares);
        shareOFTAdapter.lockShares(shares);
        vm.stopPrank();
        
        // Step 4: Send shares cross-chain (simulate)
        bytes memory options = "";
        vm.prank(user);
        shareOFTAdapter.send{value: 0.001 ether}(
            SPOKE_EID,
            bytes32(uint256(uint160(user))),
            shares,
            options
        );
        
        // Step 5: Manually trigger lzReceive on spoke (simulating LayerZero delivery)
        bytes memory payload = abi.encode(user, shares);
        vm.prank(address(lzEndpointSpoke));
        shareOFTSpoke.lzReceive(
            HUB_EID,
            bytes32(uint256(uint160(address(shareOFTAdapter)))),
            payload,
            address(0),
            ""
        );
        
        // Step 6: Approve and mint USDX on spoke using shares
        vm.startPrank(user);
        shareOFTSpoke.approve(address(spokeMinter), shares);
        spokeMinter.mintUSDXFromOVault(shares);
        vm.stopPrank();
        
        // Verify
        assertEq(usdxSpoke.balanceOf(user), shares);
        assertEq(shareOFTSpoke.balanceOf(user), 0, "Shares should be burned");
    }
    
    function testCrossChainUSDXTransfer() public {
        uint256 amount = 500 * 10**6;
        
        // Mint USDX on hub
        vm.prank(admin);
        usdxHub.mint(user, amount);
        
        // Set trusted remotes
        bytes32 hubRemote = bytes32(uint256(uint160(address(usdxHub))));
        bytes32 spokeRemote = bytes32(uint256(uint160(address(usdxSpoke))));
        
        vm.prank(admin);
        usdxHub.setTrustedRemote(SPOKE_EID, spokeRemote);
        
        lzEndpointHub.setRemoteContract(SPOKE_EID, address(usdxSpoke));
        
        // Send cross-chain
        vm.prank(user);
        usdxHub.sendCrossChain{value: 0.001 ether}(
            SPOKE_EID,
            bytes32(uint256(uint160(user))),
            amount,
            ""
        );
        
        // Verify burn on hub
        assertEq(usdxHub.balanceOf(user), 0);
        
        // Manually trigger lzReceive on spoke
        bytes memory payload = abi.encode(user, amount);
        vm.prank(address(lzEndpointSpoke));
        usdxSpoke.lzReceive(
            HUB_EID,
            hubRemote,
            payload,
            address(0),
            ""
        );
        
        // Verify mint on spoke
        assertEq(usdxSpoke.balanceOf(user), amount);
    }
}
