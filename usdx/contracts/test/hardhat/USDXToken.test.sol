// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "hardhat/console.sol";
import "../../contracts/USDXToken.sol";
import "../../contracts/mocks/MockLayerZeroEndpoint.sol";

/**
 * @title USDXToken Hardhat3 Test
 * @notice Example Solidity test using Hardhat3's native Solidity testing
 * @dev This demonstrates Hardhat3's Solidity test capabilities alongside Foundry
 * 
 * Run with: npx hardhat test test/hardhat/USDXToken.test.sol
 * 
 * Note: Hardhat3 Solidity tests use require() assertions and msg.sender for permissions.
 * For more advanced testing (vm.prank, etc.), use Foundry tests or Hardhat3 TypeScript tests.
 */
contract USDXTokenTest {
    USDXToken public token;
    MockLayerZeroEndpoint public lzEndpoint;
    
    address public admin;
    address public minter;
    address public user1;
    
    uint32 constant LOCAL_EID = 30101; // Ethereum
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    // Hardhat3 test setup - runs before each test
    constructor() {
        admin = address(this); // Use contract as admin for simplicity
        minter = address(0x2);
        user1 = address(0x3);
        
        // Deploy mock LayerZero endpoint
        lzEndpoint = new MockLayerZeroEndpoint(LOCAL_EID);
        
        // Deploy token
        token = new USDXToken(admin);
        
        // Grant minter role (admin can do this)
        token.grantRole(MINTER_ROLE, minter);
        
        // Set LayerZero endpoint
        token.setLayerZeroEndpoint(address(lzEndpoint), LOCAL_EID);
    }
    
    function testDeployment() public view {
        require(keccak256(bytes(token.name())) == keccak256(bytes("USDX Stablecoin")), "Name mismatch");
        require(keccak256(bytes(token.symbol())) == keccak256(bytes("USDX")), "Symbol mismatch");
        require(token.decimals() == 6, "Decimals mismatch");
        require(token.totalSupply() == 0, "Initial supply should be 0");
    }
    
    function testAdminHasRoles() public view {
        require(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin), "Admin should have admin role");
        require(token.hasRole(MINTER_ROLE, admin), "Admin should have minter role");
    }
    
    // Note: For tests requiring msg.sender manipulation (like vm.prank),
    // use Foundry tests or Hardhat3 TypeScript tests with network helpers
    // This example shows basic functionality testing
}
