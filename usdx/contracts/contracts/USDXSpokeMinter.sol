// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {USDXToken} from "./USDXToken.sol";

/**
 * @title USDXSpokeMinter
 * @author USDX Protocol
 * @notice Spoke chain contract that allows users to mint USDX using hub chain positions
 * @dev Deployed on spoke chains (Polygon, Arbitrum, etc.) - NOT on hub chain
 * 
 * For MVP/Hackathon:
 * - Simplified version with direct position tracking
 * - In production, this would verify cross-chain positions via OVault/Yield Routes
 */
contract USDXSpokeMinter is AccessControl, Pausable, ReentrancyGuard {
    // ============ State Variables ============
    
    /// @notice USDX token address on this spoke chain
    USDXToken public immutable usdxToken;
    
    /// @notice Tracks user positions on hub chain (for MVP)
    /// @dev In production, this would query OVault/Yield Routes via cross-chain
    mapping(address => uint256) public hubPositions;
    
    /// @notice Tracks USDX minted per user on this spoke chain
    mapping(address => uint256) public mintedPerUser;
    
    /// @notice Total USDX minted on this spoke chain
    uint256 public totalMinted;
    
    // ============ Roles ============
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    // ============ Events ============
    
    event Minted(address indexed user, uint256 amount, uint256 hubPosition);
    event Burned(address indexed user, uint256 amount);
    event HubPositionUpdated(address indexed user, uint256 newPosition, address indexed updater);
    
    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientPosition();
    error ExceedsPosition();
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the spoke minter
     * @param _usdxToken USDX token address on this spoke chain
     * @param _admin Admin address
     */
    constructor(address _usdxToken, address _admin) {
        if (_usdxToken == address(0) || _admin == address(0)) {
            revert ZeroAddress();
        }
        
        usdxToken = USDXToken(_usdxToken);
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MANAGER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(POSITION_UPDATER_ROLE, _admin);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Mints USDX on spoke chain using hub chain position
     * @param amount Amount of USDX to mint
     * @dev User must have sufficient position on hub chain
     */
    function mint(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        
        uint256 hubPosition = hubPositions[msg.sender];
        uint256 alreadyMinted = mintedPerUser[msg.sender];
        
        if (hubPosition == 0) revert InsufficientPosition();
        if (alreadyMinted + amount > hubPosition) revert ExceedsPosition();
        
        // Update tracking
        mintedPerUser[msg.sender] += amount;
        totalMinted += amount;
        
        // Mint USDX on this spoke chain
        usdxToken.mint(msg.sender, amount);
        
        emit Minted(msg.sender, amount, hubPosition);
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
     * @notice Updates user's hub chain position (MVP - manual update)
     * @param user User address
     * @param position New position amount on hub chain
     * @dev In production, this would be called by cross-chain oracle/relayer
     */
    function updateHubPosition(address user, uint256 position) 
        external 
        onlyRole(POSITION_UPDATER_ROLE) 
    {
        if (user == address(0)) revert ZeroAddress();
        
        hubPositions[user] = position;
        
        emit HubPositionUpdated(user, position, msg.sender);
    }
    
    /**
     * @notice Batch updates hub positions (gas efficient)
     * @param users Array of user addresses
     * @param positions Array of position amounts
     */
    function batchUpdateHubPositions(address[] calldata users, uint256[] calldata positions)
        external
        onlyRole(POSITION_UPDATER_ROLE)
    {
        require(users.length == positions.length, "Array length mismatch");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == address(0)) revert ZeroAddress();
            hubPositions[users[i]] = positions[i];
            emit HubPositionUpdated(users[i], positions[i], msg.sender);
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
     * @notice Gets user's available minting capacity
     * @param user User address
     * @return available Amount of USDX user can still mint
     */
    function getAvailableMintAmount(address user) external view returns (uint256 available) {
        uint256 hubPosition = hubPositions[user];
        uint256 alreadyMinted = mintedPerUser[user];
        
        if (hubPosition <= alreadyMinted) {
            return 0;
        }
        
        return hubPosition - alreadyMinted;
    }
    
    /**
     * @notice Gets user's hub position
     * @param user User address
     * @return position User's position on hub chain
     */
    function getHubPosition(address user) external view returns (uint256 position) {
        return hubPositions[user];
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
