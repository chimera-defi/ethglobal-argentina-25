// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IUSDXToken.sol";
import "../interfaces/IUSDXVault.sol";

/**
 * @title USDXSpokeMinter
 * @notice Allows users to mint USDX on spoke chains using their hub chain positions
 * @dev For MVP: Simplified version that verifies positions via a trusted oracle/relayer
 */
contract USDXSpokeMinter is AccessControl, ReentrancyGuard {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    IUSDXToken public immutable usdxToken;
    IUSDXVault public immutable hubVault;
    uint256 public immutable hubChainId;

    // Track minted USDX per user (to prevent double minting)
    mapping(address => uint256) public mintedUSDX;
    mapping(bytes32 => bool) public processedMints; // Prevent replay attacks

    event MintFromPosition(
        address indexed user,
        uint256 amount,
        uint256 hubPosition,
        bytes32 mintId
    );

    constructor(
        address _usdxToken,
        address _hubVault,
        uint256 _hubChainId
    ) {
        usdxToken = IUSDXToken(_usdxToken);
        hubVault = IUSDXVault(_hubVault);
        hubChainId = _hubChainId;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Mint USDX on spoke chain using hub chain position
     * @dev For MVP: Relayer verifies position and calls this function
     * @param user User address
     * @param amount Amount of USDX to mint
     * @param hubPosition User's collateral position on hub chain
     * @param mintId Unique mint identifier to prevent replay
     */
    function mintFromHubPosition(
        address user,
        uint256 amount,
        uint256 hubPosition,
        bytes32 mintId
    ) external onlyRole(RELAYER_ROLE) nonReentrant {
        require(!processedMints[mintId], "USDXSpokeMinter: mint already processed");
        require(amount > 0, "USDXSpokeMinter: amount must be greater than 0");
        require(hubPosition >= amount, "USDXSpokeMinter: insufficient hub position");
        
        processedMints[mintId] = true;
        mintedUSDX[user] += amount;
        
        usdxToken.mint(user, amount);
        
        emit MintFromPosition(user, amount, hubPosition, mintId);
    }

    /**
     * @notice Get total USDX minted by a user on this spoke chain
     */
    function getMintedUSDX(address user) external view returns (uint256) {
        return mintedUSDX[user];
    }
}
