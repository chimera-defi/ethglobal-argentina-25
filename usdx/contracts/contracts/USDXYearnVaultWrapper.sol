// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IYearnVault} from "./interfaces/IYearnVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title USDXYearnVaultWrapper
 * @notice ERC-4626 wrapper for Yearn USDC vault, enabling OVault integration
 * @dev This contract wraps Yearn vault to make it ERC-4626 compatible for LayerZero OVault
 * 
 * Key Features:
 * - Wraps Yearn USDC vault as ERC-4626 standard vault
 * - Enables OVault integration for cross-chain yield access
 * - Maintains 1:1 relationship with Yearn vault shares
 * - Supports deposit, redeem, and yield accrual
 */
contract USDXYearnVaultWrapper is ERC4626, Ownable, ReentrancyGuard, Pausable {
    IYearnVault public immutable yearnVault;
    IERC20 public immutable underlyingAsset; // USDC

    // ============ Events ============
    
    event YearnDeposit(uint256 assets, uint256 yearnShares);
    event YearnRedeem(uint256 yearnShares, uint256 assets);

    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error TransferFailed();

    constructor(
        address _asset, // USDC address
        address _yearnVault, // Yearn USDC vault address
        string memory _name,
        string memory _symbol
    ) ERC4626(IERC20(_asset)) Ownable(msg.sender) {
        if (_asset == address(0) || _yearnVault == address(0)) {
            revert ZeroAddress();
        }
        
        underlyingAsset = IERC20(_asset);
        yearnVault = IYearnVault(_yearnVault);
        
        // Approve Yearn vault to spend USDC
        IERC20(_asset).approve(_yearnVault, type(uint256).max);
    }

    /**
     * @notice Deposit assets into Yearn vault and mint shares
     * @param assets Amount of assets to deposit
     * @param receiver Address to receive shares
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Transfer assets from user
        if (!underlyingAsset.transferFrom(msg.sender, address(this), assets)) {
            revert TransferFailed();
        }

        // Deposit into Yearn vault
        uint256 yearnShares = yearnVault.deposit(assets, address(this));

        // Mint ERC-4626 shares 1:1 with Yearn shares (simplified for MVP)
        // In production, this would use proper conversion based on vault pricing
        shares = yearnShares;
        _mint(receiver, shares);

        emit YearnDeposit(assets, yearnShares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Redeem shares for underlying assets
     * @param shares Amount of shares to redeem
     * @param receiver Address to receive assets
     * @param owner Address that owns the shares
     * @return assets Amount of assets withdrawn
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        if (shares == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Burn shares
        _burn(owner, shares);

        // Redeem from Yearn vault
        assets = yearnVault.redeem(shares, address(this), address(this));

        // Transfer assets to receiver
        if (!underlyingAsset.transfer(receiver, assets)) {
            revert TransferFailed();
        }

        emit YearnRedeem(shares, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @notice Total assets managed by vault
     * @return Total assets in Yearn vault
     */
    function totalAssets() public view override returns (uint256) {
        uint256 yearnShares = yearnVault.balanceOf(address(this));
        if (yearnShares == 0) return 0;
        return yearnVault.convertToAssets(yearnShares);
    }

    /**
     * @notice Convert assets to shares using Yearn vault pricing
     * @dev This maintains 1:1 relationship with Yearn shares
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        // Direct conversion: wrapper shares = Yearn shares
        // This maintains 1:1 relationship for simplicity
        return yearnVault.convertToShares(assets);
    }

    /**
     * @notice Convert shares to assets using Yearn vault pricing
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return shares;
        }
        
        // Use Yearn's conversion for consistency
        return yearnVault.convertToAssets(shares);
    }

    /**
     * @notice Pause contract (emergency only)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Get Yearn vault address
     */
    function getYearnVault() external view returns (address) {
        return address(yearnVault);
    }
}
