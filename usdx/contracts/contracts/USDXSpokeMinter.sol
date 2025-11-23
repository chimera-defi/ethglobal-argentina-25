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
 * @dev Deployed on spoke chains (Polygon, Arbitrum, Arc, etc.) - NOT on hub chain
 * 
 * Key Features:
 * - Mints USDX using OVault shares from hub chain (LayerZero chains)
 * - Verifies OVault share balances via LayerZero (when available)
 * - Supports Arc chain without LayerZero (uses alternative verification)
 * - Tracks minted USDX per user
 * - Cross-chain position verification via LayerZero (when available)
 * 
 * Arc Chain Support:
 * - LayerZero is not supported on Arc chain
 * - shareOFT and lzEndpoint can be address(0) for Arc
 * - Minting on Arc uses alternative verification (oracle or Bridge Kit events)
 */
contract USDXSpokeMinter is AccessControl, Pausable, ReentrancyGuard {
    // ============ State Variables ============
    
    /// @notice USDX token address on this spoke chain
    USDXToken public immutable usdxToken;
    
    /// @notice OVault Share OFT on this spoke chain (optional, address(0) for Arc)
    USDXShareOFT public shareOFT;
    
    /// @notice Hub chain endpoint ID (Ethereum)
    uint32 public hubChainId;
    
    /// @notice LayerZero endpoint (optional, address(0) for Arc)
    ILayerZeroEndpoint public lzEndpoint;
    
    /// @notice Tracks USDX minted per user on this spoke chain
    mapping(address => uint256) public mintedPerUser;
    
    /// @notice Total USDX minted on this spoke chain
    uint256 public totalMinted;
    
    /// @notice Tracks verified hub positions per user (for Arc chain)
    /// @dev Maps user address to their verified USDC balance on hub chain
    mapping(address => uint256) public verifiedHubPositions;
    
    // ============ Roles ============
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    // ============ Events ============
    
    event Minted(address indexed user, uint256 amount, uint256 ovaultShares);
    event Burned(address indexed user, uint256 amount);
    event ShareOFTSet(address indexed oldShareOFT, address indexed newShareOFT);
    event HubPositionUpdated(address indexed user, uint256 oldPosition, uint256 newPosition);
    
    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientShares();
    error ShareOFTNotSet();
    error InsufficientHubPosition();
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the spoke minter
     * @param _usdxToken USDX token address on this spoke chain
     * @param _shareOFT OVault Share OFT address on this spoke chain (address(0) for Arc)
     * @param _lzEndpoint LayerZero endpoint address (address(0) for Arc)
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
        // shareOFT and lzEndpoint can be address(0) for Arc chain
        if (_shareOFT != address(0)) {
            shareOFT = USDXShareOFT(_shareOFT);
        }
        if (_lzEndpoint != address(0)) {
            lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        }
        hubChainId = _hubChainId;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MANAGER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(POSITION_UPDATER_ROLE, _admin);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Mints USDX on spoke chain using OVault shares
     * @param ovaultShares Amount of OVault shares to use for minting
     * @dev User must have sufficient OVault shares on this spoke chain (LayerZero chains)
     *      OR sufficient verified hub position (Arc chain)
     */
    function mintUSDXFromOVault(uint256 ovaultShares) external nonReentrant whenNotPaused {
        if (ovaultShares == 0) revert ZeroAmount();
        
        uint256 usdxAmount = ovaultShares;
        
        // Check if LayerZero is available (standard spoke chains)
        if (address(shareOFT) != address(0)) {
            // LayerZero path: Use shareOFT balance
            uint256 userShares = shareOFT.balanceOf(msg.sender);
            if (userShares < ovaultShares) revert InsufficientShares();
            
            // Transfer shares from user (will be burned or locked)
            shareOFT.transferFrom(msg.sender, address(this), ovaultShares);
            
            // Burn shares (they represent collateral on hub chain)
            shareOFT.burn(ovaultShares);
        } else {
            // Arc path: Use verified hub positions
            if (verifiedHubPositions[msg.sender] < ovaultShares) {
                revert InsufficientHubPosition();
            }
            
            // Deduct from verified hub position
            verifiedHubPositions[msg.sender] -= ovaultShares;
        }
        
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
     * @dev User must have sufficient OVault shares (LayerZero chains) OR verified hub position (Arc)
     */
    function mint(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        
        // Check if LayerZero is available (standard spoke chains)
        if (address(shareOFT) != address(0)) {
            // LayerZero path: Use shareOFT balance
            uint256 userShares = shareOFT.balanceOf(msg.sender);
            if (userShares < amount) revert InsufficientShares();
            
            // Transfer and burn shares
            shareOFT.transferFrom(msg.sender, address(this), amount);
            shareOFT.burn(amount);
        } else {
            // Arc path: Use verified hub positions
            if (verifiedHubPositions[msg.sender] < amount) {
                revert InsufficientHubPosition();
            }
            
            // Deduct from verified hub position
            verifiedHubPositions[msg.sender] -= amount;
        }
        
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
     *      For Arc chain: Restores verified position when burning (frees up minting capacity)
     */
    function burn(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (mintedPerUser[msg.sender] < amount) revert InsufficientShares();
        
        // Update tracking
        mintedPerUser[msg.sender] -= amount;
        totalMinted -= amount;
        
        // For Arc chain: Restore verified position when burning
        // This allows users to mint again up to their verified position
        if (address(shareOFT) == address(0)) {
            verifiedHubPositions[msg.sender] += amount;
        }
        
        // Burn USDX
        usdxToken.burnFrom(msg.sender, amount);
        
        emit Burned(msg.sender, amount);
    }
    
    /**
     * @notice Sets the Share OFT address
     * @param _shareOFT New Share OFT address (can be address(0) for Arc)
     */
    function setShareOFT(address _shareOFT) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldShareOFT = address(shareOFT);
        
        if (_shareOFT == address(0)) {
            // Clear shareOFT (for Arc chain)
            // We need to use assembly or a different approach since shareOFT is not nullable
            // For now, we'll require non-zero address - Arc should be deployed without shareOFT
            revert ZeroAddress();
        } else {
            shareOFT = USDXShareOFT(_shareOFT);
        }
        
        emit ShareOFTSet(oldShareOFT, _shareOFT);
    }
    
    /**
     * @notice Updates verified hub position for a user (Arc chain)
     * @param user User address
     * @param position New verified hub position amount
     * @dev Only callable by POSITION_UPDATER_ROLE (oracle or Bridge Kit event processor)
     */
    function updateHubPosition(address user, uint256 position) external onlyRole(POSITION_UPDATER_ROLE) {
        uint256 oldPosition = verifiedHubPositions[user];
        verifiedHubPositions[user] = position;
        emit HubPositionUpdated(user, oldPosition, position);
    }
    
    /**
     * @notice Batch updates verified hub positions (Arc chain)
     * @param users Array of user addresses
     * @param positions Array of verified hub position amounts
     * @dev Only callable by POSITION_UPDATER_ROLE
     */
    function batchUpdateHubPositions(
        address[] calldata users,
        uint256[] calldata positions
    ) external onlyRole(POSITION_UPDATER_ROLE) {
        require(users.length == positions.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < users.length; i++) {
            uint256 oldPosition = verifiedHubPositions[users[i]];
            verifiedHubPositions[users[i]] = positions[i];
            emit HubPositionUpdated(users[i], oldPosition, positions[i]);
        }
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
     * @notice Gets user's available minting capacity based on OVault shares or verified hub position
     * @param user User address
     * @return available Amount of USDX user can still mint
     */
    function getAvailableMintAmount(address user) external view returns (uint256 available) {
        if (address(shareOFT) != address(0)) {
            // LayerZero path: Use shareOFT balance
            return shareOFT.balanceOf(user);
        } else {
            // Arc path: Use verified hub position
            return verifiedHubPositions[user];
        }
    }
    
    /**
     * @notice Gets user's OVault shares on this spoke chain (LayerZero chains only)
     * @param user User address
     * @return shares User's OVault shares (0 for Arc chain)
     */
    function getUserOVaultShares(address user) external view returns (uint256 shares) {
        if (address(shareOFT) == address(0)) return 0;
        return shareOFT.balanceOf(user);
    }
    
    /**
     * @notice Gets user's verified hub position (Arc chain only)
     * @param user User address
     * @return position User's verified hub position in USDC
     */
    function getVerifiedHubPosition(address user) external view returns (uint256 position) {
        return verifiedHubPositions[user];
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
