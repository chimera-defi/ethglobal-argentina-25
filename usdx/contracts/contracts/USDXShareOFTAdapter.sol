// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {USDXYearnVaultWrapper} from "./USDXYearnVaultWrapper.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";
import {IOFT} from "./interfaces/IOFT.sol";

/**
 * @title USDXShareOFTAdapter
 * @notice OFTAdapter for USDX vault shares on hub chain
 * @dev Transforms ERC-4626 vault shares into omnichain fungible tokens using LayerZero
 * 
 * This contract implements the lockbox model where:
 * - Shares are locked in the vault wrapper
 * - Representative tokens are minted/burned on spoke chains
 * - Cross-chain transfers are handled via LayerZero
 * 
 * NOTE: This is a simplified implementation. In production, you would use
 * LayerZero's official OFTAdapter contract from their SDK.
 */
contract USDXShareOFTAdapter is ERC20, Ownable {
    USDXYearnVaultWrapper public immutable vault;
    ILayerZeroEndpoint public immutable lzEndpoint;
    
    uint32 public immutable localEid; // Local endpoint ID
    
    // Mapping to track locked shares per user
    mapping(address => uint256) public lockedShares;
    
    // Cross-chain state
    mapping(uint32 => bytes32) public trustedRemotes; // dstEid => remote address
    
    // ============ Events ============
    
    event SharesLocked(address indexed user, uint256 shares);
    event SharesUnlocked(address indexed user, uint256 shares);
    event CrossChainSent(uint32 dstEid, bytes32 to, uint256 shares);
    event CrossChainReceived(uint32 srcEid, bytes32 from, uint256 shares);
    
    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientShares();
    error InvalidRemote();
    error Unauthorized();
    
    constructor(
        address _vault,
        address _lzEndpoint,
        uint32 _localEid,
        address _owner
    ) ERC20("USDX Vault Shares", "USDX-SHARES") Ownable(_owner) {
        if (_vault == address(0) || _lzEndpoint == address(0) || _owner == address(0)) {
            revert ZeroAddress();
        }
        
        vault = USDXYearnVaultWrapper(_vault);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        localEid = _localEid;
    }
    
    /**
     * @notice Lock shares and mint representative tokens
     * @param shares Amount of shares to lock
     */
    function lockShares(uint256 shares) external {
        if (shares == 0) revert ZeroAmount();
        
        // Transfer shares from user (vault is ERC20)
        IERC20(address(vault)).transferFrom(msg.sender, address(this), shares);
        
        // Lock shares
        lockedShares[msg.sender] += shares;
        
        // Mint representative tokens
        _mint(msg.sender, shares);
        
        emit SharesLocked(msg.sender, shares);
    }
    
    /**
     * @notice Lock shares from a specific address (for composer)
     * @param from Address to lock shares from
     * @param shares Amount of shares to lock
     */
    function lockSharesFrom(address from, uint256 shares) external {
        if (shares == 0) revert ZeroAmount();
        if (from == address(0)) revert ZeroAddress();
        
        // Transfer shares from specified address
        IERC20(address(vault)).transferFrom(from, address(this), shares);
        
        // Lock shares
        lockedShares[from] += shares;
        
        // Mint representative tokens to from address
        _mint(from, shares);
        
        emit SharesLocked(from, shares);
    }
    
    /**
     * @notice Unlock shares by burning representative tokens
     * @param shares Amount of shares to unlock
     */
    function unlockShares(uint256 shares) external {
        if (shares == 0) revert ZeroAmount();
        if (lockedShares[msg.sender] < shares) revert InsufficientShares();
        
        // Burn representative tokens
        _burn(msg.sender, shares);
        
        // Unlock shares
        lockedShares[msg.sender] -= shares;
        
        // Transfer shares back to user
        IERC20(address(vault)).transfer(msg.sender, shares);
        
        emit SharesUnlocked(msg.sender, shares);
    }
    
    /**
     * @notice Send shares cross-chain via LayerZero
     * @param dstEid Destination endpoint ID
     * @param to Destination address (bytes32 format)
     * @param shares Amount of shares to send
     * @param options LayerZero options
     */
    function send(
        uint32 dstEid,
        bytes32 to,
        uint256 shares,
        bytes calldata options
    ) external payable {
        if (shares == 0) revert ZeroAmount();
        if (trustedRemotes[dstEid] == bytes32(0)) revert InvalidRemote();
        
        // Burn tokens from sender
        _burn(msg.sender, shares);
        
        // Build payload
        bytes memory payload = abi.encode(msg.sender, shares);
        
        // Send via LayerZero
        ILayerZeroEndpoint.MessagingParams memory params = ILayerZeroEndpoint.MessagingParams({
            dstEid: dstEid,
            receiver: to,
            message: payload,
            options: options,
            payInLzToken: false
        });
        
        lzEndpoint.send{value: msg.value}(params, msg.sender);
        
        emit CrossChainSent(dstEid, to, shares);
    }
    
    /**
     * @notice Receive shares from cross-chain transfer
     * @dev Called by LayerZero endpoint
     */
    function lzReceive(
        uint32 srcEid,
        bytes32 sender,
        bytes calldata payload,
        address executor,
        bytes calldata extraData
    ) external payable {
        // Verify caller is LayerZero endpoint
        if (msg.sender != address(lzEndpoint)) revert Unauthorized();
        
        // Verify trusted remote
        if (trustedRemotes[srcEid] != sender) revert InvalidRemote();
        
        // Decode payload
        (address user, uint256 shares) = abi.decode(payload, (address, uint256));
        
        // Lock shares in vault (they should already be locked on source chain)
        // For simplicity, we mint representative tokens here
        // In production, you'd need proper accounting
        _mint(user, shares);
        
        emit CrossChainReceived(srcEid, sender, shares);
    }
    
    /**
     * @notice Set trusted remote for cross-chain communication
     * @param dstEid Destination endpoint ID
     * @param remote Remote address (bytes32 format)
     */
    function setTrustedRemote(uint32 dstEid, bytes32 remote) external onlyOwner {
        trustedRemotes[dstEid] = remote;
    }
    
    /**
     * @notice Get vault address
     */
    function getVault() external view returns (address) {
        return address(vault);
    }
    
    /**
     * @notice Get total locked shares
     */
    function getTotalLockedShares() external view returns (uint256) {
        return vault.balanceOf(address(this));
    }
}
