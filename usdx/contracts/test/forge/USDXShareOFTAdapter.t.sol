// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXShareOFTAdapter} from "../../contracts/USDXShareOFTAdapter.sol";
import {USDXYearnVaultWrapper} from "../../contracts/USDXYearnVaultWrapper.sol";
import {MockUSDC} from "../../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../../contracts/mocks/MockYearnVault.sol";
import {MockLayerZeroEndpoint} from "../../contracts/mocks/MockLayerZeroEndpoint.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDXShareOFTAdapterTest is Test {
    USDXShareOFTAdapter adapter;
    USDXYearnVaultWrapper vault;
    MockUSDC usdc;
    MockYearnVault yearnVault;
    MockLayerZeroEndpoint lzEndpoint;
    
    address user = address(0x1234);
    address owner = address(this);
    
    uint32 constant LOCAL_EID = 30101;
    uint32 constant REMOTE_EID = 30109;
    
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
        
        // Deploy adapter
        adapter = new USDXShareOFTAdapter(
            address(vault),
            address(lzEndpoint),
            LOCAL_EID,
            owner
        );
        
        // Setup user
        usdc.mint(user, INITIAL_BALANCE);
        vm.prank(user);
        usdc.approve(address(vault), type(uint256).max);
        
        // User deposits into vault to get shares
        vm.prank(user);
        vault.deposit(DEPOSIT_AMOUNT, user);
        
        // Approve adapter to transfer shares
        vm.prank(user);
        IERC20(address(vault)).approve(address(adapter), type(uint256).max);
    }
    
    function testLockShares() public {
        uint256 shares = vault.balanceOf(user);
        
        vm.prank(user);
        adapter.lockShares(shares);
        
        assertEq(adapter.balanceOf(user), shares, "User should have OFT tokens");
        assertEq(adapter.lockedShares(user), shares, "Shares should be locked");
        assertEq(vault.balanceOf(address(adapter)), shares, "Adapter should hold shares");
    }
    
    function testLockSharesZeroAmount() public {
        vm.prank(user);
        vm.expectRevert(USDXShareOFTAdapter.ZeroAmount.selector);
        adapter.lockShares(0);
    }
    
    function testUnlockShares() public {
        uint256 shares = vault.balanceOf(user);
        
        // Lock shares first
        vm.prank(user);
        adapter.lockShares(shares);
        
        // Unlock shares
        vm.prank(user);
        adapter.unlockShares(shares);
        
        assertEq(adapter.balanceOf(user), 0, "User should have no OFT tokens");
        assertEq(adapter.lockedShares(user), 0, "Shares should be unlocked");
        assertEq(vault.balanceOf(user), shares, "User should have shares back");
    }
    
    function testUnlockSharesInsufficient() public {
        vm.prank(user);
        vm.expectRevert(USDXShareOFTAdapter.InsufficientShares.selector);
        adapter.unlockShares(1000e6);
    }
    
    function testLockSharesFrom() public {
        uint256 shares = vault.balanceOf(user);
        
        // Approve adapter to transfer shares FROM user
        vm.prank(user);
        IERC20(address(vault)).approve(address(adapter), shares);
        
        // Lock shares from user (adapter transfers from user)
        adapter.lockSharesFrom(user, shares);
        
        assertEq(adapter.balanceOf(user), shares, "User should have OFT tokens");
        assertEq(adapter.lockedShares(user), shares, "Shares should be locked for user");
        assertEq(vault.balanceOf(address(adapter)), shares, "Adapter should hold shares");
        assertEq(vault.balanceOf(user), 0, "User should have no vault shares");
    }
    
    function testUnlockSharesFor() public {
        uint256 shares = vault.balanceOf(user);
        
        // Lock shares first
        vm.prank(user);
        adapter.lockShares(shares);
        
        // Unlock shares for user
        adapter.unlockSharesFor(user, shares);
        
        assertEq(adapter.balanceOf(user), 0);
        assertEq(vault.balanceOf(user), shares);
    }
    
    function testSendCrossChain() public {
        uint256 shares = vault.balanceOf(user);
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        // Lock shares first
        vm.prank(user);
        adapter.lockShares(shares);
        
        // Set trusted remote
        bytes32 remote = bytes32(uint256(uint160(address(adapter))));
        vm.prank(owner);
        adapter.setTrustedRemote(REMOTE_EID, remote);
        
        // Set remote contract on endpoint
        lzEndpoint.setRemoteContract(REMOTE_EID, address(adapter));
        
        // Give user ETH for LayerZero fees
        vm.deal(user, 1 ether);
        
        // Send cross-chain
        vm.prank(user);
        adapter.send{value: 0.001 ether}(REMOTE_EID, receiver, shares, options);
        
        // OFT tokens should be burned
        assertEq(adapter.balanceOf(user), 0);
    }
    
    function testLzReceive() public {
        uint256 shares = 1000e6;
        bytes32 sender = bytes32(uint256(uint160(address(adapter))));
        bytes memory payload = abi.encode(user, shares);
        
        // Set trusted remote
        vm.prank(owner);
        adapter.setTrustedRemote(REMOTE_EID, sender);
        
        // Call lzReceive
        vm.prank(address(lzEndpoint));
        adapter.lzReceive(REMOTE_EID, sender, payload, address(0), "");
        
        // OFT tokens should be minted
        assertEq(adapter.balanceOf(user), shares);
    }
    
    function testLzReceiveRevertsIfNotEndpoint() public {
        bytes32 sender = bytes32(uint256(uint160(address(adapter))));
        bytes memory payload = abi.encode(user, 1000e6);
        
        vm.prank(user);
        vm.expectRevert(USDXShareOFTAdapter.Unauthorized.selector);
        adapter.lzReceive(REMOTE_EID, sender, payload, address(0), "");
    }
    
    function testSetTrustedRemote() public {
        bytes32 remote = bytes32(uint256(uint160(user)));
        
        vm.prank(owner);
        adapter.setTrustedRemote(REMOTE_EID, remote);
        
        assertEq(adapter.trustedRemotes(REMOTE_EID), remote);
    }
    
    function testGetTotalLockedShares() public {
        uint256 shares = vault.balanceOf(user);
        
        vm.prank(user);
        adapter.lockShares(shares);
        
        assertEq(adapter.getTotalLockedShares(), shares);
    }
}
