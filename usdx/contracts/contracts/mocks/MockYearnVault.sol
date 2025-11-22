// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/**
 * @title MockYearnVault
 * @notice Mock Yearn V3 vault for testing purposes
 * @dev Simplified ERC-4626 implementation for testing
 */
contract MockYearnVault is ERC20 {
    IERC20 public immutable asset;
    
    // Simulated yield rate (10% APY for testing)
    uint256 public yieldMultiplier = 1e18; // 1.0x initially
    
    constructor(address _asset) ERC20("Yearn USDC Vault", "yUSDC") {
        asset = IERC20(_asset);
    }
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    /**
     * @notice Deposit assets and receive shares
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        require(assets > 0, "Cannot deposit 0");
        
        // Transfer assets from sender
        require(asset.transferFrom(msg.sender, address(this), assets), "Transfer failed");
        
        // Calculate shares (1:1 initially, then based on yield)
        shares = convertToShares(assets);
        
        // Mint shares to receiver
        _mint(receiver, shares);
        
        return shares;
    }
    
    /**
     * @notice Redeem shares for assets
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        require(shares > 0, "Cannot redeem 0");
        require(balanceOf(owner) >= shares, "Insufficient balance");
        
        // Calculate assets
        assets = convertToAssets(shares);
        
        // Burn shares from owner
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        
        // Transfer assets to receiver
        require(asset.transfer(receiver, assets), "Transfer failed");
        
        return assets;
    }
    
    /**
     * @notice Convert assets to shares
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return assets;
        }
        
        return (assets * supply) / totalAssets();
    }
    
    /**
     * @notice Convert shares to assets
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return shares;
        }
        
        return (shares * totalAssets()) / supply;
    }
    
    /**
     * @notice Get total assets (with simulated yield)
     */
    function totalAssets() public view returns (uint256) {
        uint256 balance = asset.balanceOf(address(this));
        return (balance * yieldMultiplier) / 1e18;
    }
    
    /**
     * @notice Simulate yield accrual (for testing)
     */
    function accrueYield(uint256 percentage) external {
        // Increase yield multiplier by percentage (e.g., 10 = 10%)
        yieldMultiplier = yieldMultiplier * (100 + percentage) / 100;
    }
    
    // ERC-4626 preview functions
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }
    
    function previewRedeem(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }
    
    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }
    
    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }
}
