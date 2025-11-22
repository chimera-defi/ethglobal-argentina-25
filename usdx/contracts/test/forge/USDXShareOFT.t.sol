// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXShareOFT} from "../../contracts/USDXShareOFT.sol";
import {MockLayerZeroEndpoint} from "../../contracts/mocks/MockLayerZeroEndpoint.sol";

contract USDXShareOFTTest is Test {
    USDXShareOFT shareOFT;
    MockLayerZeroEndpoint lzEndpoint;
    
    address owner = address(this);
    address minter = address(0x1234);
    address user = address(0x5678);
    
    uint32 constant LOCAL_EID = 30109; // Polygon
    uint32 constant REMOTE_EID = 30101; // Ethereum
    
    uint256 constant MINT_AMOUNT = 1000e6;
    
    function setUp() public {
        lzEndpoint = new MockLayerZeroEndpoint(LOCAL_EID);
        
        shareOFT = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            address(lzEndpoint),
            LOCAL_EID,
            owner
        );
        
        // Set minter
        shareOFT.setMinter(minter);
    }
    
    function testMint() public {
        vm.prank(minter);
        shareOFT.mint(user, MINT_AMOUNT);
        
        assertEq(shareOFT.balanceOf(user), MINT_AMOUNT);
        assertEq(shareOFT.totalSupply(), MINT_AMOUNT);
    }
    
    function testMintRevertsIfNotMinter() public {
        vm.prank(user);
        vm.expectRevert(USDXShareOFT.Unauthorized.selector);
        shareOFT.mint(user, MINT_AMOUNT);
    }
    
    function testBurn() public {
        vm.prank(minter);
        shareOFT.mint(user, MINT_AMOUNT);
        
        vm.prank(user);
        shareOFT.burn(MINT_AMOUNT / 2);
        
        assertEq(shareOFT.balanceOf(user), MINT_AMOUNT / 2);
        assertEq(shareOFT.totalSupply(), MINT_AMOUNT / 2);
    }
    
    function testSendCrossChain() public {
        bytes32 receiver = bytes32(uint256(uint160(user)));
        bytes memory options = "";
        
        // Mint tokens
        vm.prank(minter);
        shareOFT.mint(user, MINT_AMOUNT);
        
        // Set trusted remote
        bytes32 remote = bytes32(uint256(uint160(address(shareOFT))));
        vm.prank(owner);
        shareOFT.setTrustedRemote(REMOTE_EID, remote);
        
        // Set remote contract
        lzEndpoint.setRemoteContract(REMOTE_EID, address(shareOFT));
        
        // Give user ETH for LayerZero fees
        vm.deal(user, 1 ether);
        
        // Send cross-chain
        vm.prank(user);
        shareOFT.send{value: 0.001 ether}(REMOTE_EID, receiver, MINT_AMOUNT, options);
        
        // Tokens should be burned
        assertEq(shareOFT.balanceOf(user), 0);
    }
    
    function testLzReceive() public {
        bytes32 sender = bytes32(uint256(uint160(address(shareOFT))));
        bytes memory payload = abi.encode(user, MINT_AMOUNT);
        
        // Set trusted remote
        vm.prank(owner);
        shareOFT.setTrustedRemote(REMOTE_EID, sender);
        
        // Call lzReceive
        vm.prank(address(lzEndpoint));
        shareOFT.lzReceive(REMOTE_EID, sender, payload, address(0), "");
        
        // Tokens should be minted
        assertEq(shareOFT.balanceOf(user), MINT_AMOUNT);
    }
    
    function testSetMinter() public {
        address newMinter = address(0x9999);
        
        vm.prank(owner);
        shareOFT.setMinter(newMinter);
        
        assertEq(shareOFT.minter(), newMinter);
        
        // New minter can mint
        vm.prank(newMinter);
        shareOFT.mint(user, MINT_AMOUNT);
        
        assertEq(shareOFT.balanceOf(user), MINT_AMOUNT);
    }
    
    function testSetMinterRevertsIfNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        shareOFT.setMinter(user);
    }
}
