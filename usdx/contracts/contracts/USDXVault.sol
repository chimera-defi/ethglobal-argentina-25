// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IYearnVault} from "./interfaces/IYearnVault.sol";
import {USDXToken} from "./USDXToken.sol";
import {USDXVaultComposerSync} from "./USDXVaultComposerSync.sol";
import {USDXShareOFTAdapter} from "./USDXShareOFTAdapter.sol";
import {USDXYearnVaultWrapper} from "./USDXYearnVaultWrapper.sol";
import {IOVaultComposer} from "./interfaces/IOVaultComposer.sol";

/**
 * @title USDXVault
 * @author USDX Protocol
 * @notice Hub chain vault that manages USDC collateral and mints USDX
 * @dev This is the core vault contract deployed only on the hub chain (Ethereum)
 * 
 * Key Features:
 * - Accepts USDC deposits
 * - Integrates with LayerZero OVault for cross-chain yield access
 * - Deposits USDC into Yearn vault via OVault wrapper
 * - Mints USDX 1:1 against USDC deposits
 * - Configurable yield distribution (treasury/users/buyback)
 * - Withdrawal mechanism with instant USDC redemption
 * - Cross-chain position tracking via LayerZero OVault
 */
contract USDXVault is AccessControl, Pausable, ReentrancyGuard {
    // ============ State Variables ============
    
    /// @notice USDC token address
    IERC20 public immutable usdc;
    
    /// @notice USDX token address
    USDXToken public immutable usdx;
    
    /// @notice OVault Composer for cross-chain operations
    USDXVaultComposerSync public ovaultComposer;
    
    /// @notice OVault Share OFT Adapter
    USDXShareOFTAdapter public shareOFTAdapter;
    
    /// @notice OVault Yearn Wrapper
    USDXYearnVaultWrapper public vaultWrapper;
    
    /// @notice Yearn USDC vault address (optional, can be zero for MVP)
    IYearnVault public yearnVault;
    
    /// @notice Protocol treasury address
    address public treasury;
    
    /// @notice Total USDC deposited by users
    uint256 public totalCollateral;
    
    /// @notice Total USDX minted
    uint256 public totalMinted;
    
    /// @notice User deposits mapping
    mapping(address => uint256) public userDeposits;
    
    /// @notice User OVault shares mapping
    mapping(address => uint256) public userOVaultShares;
    
    /// @notice User Yearn shares mapping (legacy, for backward compatibility)
    mapping(address => uint256) public userYearnShares;
    
    /// @notice Yield distribution mode (0=treasury, 1=users/rebasing, 2=buyback)
    uint8 public yieldDistributionMode;
    
    /// @notice Total yield accumulated
    uint256 public totalYieldAccumulated;
    
    // ============ Constants ============
    
    uint256 private constant PRECISION = 1e18;
    
    // ============ Roles ============
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // ============ Events ============
    
    event Deposited(address indexed user, uint256 usdcAmount, uint256 usdxAmount, uint256 ovaultShares);
    event DepositedViaOVault(address indexed user, uint256 usdcAmount, uint256 ovaultShares);
    event Withdrawn(address indexed user, uint256 usdxAmount, uint256 usdcAmount);
    event YieldDistributionModeUpdated(uint8 oldMode, uint8 newMode);
    event YearnVaultUpdated(address indexed oldVault, address indexed newVault);
    event OVaultComposerUpdated(address indexed oldComposer, address indexed newComposer);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event YieldHarvested(uint256 amount, uint8 distributionMode);
    
    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance();
    error InvalidYieldMode();
    error TransferFailed();
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the USDX Vault
     * @param _usdc USDC token address
     * @param _usdx USDX token address
     * @param _treasury Protocol treasury address
     * @param _admin Admin address
     * @param _ovaultComposer OVault Composer address (can be zero initially)
     * @param _shareOFTAdapter Share OFT Adapter address (can be zero initially)
     * @param _vaultWrapper Vault Wrapper address (can be zero initially)
     */
    constructor(
        address _usdc,
        address _usdx,
        address _treasury,
        address _admin,
        address _ovaultComposer,
        address _shareOFTAdapter,
        address _vaultWrapper
    ) {
        if (_usdc == address(0) || _usdx == address(0) || _treasury == address(0) || _admin == address(0)) {
            revert ZeroAddress();
        }
        
        usdc = IERC20(_usdc);
        usdx = USDXToken(_usdx);
        treasury = _treasury;
        yieldDistributionMode = 0; // Default to treasury
        
        if (_ovaultComposer != address(0)) {
            ovaultComposer = USDXVaultComposerSync(_ovaultComposer);
        }
        if (_shareOFTAdapter != address(0)) {
            shareOFTAdapter = USDXShareOFTAdapter(_shareOFTAdapter);
        }
        if (_vaultWrapper != address(0)) {
            vaultWrapper = USDXYearnVaultWrapper(_vaultWrapper);
        }
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MANAGER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Deposits USDC and mints USDX 1:1
     * @param amount Amount of USDC to deposit
     * @return usdxMinted Amount of USDX minted
     */
    function deposit(uint256 amount) external nonReentrant whenNotPaused returns (uint256 usdxMinted) {
        if (amount == 0) revert ZeroAmount();
        
        // Transfer USDC from user
        if (!usdc.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        // Update accounting
        userDeposits[msg.sender] += amount;
        totalCollateral += amount;
        
        uint256 ovaultShares = 0;
        
        // Use OVault if configured
        if (address(vaultWrapper) != address(0)) {
            // Approve vault wrapper
            usdc.approve(address(vaultWrapper), amount);
            
            // Deposit into OVault wrapper (which deposits into Yearn)
            ovaultShares = vaultWrapper.deposit(amount, msg.sender);
            userOVaultShares[msg.sender] += ovaultShares;
            
            emit DepositedViaOVault(msg.sender, amount, ovaultShares);
        } else if (address(yearnVault) != address(0)) {
            // Fallback to direct Yearn deposit (legacy)
            usdc.approve(address(yearnVault), amount);
            uint256 yearnShares = yearnVault.deposit(amount, address(this));
            userYearnShares[msg.sender] += yearnShares;
            ovaultShares = yearnShares; // For event compatibility
        }
        
        // Mint USDX 1:1
        usdxMinted = amount;
        usdx.mint(msg.sender, usdxMinted);
        totalMinted += usdxMinted;
        
        emit Deposited(msg.sender, amount, usdxMinted, ovaultShares);
        return usdxMinted;
    }
    
    /**
     * @notice Deposits USDC via OVault Composer for cross-chain operations
     * @param amount Amount of USDC to deposit
     * @param dstEid Destination endpoint ID for shares
     * @param receiver Destination receiver address (bytes32 format)
     * @param options LayerZero options
     * @return shares Amount of OVault shares created
     */
    function depositViaOVault(
        uint256 amount,
        uint32 dstEid,
        bytes32 receiver,
        bytes calldata options
    ) external payable nonReentrant whenNotPaused returns (uint256 shares) {
        if (amount == 0) revert ZeroAmount();
        if (address(ovaultComposer) == address(0)) revert ZeroAddress();
        
        // Transfer USDC from user
        if (!usdc.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        // Approve composer
        usdc.approve(address(ovaultComposer), amount);
        
        // Deposit via OVault Composer
        IOVaultComposer.DepositParams memory params = IOVaultComposer.DepositParams({
            assets: amount,
            dstEid: dstEid,
            receiver: receiver
        });
        
        ovaultComposer.deposit{value: msg.value}(params, options);
        
        // Update accounting
        userDeposits[msg.sender] += amount;
        totalCollateral += amount;
        
        // Note: Shares will be sent to destination chain via LayerZero
        // User can query their shares on the destination chain
        
        return shares;
    }
    
    /**
     * @notice Withdraws USDC by burning USDX
     * @param usdxAmount Amount of USDX to burn
     * @return usdcReturned Amount of USDC returned
     */
    function withdraw(uint256 usdxAmount) external nonReentrant whenNotPaused returns (uint256 usdcReturned) {
        if (usdxAmount == 0) revert ZeroAmount();
        if (userDeposits[msg.sender] < usdxAmount) revert InsufficientBalance();
        
        // Calculate USDC to return (1:1 ratio)
        usdcReturned = usdxAmount;
        
        // Withdraw from Yearn if needed
        if (address(yearnVault) != address(0) && userYearnShares[msg.sender] > 0) {
            // Calculate shares to redeem
            uint256 sharesToRedeem = (userYearnShares[msg.sender] * usdxAmount) / userDeposits[msg.sender];
            
            // Redeem from Yearn
            yearnVault.redeem(sharesToRedeem, address(this), address(this));
            userYearnShares[msg.sender] -= sharesToRedeem;
        }
        
        // Update accounting
        userDeposits[msg.sender] -= usdxAmount;
        totalCollateral -= usdxAmount;
        totalMinted -= usdxAmount;
        
        // Burn USDX
        usdx.burnFrom(msg.sender, usdxAmount);
        
        // Transfer USDC back to user
        if (!usdc.transfer(msg.sender, usdcReturned)) {
            revert TransferFailed();
        }
        
        emit Withdrawn(msg.sender, usdxAmount, usdcReturned);
        return usdcReturned;
    }
    
    /**
     * @notice Harvests yield from Yearn vault and distributes according to mode
     * @dev Only callable by manager
     */
    function harvestYield() external onlyRole(MANAGER_ROLE) {
        if (address(yearnVault) == address(0)) return;
        
        // Calculate current value in Yearn
        uint256 currentAssets = yearnVault.convertToAssets(yearnVault.balanceOf(address(this)));
        
        // Calculate yield (current value - total collateral)
        if (currentAssets <= totalCollateral) return;
        
        uint256 yieldAmount = currentAssets - totalCollateral;
        totalYieldAccumulated += yieldAmount;
        
        // Distribute yield based on mode
        if (yieldDistributionMode == 0) {
            // Mode 0: Send to treasury
            _withdrawYieldToTreasury(yieldAmount);
        } else if (yieldDistributionMode == 1) {
            // Mode 1: Keep in vault for users (rebasing)
            // No action needed - users get more USDC per USDX
        } else if (yieldDistributionMode == 2) {
            // Mode 2: Buyback and burn (simplified for MVP)
            _withdrawYieldToTreasury(yieldAmount);
        }
        
        emit YieldHarvested(yieldAmount, yieldDistributionMode);
    }
    
    /**
     * @notice Sets the yield distribution mode
     * @param mode New yield distribution mode (0=treasury, 1=users, 2=buyback)
     */
    function setYieldDistributionMode(uint8 mode) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (mode > 2) revert InvalidYieldMode();
        
        uint8 oldMode = yieldDistributionMode;
        yieldDistributionMode = mode;
        
        emit YieldDistributionModeUpdated(oldMode, mode);
    }
    
    /**
     * @notice Sets the Yearn vault address
     * @param _yearnVault New Yearn vault address
     */
    function setYearnVault(address _yearnVault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldVault = address(yearnVault);
        yearnVault = IYearnVault(_yearnVault);
        
        emit YearnVaultUpdated(oldVault, _yearnVault);
    }
    
    /**
     * @notice Sets the OVault Composer address
     * @param _ovaultComposer New OVault Composer address
     */
    function setOVaultComposer(address _ovaultComposer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldComposer = address(ovaultComposer);
        ovaultComposer = USDXVaultComposerSync(_ovaultComposer);
        
        emit OVaultComposerUpdated(oldComposer, _ovaultComposer);
    }
    
    /**
     * @notice Sets the Share OFT Adapter address
     * @param _shareOFTAdapter New Share OFT Adapter address
     */
    function setShareOFTAdapter(address _shareOFTAdapter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        shareOFTAdapter = USDXShareOFTAdapter(_shareOFTAdapter);
    }
    
    /**
     * @notice Sets the Vault Wrapper address
     * @param _vaultWrapper New Vault Wrapper address
     */
    function setVaultWrapper(address _vaultWrapper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vaultWrapper = USDXYearnVaultWrapper(_vaultWrapper);
    }
    
    /**
     * @notice Sets the treasury address
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_treasury == address(0)) revert ZeroAddress();
        
        address oldTreasury = treasury;
        treasury = _treasury;
        
        emit TreasuryUpdated(oldTreasury, _treasury);
    }
    
    /**
     * @notice Pauses the contract
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }
    
    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Withdraws yield to treasury
     * @param amount Amount of yield to withdraw
     */
    function _withdrawYieldToTreasury(uint256 amount) internal {
        // Calculate shares for this amount
        uint256 shares = yearnVault.convertToShares(amount);
        
        // Redeem shares
        uint256 assetsReceived = yearnVault.redeem(shares, address(this), address(this));
        
        // Transfer to treasury
        if (!usdc.transfer(treasury, assetsReceived)) {
            revert TransferFailed();
        }
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets the collateral ratio (should always be >= 1:1)
     * @return ratio Collateral ratio with 18 decimals
     */
    function getCollateralRatio() external view returns (uint256 ratio) {
        if (totalMinted == 0) return PRECISION;
        return (totalCollateral * PRECISION) / totalMinted;
    }
    
    /**
     * @notice Gets user's deposit balance
     * @param user User address
     * @return balance User's USDC deposit balance
     */
    function getUserBalance(address user) external view returns (uint256 balance) {
        return userDeposits[user];
    }
    
    /**
     * @notice Gets user's Yearn vault shares (legacy)
     * @param user User address
     * @return shares User's Yearn shares
     */
    function getUserYearnShares(address user) external view returns (uint256 shares) {
        return userYearnShares[user];
    }
    
    /**
     * @notice Gets user's OVault shares
     * @param user User address
     * @return shares User's OVault shares
     */
    function getUserOVaultShares(address user) external view returns (uint256 shares) {
        if (address(shareOFTAdapter) != address(0)) {
            return shareOFTAdapter.balanceOf(user);
        }
        return userOVaultShares[user];
    }
    
    /**
     * @notice Gets user's position (for cross-chain syncing)
     * @param user User address
     * @return position User's total position
     */
    function getUserPosition(address user) external view returns (uint256 position) {
        return userDeposits[user];
    }
    
    /**
     * @notice Gets current vault value (USDC + yield if Yearn/OVault is configured)
     * @return value Total value in USDC
     */
    function getTotalValue() external view returns (uint256 value) {
        if (address(vaultWrapper) != address(0)) {
            return vaultWrapper.totalAssets();
        } else if (address(yearnVault) != address(0)) {
            uint256 vaultShares = yearnVault.balanceOf(address(this));
            return yearnVault.convertToAssets(vaultShares);
        }
        
        return totalCollateral;
    }
}
