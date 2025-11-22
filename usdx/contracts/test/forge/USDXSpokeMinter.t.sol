// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/USDXToken.sol";
import "../../contracts/core/USDXSpokeMinter.sol";
import "../../contracts/core/MockUSDC.sol";
import "../../contracts/core/MockYieldVault.sol";
import "../../contracts/core/USDXVault.sol";

contract USDXSpokeMinterTest is Test {
    USDXToken public usdxToken;
    USDXVault public hubVault;
    USDXSpokeMinter public spokeMinter;
    
    address public admin;
    address public relayer;
    address public user;
    uint256 public constant HUB_CHAIN_ID = 1;

    function setUp() public {
        admin = address(0x1);
        relayer = address(0x2);
        user = address(0x3);
        
        // Deploy hub chain contracts (deployer is test contract, admin gets role in constructor)
        MockUSDC usdc = new MockUSDC();
        usdxToken = new USDXToken(admin);
        MockYieldVault yieldVault = new MockYieldVault(address(usdc));
        hubVault = new USDXVault(
            address(usdc),
            address(usdxToken),
            address(yieldVault)
        );
        
        // Deploy spoke minter
        spokeMinter = new USDXSpokeMinter(
            address(usdxToken),
            address(hubVault),
            HUB_CHAIN_ID
        );
        
        // Grant roles (impersonate admin)
        vm.startPrank(admin);
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(hubVault));
        usdxToken.grantRole(usdxToken.VAULT_ROLE(), address(spokeMinter));
        spokeMinter.grantRole(spokeMinter.RELAYER_ROLE(), relayer);
        vm.stopPrank();
    }

    function testMintFromHubPosition() public {
        uint256 amount = 1000e18;
        uint256 hubPosition = 2000e6; // User has 2000 USDC on hub
        bytes32 mintId = keccak256("test-mint-1");
        
        vm.prank(relayer);
        spokeMinter.mintFromHubPosition(user, amount, hubPosition, mintId);
        
        assertEq(usdxToken.balanceOf(user), amount);
        assertEq(spokeMinter.getMintedUSDX(user), amount);
    }

    function testMintRevertsIfInsufficientPosition() public {
        uint256 amount = 1000e18;
        uint256 hubPosition = 500e6; // Less than amount
        bytes32 mintId = keccak256("test-mint-2");
        
        vm.prank(relayer);
        vm.expectRevert("USDXSpokeMinter: insufficient hub position");
        spokeMinter.mintFromHubPosition(user, amount, hubPosition, mintId);
    }

    function testMintRevertsIfReplay() public {
        uint256 amount = 1000e18;
        uint256 hubPosition = 2000e6;
        bytes32 mintId = keccak256("test-mint-3");
        
        vm.prank(relayer);
        spokeMinter.mintFromHubPosition(user, amount, hubPosition, mintId);
        
        // Try to mint again with same mintId
        vm.prank(relayer);
        vm.expectRevert("USDXSpokeMinter: mint already processed");
        spokeMinter.mintFromHubPosition(user, amount, hubPosition, mintId);
    }

    function testMintRevertsIfNotRelayer() public {
        uint256 amount = 1000e18;
        uint256 hubPosition = 2000e6;
        bytes32 mintId = keccak256("test-mint-4");
        
        vm.prank(user);
        vm.expectRevert();
        spokeMinter.mintFromHubPosition(user, amount, hubPosition, mintId);
    }
}
