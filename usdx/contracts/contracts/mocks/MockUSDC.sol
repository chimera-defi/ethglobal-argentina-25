// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @notice Mock USDC token for testing purposes
 * @dev Mimics USDC with 6 decimals and free minting for testing
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}
    
    /**
     * @notice Returns 6 decimals (same as real USDC)
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    /**
     * @notice Allows anyone to mint USDC for testing
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    /**
     * @notice Allows anyone to burn their USDC
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
