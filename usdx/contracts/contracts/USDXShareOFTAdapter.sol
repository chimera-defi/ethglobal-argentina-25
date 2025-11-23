// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {USDXYearnVaultWrapper} from "./USDXYearnVaultWrapper.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

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
contract USDXShareOFTAdapter is ERC20, ERC20Burnable, Ownable {
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
        
        // Burn representative tokens (must have balance)
        if (balanceOf(msg.sender) < shares) revert InsufficientShares();
        _burn(msg.sender, shares);
        
        // Unlock shares
        lockedShares[msg.sender] -= shares;
        
        // Transfer shares back to user
        IERC20(address(vault)).transfer(msg.sender, shares);
        
        emit SharesUnlocked(msg.sender, shares);
    }
    
    /**
     * @notice Unlock shares for a specific address (for composer)
     * @param account Address to unlock shares for
     * @param shares Amount of shares to unlock
     */
    function unlockSharesFor(address account, uint256 shares) external {
        if (shares == 0) revert ZeroAmount();
        if (account == address(0)) revert ZeroAddress();
        if (lockedShares[account] < shares) revert InsufficientShares();
        
        // Burn representative tokens from account (must have balance)
        if (balanceOf(account) < shares) revert InsufficientShares();
        _burn(account, shares);
        
        // Unlock shares
        lockedShares[account] -= shares;
        
        // Transfer shares back to account
        IERC20(address(vault)).transfer(account, shares);
        
        emit SharesUnlocked(account, shares);
    }
    
    /**
     * @notice Burn tokens (inherited from ERC20Burnable)
     * @param amount Amount to burn
     */
    function burn(uint256 amount) public override {
        // Allow burning without unlocking shares (for cross-chain transfers)
        _burn(msg.sender, amount);
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
     * @notice Send shares cross-chain with custom receiver (for composer/contract use)
     * @param from Address to burn OFT tokens from (must have approved this contract)
     * @param dstEid Destination endpoint ID
     * @param to Receiver address on destination chain (bytes32 format)
     * @param shares Amount of shares to send
     * @param options LayerZero options
     */
    function sendTo(
        address from,
        uint32 dstEid,
        bytes32 to,
        uint256 shares,
        bytes calldata options
    ) external payable {
        if (shares == 0) revert ZeroAmount();
        if (trustedRemotes[dstEid] == bytes32(0)) revert InvalidRemote();
        
        // Burn tokens from 'from' address
        // Only require allowance if sender is not the owner
        if (from != msg.sender) {
            _spendAllowance(from, msg.sender, shares);
        }
        _burn(from, shares);
        
        // Build payload with custom receiver
        address receiver = address(uint160(uint256(to)));
        bytes memory payload = abi.encode(receiver, shares);
        
        // Send via LayerZero
        ILayerZeroEndpoint.MessagingParams memory params = ILayerZeroEndpoint.MessagingParams({
            dstEid: dstEid,
            receiver: trustedRemotes[dstEid],
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
     * @dev This mints OFT tokens representing shares that are locked on hub chain
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
        if (trustedRemotes[srcEid] == bytes32(0) || trustedRemotes[srcEid] != sender) {
            revert InvalidRemote();
        }
        
        // Decode payload
        (address user, uint256 shares) = abi.decode(payload, (address, uint256));
        
        if (user == address(0)) revert ZeroAddress();
        if (shares == 0) revert ZeroAmount();
        
        // Mint OFT tokens representing shares locked on hub chain
        // Shares are locked in the adapter on hub chain, OFT tokens represent them here
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
