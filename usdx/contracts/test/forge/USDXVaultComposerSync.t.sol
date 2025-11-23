// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXVaultComposerSync} from "../../contracts/USDXVaultComposerSync.sol";
import {USDXYearnVaultWrapper} from "../../contracts/USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapter} from "../../contracts/USDXShareOFTAdapter.sol";
import {USDXShareOFT} from "../../contracts/USDXShareOFT.sol";
import {MockUSDC} from "../../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../../contracts/mocks/MockYearnVault.sol";
import {MockLayerZeroEndpoint} from "../../contracts/mocks/MockLayerZeroEndpoint.sol";
import {IOVaultComposer} from "../../contracts/interfaces/IOVaultComposer.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDXVaultComposerSyncTest is Test {
    USDXVaultComposerSync composer;
    USDXYearnVaultWrapper vault;
    USDXShareOFTAdapter shareOFTAdapter;
    USDXShareOFT shareOFT;
    MockUSDC usdc;
    MockYearnVault yearnVault;
    MockLayerZeroEndpoint lzEndpoint;
    
    address owner = address(this);
    address user = address(0x1234);
    
    uint32 constant LOCAL_EID = 30101; // Ethereum (hub)
    uint32 constant REMOTE_EID = 30109; // Polygon (spoke)
    
    uint256 constant INITIAL_BALANCE = 10000e6;
    uint256 constant DEPOSIT_AMOUNT = 1000e6;
    
    function setUp() public {
        // Deploy mocks
        usdc = new MockUSDC();
        yearnVault = new MockYearnVault(address(usdc));
        lzEndpoint = new MockLayerZeroEndpoint(LOCAL_EID);
        
        // Deploy vault wrapper
        vault = new USDXYearnVaultWrapper(
            address(usdc),
            address(yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        
        // Deploy share OFT adapter (hub)
        shareOFTAdapter = new USDXShareOFTAdapter(
            address(vault),
            address(lzEndpoint),
            LOCAL_EID,
            owner
        );
        
        // Deploy share OFT (spoke)
        shareOFT = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            address(lzEndpoint),
            REMOTE_EID,
            owner
        );
        
        // Deploy composer
        composer = new USDXVaultComposerSync(
            address(vault),
            address(shareOFTAdapter),
            address(usdc),
            address(lzEndpoint),
            LOCAL_EID,
            owner
        );
        
        // Setup user
        usdc.mint(user, INITIAL_BALANCE);
        vm.deal(user, 1 ether); // Give user ETH for LayerZero fees
        vm.startPrank(user);
        usdc.approve(address(composer), type(uint256).max);
        IERC20(address(vault)).approve(address(shareOFTAdapter), type(uint256).max);
        vm.stopPrank();
        
        // Set trusted remotes
        bytes32 remote = bytes32(uint256(uint160(address(shareOFT))));
        vm.prank(owner);
        composer.setTrustedRemote(REMOTE_EID, remote);
        
        vm.prank(owner);
        shareOFTAdapter.setTrustedRemote(REMOTE_EID, remote);
        
        vm.prank(owner);
        shareOFT.setTrustedRemote(LOCAL_EID, bytes32(uint256(uint160(address(shareOFTAdapter)))));
        
        // Set remote contracts on endpoint
        lzEndpoint.setRemoteContract(REMOTE_EID, address(shareOFT));
    }
    
    function testDeposit() public {
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        vm.deal(user, 1 ether);
        IOVaultComposer.DepositParams memory params = IOVaultComposer.DepositParams({
            assets: DEPOSIT_AMOUNT,
            dstEid: REMOTE_EID,
            receiver: receiver
        });
        
        vm.prank(user);
        composer.deposit{value: 0.001 ether}(params, options);
        
        // Verify: Composer immediately sends OFT tokens cross-chain via sendTo()
        // So composer should have NO OFT tokens left (they were burned during send)
        assertEq(shareOFTAdapter.balanceOf(address(composer)), 0, "Composer should have sent all OFT tokens");
        
        // Simulate LayerZero delivery to spoke chain
        // The sender should be the trusted remote (shareOFTAdapter), not the composer
        uint256 expectedShares = DEPOSIT_AMOUNT; // 1:1 for initial deposit
        bytes memory payload = abi.encode(user, expectedShares);
        vm.prank(address(lzEndpoint));
        shareOFT.lzReceive(
            LOCAL_EID,
            bytes32(uint256(uint160(address(shareOFTAdapter)))), // sender is the adapter
            payload,
            address(0),
            ""
        );
        
        // User should have received shares on spoke chain
        assertEq(shareOFT.balanceOf(user), expectedShares, "User should have shares on spoke");
    }
    
    function testDepositRevertsIfZeroAmount() public {
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        IOVaultComposer.DepositParams memory params = IOVaultComposer.DepositParams({
            assets: 0,
            dstEid: REMOTE_EID,
            receiver: receiver
        });
        
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert(USDXVaultComposerSync.ZeroAmount.selector);
        composer.deposit{value: 0.001 ether}(params, options);
    }
    
    function testDepositRevertsIfInvalidRemote() public {
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        IOVaultComposer.DepositParams memory params = IOVaultComposer.DepositParams({
            assets: DEPOSIT_AMOUNT,
            dstEid: 99999, // Invalid EID
            receiver: receiver
        });
        
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert(USDXVaultComposerSync.InvalidRemote.selector);
        composer.deposit{value: 0.001 ether}(params, options);
    }
    
    function testRedeem() public {
        // Redeem functionality is not fully implemented in the current composer
        // The composer focuses on deposits (sendTo). Redeem would require additional
        // spoke-side contracts to handle the reverse flow.
        // This test is kept as a placeholder for future implementation.
        
        // For now, just verify the redeem function exists and has basic validation
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert(); // Will revert because user has no shares
        composer.redeem{value: 0.001 ether}(
            IOVaultComposer.RedeemParams({
                shares: DEPOSIT_AMOUNT,
                dstEid: REMOTE_EID,
                receiver: receiver
            }),
            options
        );
    }
    
    function testSetTrustedRemote() public {
        bytes32 remote = bytes32(uint256(uint160(user)));
        
        vm.prank(owner);
        composer.setTrustedRemote(REMOTE_EID, remote);
        
        assertEq(composer.trustedRemotes(REMOTE_EID), remote);
    }
    
    function testSetTrustedRemoteRevertsIfNotOwner() public {
        bytes32 remote = bytes32(uint256(uint160(user)));
        
        vm.prank(user);
        vm.expectRevert();
        composer.setTrustedRemote(REMOTE_EID, remote);
    }
}
