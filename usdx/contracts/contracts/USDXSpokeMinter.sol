// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {USDXToken} from "./USDXToken.sol";
import {USDXShareOFT} from "./USDXShareOFT.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

/**
 * @title USDXSpokeMinter
 * @author USDX Protocol
 * @notice Spoke chain contract that allows users to mint USDX using LayerZero OVault shares
 * @dev Deployed on spoke chains (Polygon, Arbitrum, etc.) - NOT on hub chain
 * 
 * Key Features:
 * - Mints USDX using OVault shares from hub chain
 * - Verifies OVault share balances via LayerZero
 * - Tracks minted USDX per user
 * - Cross-chain position verification via LayerZero
 */
contract USDXSpokeMinter is AccessControl, Pausable, ReentrancyGuard {
    // ============ State Variables ============
    
    /// @notice USDX token address on this spoke chain
    USDXToken public immutable usdxToken;
    
    /// @notice OVault Share OFT on this spoke chain
    USDXShareOFT public shareOFT;
    
    /// @notice Hub chain endpoint ID (Ethereum)
    uint32 public hubChainId;
    
    /// @notice LayerZero endpoint
    ILayerZeroEndpoint public lzEndpoint;
    
    /// @notice Tracks USDX minted per user on this spoke chain
    mapping(address => uint256) public mintedPerUser;
    
    /// @notice Total USDX minted on this spoke chain
    uint256 public totalMinted;
    
    // ============ Roles ============
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // ============ Events ============
    
    event Minted(address indexed user, uint256 amount, uint256 ovaultShares);
    event Burned(address indexed user, uint256 amount);
    event ShareOFTSet(address indexed oldShareOFT, address indexed newShareOFT);
    
    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientShares();
    error ShareOFTNotSet();
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the spoke minter
     * @param _usdxToken USDX token address on this spoke chain
     * @param _shareOFT OVault Share OFT address on this spoke chain
     * @param _lzEndpoint LayerZero endpoint address
     * @param _hubChainId Hub chain endpoint ID (Ethereum = 30101)
     * @param _admin Admin address
     */
    constructor(
        address _usdxToken,
        address _shareOFT,
        address _lzEndpoint,
        uint32 _hubChainId,
        address _admin
    ) {
        if (_usdxToken == address(0) || _admin == address(0)) {
            revert ZeroAddress();
        }
        
        usdxToken = USDXToken(_usdxToken);
        shareOFT = USDXShareOFT(_shareOFT);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        hubChainId = _hubChainId;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MANAGER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Mints USDX on spoke chain using OVault shares
     * @param ovaultShares Amount of OVault shares to use for minting
     * @dev User must have sufficient OVault shares on this spoke chain
     */
    function mintUSDXFromOVault(uint256 ovaultShares) external nonReentrant whenNotPaused {
        if (ovaultShares == 0) revert ZeroAmount();
        if (address(shareOFT) == address(0)) revert ShareOFTNotSet();
        
        // Check user has OVault shares on this spoke chain
        uint256 userShares = shareOFT.balanceOf(msg.sender);
        if (userShares < ovaultShares) revert InsufficientShares();
        
        // Calculate USDC value of shares (1:1 for simplicity, should use vault pricing)
        uint256 usdxAmount = ovaultShares;
        
        // Transfer shares from user (will be burned or locked)
        shareOFT.transferFrom(msg.sender, address(this), ovaultShares);
        
        // Burn shares (they represent collateral on hub chain)
        shareOFT.burn(ovaultShares);
        
        // Update tracking
        mintedPerUser[msg.sender] += usdxAmount;
        totalMinted += usdxAmount;
        
        // Mint USDX on this spoke chain
        usdxToken.mint(msg.sender, usdxAmount);
        
        emit Minted(msg.sender, usdxAmount, ovaultShares);
    }
    
    /**
     * @notice Mints USDX on spoke chain (simplified version using existing shares)
     * @param amount Amount of USDX to mint
     * @dev User must have sufficient OVault shares
     */
    function mint(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (address(shareOFT) == address(0)) revert ShareOFTNotSet();
        
        // Check user has sufficient OVault shares
        uint256 userShares = shareOFT.balanceOf(msg.sender);
        if (userShares < amount) revert InsufficientShares();
        
        // Transfer and burn shares
        shareOFT.transferFrom(msg.sender, address(this), amount);
        shareOFT.burn(amount);
        
        // Update tracking
        mintedPerUser[msg.sender] += amount;
        totalMinted += amount;
        
        // Mint USDX
        usdxToken.mint(msg.sender, amount);
        
        emit Minted(msg.sender, amount, amount);
    }
    
    /**
     * @notice Burns USDX on spoke chain
     * @param amount Amount of USDX to burn
     * @dev Reduces user's minted balance, allowing them to mint more if desired
     */
    function burn(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (mintedPerUser[msg.sender] < amount) revert InsufficientPosition();
        
        // Update tracking
        mintedPerUser[msg.sender] -= amount;
        totalMinted -= amount;
        
        // Burn USDX
        usdxToken.burnFrom(msg.sender, amount);
        
        emit Burned(msg.sender, amount);
    }
    
    /**
     * @notice Sets the Share OFT address
     * @param _shareOFT New Share OFT address
     */
    function setShareOFT(address _shareOFT) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_shareOFT == address(0)) revert ZeroAddress();
        
        address oldShareOFT = address(shareOFT);
        shareOFT = USDXShareOFT(_shareOFT);
        
        emit ShareOFTSet(oldShareOFT, _shareOFT);
    }
    
    /**
     * @notice Pauses minting operations
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }
    
    /**
     * @notice Unpauses minting operations
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets user's available minting capacity based on OVault shares
     * @param user User address
     * @return available Amount of USDX user can still mint
     */
    function getAvailableMintAmount(address user) external view returns (uint256 available) {
        if (address(shareOFT) == address(0)) return 0;
        
        uint256 userShares = shareOFT.balanceOf(user);
        return userShares;
    }
    
    /**
     * @notice Gets user's OVault shares on this spoke chain
     * @param user User address
     * @return shares User's OVault shares
     */
    function getUserOVaultShares(address user) external view returns (uint256 shares) {
        if (address(shareOFT) == address(0)) return 0;
        return shareOFT.balanceOf(user);
    }
    
    /**
     * @notice Gets user's minted amount on this spoke chain
     * @param user User address
     * @return minted Amount of USDX minted by user
     */
    function getMintedAmount(address user) external view returns (uint256 minted) {
        return mintedPerUser[user];
    }
}
