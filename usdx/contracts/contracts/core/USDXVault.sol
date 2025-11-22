// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUSDXVault.sol";
import "../interfaces/IUSDXToken.sol";
import "./MockYieldVault.sol";

/**
 * @title USDXVault
 * @notice Hub chain vault that manages USDC deposits and yield generation
 * @dev For MVP: Uses MockYieldVault to simulate yield accrual
 */
contract USDXVault is AccessControl, ReentrancyGuard, IUSDXVault {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    IERC20 public immutable usdc;
    IUSDXToken public immutable usdxToken;
    MockYieldVault public immutable yieldVault;

    uint256 public totalCollateral;
    uint256 public totalUSDXMinted;
    
    mapping(address => uint256) public userCollateral;
    mapping(address => uint256) public userShares;

    event Deposit(address indexed user, uint256 usdcAmount, uint256 usdxAmount);
    event Withdrawal(address indexed user, uint256 usdxAmount, uint256 usdcAmount);
    event YieldAccrued(uint256 amount);

    constructor(
        address _usdc,
        address _usdxToken,
        address _yieldVault
    ) {
        usdc = IERC20(_usdc);
        usdxToken = IUSDXToken(_usdxToken);
        yieldVault = MockYieldVault(_yieldVault);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function depositUSDC(uint256 amount) external nonReentrant returns (uint256 usdxAmount) {
        return depositUSDCFor(msg.sender, amount);
    }

    function depositUSDCFor(address user, uint256 amount) public nonReentrant returns (uint256 usdxAmount) {
        require(amount > 0, "USDXVault: amount must be greater than 0");
        
        // Transfer USDC from user
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve and deposit into yield vault
        usdc.forceApprove(address(yieldVault), amount);
        uint256 shares = yieldVault.deposit(amount, address(this));
        
        // Update state
        userCollateral[user] += amount;
        userShares[user] += shares;
        totalCollateral += amount;
        
        // Mint USDX 1:1 with USDC
        usdxAmount = amount;
        totalUSDXMinted += usdxAmount;
        usdxToken.mint(user, usdxAmount);
        
        emit Deposit(user, amount, usdxAmount);
        return usdxAmount;
    }

    function withdrawUSDC(uint256 usdxAmount) external nonReentrant returns (uint256 usdcAmount) {
        return withdrawUSDCTo(msg.sender, usdxAmount);
    }

    function withdrawUSDCTo(address to, uint256 usdxAmount) public nonReentrant returns (uint256 usdcAmount) {
        require(usdxAmount > 0, "USDXVault: amount must be greater than 0");
        require(userCollateral[msg.sender] >= usdxAmount, "USDXVault: insufficient collateral");
        
        // Calculate shares to withdraw (accounting for yield)
        uint256 userTotalShares = userShares[msg.sender];
        uint256 userTotalCollateral = userCollateral[msg.sender];
        
        // Calculate proportional shares
        uint256 sharesToWithdraw = (userTotalShares * usdxAmount) / userTotalCollateral;
        
        // Withdraw from yield vault
        usdcAmount = yieldVault.withdraw(sharesToWithdraw, address(this));
        
        // Transfer USDC to user
        usdc.safeTransfer(to, usdcAmount);
        
        // Burn USDX
        usdxToken.burnFrom(msg.sender, usdxAmount);
        
        // Update state
        userCollateral[msg.sender] -= usdxAmount;
        userShares[msg.sender] -= sharesToWithdraw;
        totalCollateral -= usdxAmount;
        totalUSDXMinted -= usdxAmount;
        
        emit Withdrawal(msg.sender, usdxAmount, usdcAmount);
        return usdcAmount;
    }

    function getUserCollateral(address user) external view returns (uint256) {
        return userCollateral[user];
    }

    function getTotalCollateral() external view returns (uint256) {
        return totalCollateral;
    }

    function getTotalUSDXMinted() external view returns (uint256) {
        return totalUSDXMinted;
    }

    function getCollateralRatio() external view returns (uint256) {
        if (totalUSDXMinted == 0) return 1e18; // 1:1 ratio
        return (totalCollateral * 1e18) / totalUSDXMinted;
    }

    function getUserYieldPosition(address user) external view returns (uint256 shares, uint256 assets) {
        shares = userShares[user];
        assets = yieldVault.convertToAssets(shares);
    }
}
