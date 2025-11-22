// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockYieldVault
 * @notice Simulates a yield-generating vault (like Yearn) for MVP testing
 * @dev For MVP: Simulates yield accrual with a simple interest rate
 */
contract MockYieldVault is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset; // USDC
    uint256 public totalAssets;
    uint256 public constant YIELD_RATE_BPS = 500; // 5% APY (500 basis points)
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public lastUpdateTime;
    uint256 public yieldAccrued;

    constructor(address _asset) ERC20("Mock Yield Vault Shares", "MYVS") {
        asset = IERC20(_asset);
        lastUpdateTime = block.timestamp;
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        _accrueYield();
        asset.safeTransferFrom(msg.sender, address(this), assets);
        totalAssets += assets;
        
        shares = convertToShares(assets);
        _mint(receiver, shares);
        
        return shares;
    }

    function withdraw(uint256 shares, address receiver) external returns (uint256 assets) {
        _accrueYield();
        assets = convertToAssets(shares);
        
        _burn(msg.sender, shares);
        totalAssets -= assets;
        
        asset.safeTransfer(receiver, assets);
        
        return assets;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        if (totalSupply() == 0 || totalAssets == 0) {
            return assets;
        }
        return (assets * totalSupply()) / totalAssets;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        if (totalSupply() == 0) {
            return shares;
        }
        return (shares * totalAssets) / totalSupply();
    }

    function _accrueYield() internal {
        if (totalAssets == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        if (timeElapsed == 0) return;

        // Simple interest calculation: yield = principal * rate * time
        uint256 yield = (totalAssets * YIELD_RATE_BPS * timeElapsed) / (SECONDS_PER_YEAR * 10000);
        
        totalAssets += yield;
        yieldAccrued += yield;
        lastUpdateTime = block.timestamp;
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }
}
