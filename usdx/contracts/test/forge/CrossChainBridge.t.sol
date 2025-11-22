// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/USDXToken.sol";
import "../../contracts/core/CrossChainBridge.sol";

contract CrossChainBridgeTest is Test {
    USDXToken public usdxToken;
    CrossChainBridge public bridge;
    
    address public admin;
    address public relayer;
    address public user;
    uint256 public constant CHAIN_ID = 137; // Polygon
    
    uint256 public constant DEST_CHAIN_ID = 42161; // Arbitrum

    function setUp() public {
        admin = address(0x1);
        relayer = address(0x2);
        user = address(0x3);
        
        usdxToken = new USDXToken(admin);
        bridge = new CrossChainBridge(address(usdxToken), CHAIN_ID);
        
        // Grant roles
        // USDXToken admin is set in constructor, so impersonate admin
        vm.startPrank(admin);
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(bridge));
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), admin);
        usdxToken.mint(user, 10000e18);
        vm.stopPrank();
        
        // Bridge admin is deployer (test contract), so we can grant directly
        bridge.grantRole(bridge.RELAYER_ROLE(), relayer);
        bridge.setSupportedChain(DEST_CHAIN_ID, true);
    }

    function testTransferCrossChain() public {
        uint256 amount = 1000e18;
        address destinationAddress = address(0x4);
        
        vm.startPrank(user);
        // Approve bridge to burn tokens
        usdxToken.approve(address(bridge), amount);
        bytes32 transferId = bridge.transferCrossChain(amount, DEST_CHAIN_ID, destinationAddress);
        vm.stopPrank();
        
        // Check USDX was burned
        assertEq(usdxToken.balanceOf(user), 10000e18 - amount);
        
        // Check transfer record
        CrossChainBridge.PendingTransfer memory transfer = bridge.getPendingTransfer(transferId);
        assertEq(transfer.user, user);
        assertEq(transfer.amount, amount);
        assertEq(transfer.destinationChainId, DEST_CHAIN_ID);
        assertEq(transfer.destinationAddress, destinationAddress);
        assertFalse(transfer.completed);
    }

    function testCompleteTransfer() public {
        uint256 amount = 1000e18;
        address destinationAddress = address(0x4);
        uint256 sourceChainId = CHAIN_ID;
        
        // Initiate transfer
        vm.startPrank(user);
        // Approve bridge to burn tokens
        usdxToken.approve(address(bridge), amount);
        bytes32 transferId = bridge.transferCrossChain(amount, DEST_CHAIN_ID, destinationAddress);
        vm.stopPrank();
        
        // Complete transfer on destination chain
        vm.prank(relayer);
        bridge.completeTransfer(transferId, sourceChainId, user, amount, destinationAddress);
        
        // Check USDX was minted on destination
        assertEq(usdxToken.balanceOf(destinationAddress), amount);
    }

    function testTransferRevertsIfUnsupportedChain() public {
        uint256 unsupportedChainId = 999;
        
        vm.prank(user);
        vm.expectRevert("CrossChainBridge: unsupported destination chain");
        bridge.transferCrossChain(1000e18, unsupportedChainId, address(0x4));
    }

    function testCompleteTransferRevertsIfReplay() public {
        uint256 amount = 1000e18;
        address destinationAddress = address(0x4);
        uint256 sourceChainId = CHAIN_ID;
        
        // Initiate transfer
        vm.startPrank(user);
        // Approve bridge to burn tokens
        usdxToken.approve(address(bridge), amount);
        bytes32 transferId = bridge.transferCrossChain(amount, DEST_CHAIN_ID, destinationAddress);
        vm.stopPrank();
        
        // Complete transfer
        vm.prank(relayer);
        bridge.completeTransfer(transferId, sourceChainId, user, amount, destinationAddress);
        
        // Try to complete again
        vm.prank(relayer);
        vm.expectRevert("CrossChainBridge: transfer already processed");
        bridge.completeTransfer(transferId, sourceChainId, user, amount, destinationAddress);
    }
}
