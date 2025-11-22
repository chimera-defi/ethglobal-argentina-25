// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../../contracts/USDXToken.sol";

contract USDXTokenTest is Test {
    USDXToken public token;
    
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    function setUp() public {
        // Deploy token
        token = new USDXToken(admin);
        
        // Grant minter role to minter address
        vm.prank(admin);
        token.grantRole(MINTER_ROLE, minter);
    }
    
    function testDeployment() public view {
        assertEq(token.name(), "USDX Stablecoin");
        assertEq(token.symbol(), "USDX");
        assertEq(token.decimals(), 6);
        assertEq(token.totalSupply(), 0);
    }
    
    function testAdminHasAllRoles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(MINTER_ROLE, admin));
        assertTrue(token.hasRole(BURNER_ROLE, admin));
        assertTrue(token.hasRole(PAUSER_ROLE, admin));
    }
    
    function testMint() public {
        uint256 amount = 1000 * 10**6; // 1000 USDX
        
        vm.prank(minter);
        token.mint(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }
    
    function testMintRevertsIfNotMinter() public {
        uint256 amount = 1000 * 10**6;
        
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, amount);
    }
    
    function testMintRevertsIfZeroAddress() public {
        uint256 amount = 1000 * 10**6;
        
        vm.prank(minter);
        vm.expectRevert("USDXToken: mint to zero address");
        token.mint(address(0), amount);
    }
    
    function testMintRevertsIfZeroAmount() public {
        vm.prank(minter);
        vm.expectRevert("USDXToken: mint amount is zero");
        token.mint(user1, 0);
    }
    
    function testBurn() public {
        uint256 amount = 1000 * 10**6;
        
        // Mint tokens first
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Burn tokens
        vm.prank(user1);
        token.burn(amount / 2);
        
        assertEq(token.balanceOf(user1), amount / 2);
        assertEq(token.totalSupply(), amount / 2);
    }
    
    function testBurnFrom() public {
        uint256 amount = 1000 * 10**6;
        
        // Mint tokens first
        vm.prank(minter);
        token.mint(user1, amount);
        
        // User1 approves admin to burn (standard ERC20 behavior)
        vm.prank(user1);
        token.approve(admin, amount / 2);
        
        // Admin can burn using allowance
        vm.prank(admin);
        token.burnFrom(user1, amount / 2);
        
        assertEq(token.balanceOf(user1), amount / 2);
        assertEq(token.totalSupply(), amount / 2);
    }
    
    function testBurnFromRole() public {
        uint256 amount = 1000 * 10**6;
        
        // Mint tokens first
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Admin with BURNER_ROLE can burn without approval
        vm.prank(admin);
        token.burnFromRole(user1, amount / 2);
        
        assertEq(token.balanceOf(user1), amount / 2);
        assertEq(token.totalSupply(), amount / 2);
    }
    
    function testBurnForCrossChain() public {
        uint256 amount = 1000 * 10**6;
        uint256 destinationChainId = 137; // Polygon
        
        // Mint tokens first
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Burn for cross-chain transfer
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit USDXToken.CrossChainBurn(user1, amount, destinationChainId, user2);
        token.burnForCrossChain(amount, destinationChainId, user2);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.totalSupply(), 0);
    }
    
    function testMintFromCrossChain() public {
        uint256 amount = 1000 * 10**6;
        uint256 sourceChainId = 1; // Ethereum
        bytes32 messageHash = keccak256("test");
        
        // Mint from cross-chain
        vm.prank(minter);
        vm.expectEmit(true, true, true, true);
        emit USDXToken.CrossChainMint(user1, amount, sourceChainId, messageHash);
        token.mintFromCrossChain(user1, amount, sourceChainId, messageHash);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }
    
    function testPause() public {
        uint256 amount = 1000 * 10**6;
        
        // Mint tokens
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Pause contract
        vm.prank(admin);
        token.pause();
        
        // Transfers should revert when paused
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, amount);
    }
    
    function testUnpause() public {
        uint256 amount = 1000 * 10**6;
        
        // Mint tokens
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Pause and unpause
        vm.prank(admin);
        token.pause();
        
        vm.prank(admin);
        token.unpause();
        
        // Transfers should work after unpause
        vm.prank(user1);
        token.transfer(user2, amount);
        
        assertEq(token.balanceOf(user2), amount);
    }
    
    function testTransfer() public {
        uint256 amount = 1000 * 10**6;
        
        // Mint tokens
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Transfer tokens
        vm.prank(user1);
        token.transfer(user2, amount / 2);
        
        assertEq(token.balanceOf(user1), amount / 2);
        assertEq(token.balanceOf(user2), amount / 2);
    }
    
    function testApproveAndTransferFrom() public {
        uint256 amount = 1000 * 10**6;
        
        // Mint tokens
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Approve user2 to spend tokens
        vm.prank(user1);
        token.approve(user2, amount);
        
        // Transfer tokens using transferFrom
        vm.prank(user2);
        token.transferFrom(user1, user2, amount / 2);
        
        assertEq(token.balanceOf(user1), amount / 2);
        assertEq(token.balanceOf(user2), amount / 2);
    }
    
    function testFuzzMint(uint256 amount) public {
        // Bound amount to reasonable values (up to 1 billion USDX)
        amount = bound(amount, 1, 1_000_000_000 * 10**6);
        
        vm.prank(minter);
        token.mint(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }
    
    function testFuzzTransfer(uint256 amount) public {
        // Bound amount
        amount = bound(amount, 1, 1_000_000_000 * 10**6);
        
        // Mint tokens
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Transfer tokens
        vm.prank(user1);
        token.transfer(user2, amount);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), amount);
    }
}
