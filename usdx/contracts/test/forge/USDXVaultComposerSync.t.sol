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
        
        // Verify assets were deposited - shares are locked in adapter immediately
        // Check adapter's locked shares mapping
        assertGt(shareOFTAdapter.lockedShares(address(composer)), 0, "Composer should have locked shares in adapter");
        // Also check adapter's OFT token balance (representative tokens)
        assertGt(shareOFTAdapter.balanceOf(address(composer)), 0, "Composer should have OFT tokens");
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
        // First, deposit to get shares
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        vm.deal(user, 1 ether);
        IOVaultComposer.DepositParams memory depositParams = IOVaultComposer.DepositParams({
            assets: DEPOSIT_AMOUNT,
            dstEid: REMOTE_EID,
            receiver: receiver
        });
        
        vm.prank(user);
        composer.deposit{value: 0.001 ether}(depositParams, options);
        
        // After deposit, shares are locked in adapter for composer
        uint256 shares = shareOFTAdapter.lockedShares(address(composer));
        assertGt(shares, 0, "Composer should have locked shares in adapter");
        
        // Verify composer has adapter OFT tokens (minted when shares were locked)
        assertEq(shareOFTAdapter.balanceOf(address(composer)), shares, "Composer should have adapter OFT tokens");
        
        // Simulate cross-chain receipt: user receives adapter OFT tokens on spoke chain
        // In reality, this would happen via LayerZero - shares are locked in adapter
        // and adapter OFT tokens are minted to user on spoke chain
        // For this test, we transfer adapter OFT tokens from composer to user
        // (simulating that user received them on the spoke chain)
        vm.prank(address(composer));
        IERC20(address(shareOFTAdapter)).transfer(user, shares);
        
        // Verify user now has adapter tokens
        assertEq(shareOFTAdapter.balanceOf(user), shares, "User should have adapter OFT tokens");
        
        // Now redeem - user transfers adapter OFT tokens to composer, which unlocks shares
        // Use a different timestamp to avoid operation ID collision
        vm.warp(block.timestamp + 1);
        
        vm.startPrank(user);
        // Approve composer to transfer adapter OFT tokens
        IERC20(address(shareOFTAdapter)).approve(address(composer), shares);
        vm.deal(user, 1 ether);
        
        IOVaultComposer.RedeemParams memory redeemParams = IOVaultComposer.RedeemParams({
            shares: shares,
            dstEid: REMOTE_EID,
            receiver: receiver
        });
        
        composer.redeem{value: 0.001 ether}(redeemParams, options);
        vm.stopPrank();
        
        // Verify shares were unlocked from adapter (composer's locked shares decreased)
        // The redeem function unlocks shares and redeems from vault
        // Shares should be unlocked, so locked shares should decrease
        assertEq(shareOFTAdapter.lockedShares(address(composer)), 0, "Composer's locked shares should be unlocked");
        assertEq(shareOFTAdapter.balanceOf(address(composer)), 0, "Composer should have no adapter OFT tokens");
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
