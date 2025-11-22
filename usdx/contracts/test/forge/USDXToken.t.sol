// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../../contracts/USDXToken.sol";
import "../../contracts/interfaces/ILayerZeroEndpoint.sol";
import "../../contracts/mocks/MockLayerZeroEndpoint.sol";

contract USDXTokenTest is Test {
    USDXToken public token;
    MockLayerZeroEndpoint public lzEndpoint;
    
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    uint32 constant LOCAL_EID = 30101; // Ethereum
    uint32 constant REMOTE_EID = 30109; // Polygon
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    function setUp() public {
        // Deploy mock LayerZero endpoint
        lzEndpoint = new MockLayerZeroEndpoint(LOCAL_EID);
        
        // Deploy token
        token = new USDXToken(admin);
        
        // Grant minter role to minter address
        vm.prank(admin);
        token.grantRole(MINTER_ROLE, minter);
        
        // Set LayerZero endpoint
        vm.prank(admin);
        token.setLayerZeroEndpoint(address(lzEndpoint), LOCAL_EID);
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
    
    // LayerZero Tests
    function testSetLayerZeroEndpoint() public {
        MockLayerZeroEndpoint newEndpoint = new MockLayerZeroEndpoint(LOCAL_EID);
        
        vm.prank(admin);
        token.setLayerZeroEndpoint(address(newEndpoint), LOCAL_EID);
        
        assertEq(address(token.lzEndpoint()), address(newEndpoint));
        assertEq(token.localEid(), LOCAL_EID);
    }
    
    function testSetLayerZeroEndpointRevertsIfNotAdmin() public {
        MockLayerZeroEndpoint newEndpoint = new MockLayerZeroEndpoint(LOCAL_EID);
        
        vm.prank(user1);
        vm.expectRevert();
        token.setLayerZeroEndpoint(address(newEndpoint), LOCAL_EID);
    }
    
    function testSetTrustedRemote() public {
        bytes32 remote = bytes32(uint256(uint160(user2)));
        
        vm.prank(admin);
        token.setTrustedRemote(REMOTE_EID, remote);
        
        assertEq(token.trustedRemotes(REMOTE_EID), remote);
    }
    
    function testSendCrossChain() public {
        uint256 amount = 1000 * 10**6;
        bytes32 receiver = bytes32(uint256(uint160(user2)));
        bytes memory options = "";
        
        // Mint tokens
        vm.prank(minter);
        token.mint(user1, amount);
        
        // Set trusted remote
        bytes32 remote = bytes32(uint256(uint160(address(token)))); // Self for testing
        vm.prank(admin);
        token.setTrustedRemote(REMOTE_EID, remote);
        
        // Set remote contract on endpoint
        lzEndpoint.setRemoteContract(REMOTE_EID, address(token));
        
        // Give user1 ETH for LayerZero fees
        vm.deal(user1, 1 ether);
        
        // Send cross-chain
        vm.prank(user1);
        token.sendCrossChain{value: 0.001 ether}(REMOTE_EID, receiver, amount, options);
        
        // Tokens should be burned
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.totalSupply(), 0);
    }
    
    function testSendCrossChainRevertsIfNoEndpoint() public {
        USDXToken tokenNoEndpoint = new USDXToken(admin);
        vm.prank(admin);
        tokenNoEndpoint.grantRole(MINTER_ROLE, minter);
        
        vm.prank(minter);
        tokenNoEndpoint.mint(user1, 1000 * 10**6);
        
        vm.prank(user1);
        vm.expectRevert(USDXToken.ZeroAddress.selector);
        tokenNoEndpoint.sendCrossChain(REMOTE_EID, bytes32(uint256(uint160(user2))), 1000 * 10**6, "");
    }
    
    function testSendCrossChainRevertsIfInvalidRemote() public {
        uint256 amount = 1000 * 10**6;
        
        vm.prank(minter);
        token.mint(user1, amount);
        
        vm.prank(user1);
        vm.expectRevert(USDXToken.InvalidRemote.selector);
        token.sendCrossChain(REMOTE_EID, bytes32(uint256(uint160(user2))), amount, "");
    }
    
    function testLzReceive() public {
        uint256 amount = 1000 * 10**6;
        bytes32 sender = bytes32(uint256(uint160(address(token))));
        bytes memory payload = abi.encode(user1, amount);
        
        // Set trusted remote
        vm.prank(admin);
        token.setTrustedRemote(REMOTE_EID, sender);
        
        // Call lzReceive (simulating LayerZero endpoint call)
        vm.prank(address(lzEndpoint));
        token.lzReceive(REMOTE_EID, sender, payload, address(0), "");
        
        // Tokens should be minted
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }
    
    function testLzReceiveRevertsIfNotEndpoint() public {
        bytes32 sender = bytes32(uint256(uint160(address(token))));
        bytes memory payload = abi.encode(user1, 1000 * 10**6);
        
        vm.prank(user1);
        vm.expectRevert(USDXToken.Unauthorized.selector);
        token.lzReceive(REMOTE_EID, sender, payload, address(0), "");
    }
    
    function testLzReceiveRevertsIfInvalidRemote() public {
        bytes32 sender = bytes32(uint256(uint160(user2)));
        bytes memory payload = abi.encode(user1, 1000 * 10**6);
        
        vm.prank(address(lzEndpoint));
        vm.expectRevert(USDXToken.InvalidRemote.selector);
        token.lzReceive(REMOTE_EID, sender, payload, address(0), "");
    }
    
    function testLzReceiveRevertsIfZeroAddress() public {
        bytes32 sender = bytes32(uint256(uint160(address(token))));
        bytes memory payload = abi.encode(address(0), 1000 * 10**6);
        
        vm.prank(admin);
        token.setTrustedRemote(REMOTE_EID, sender);
        
        vm.prank(address(lzEndpoint));
        vm.expectRevert(USDXToken.ZeroAddress.selector);
        token.lzReceive(REMOTE_EID, sender, payload, address(0), "");
    }
}
