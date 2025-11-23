// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {USDXYearnVaultWrapper} from "./USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapter} from "./USDXShareOFTAdapter.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";
import {IOVaultComposer} from "./interfaces/IOVaultComposer.sol";

/**
 * @title USDXVaultComposerSync
 * @notice Composer for orchestrating USDX OVault operations
 * @dev Handles cross-chain deposits and redemptions using LayerZero
 * 
 * This contract orchestrates:
 * - Cross-chain deposits: Receive assets → Deposit to vault → Send shares to destination
 * - Cross-chain redemptions: Receive shares → Redeem from vault → Send assets to destination
 * 
 * NOTE: This is a simplified implementation. In production, you would use
 * LayerZero's official VaultComposerSync contract from their SDK.
 */
contract USDXVaultComposerSync is Ownable, ReentrancyGuard, IOVaultComposer {
    USDXYearnVaultWrapper public immutable vault;
    USDXShareOFTAdapter public immutable shareOFT;
    IERC20 public immutable assetOFT; // USDC OFT (or standard USDC)
    ILayerZeroEndpoint public immutable lzEndpoint;
    
    uint32 public immutable localEid;
    
    // Cross-chain state
    mapping(uint32 => bytes32) public trustedRemotes;
    
    // Operation tracking
    mapping(bytes32 => bool) public processedOperations;
    
    // ============ Events ============
    
    event DepositInitiated(
        bytes32 indexed operationId,
        address indexed user,
        uint256 assets,
        uint32 dstEid,
        bytes32 receiver
    );
    
    event DepositCompleted(
        bytes32 indexed operationId,
        address indexed user,
        uint256 shares
    );
    
    event RedeemInitiated(
        bytes32 indexed operationId,
        address indexed user,
        uint256 shares,
        uint32 dstEid,
        bytes32 receiver
    );
    
    event RedeemCompleted(
        bytes32 indexed operationId,
        address indexed user,
        uint256 assets
    );
    
    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error InvalidRemote();
    error OperationAlreadyProcessed();
    error Unauthorized();
    error TransferFailed();
    
    constructor(
        address _vault,
        address _shareOFT,
        address _assetOFT,
        address _lzEndpoint,
        uint32 _localEid,
        address _owner
    ) Ownable(_owner) {
        if (_vault == address(0) || _shareOFT == address(0) || 
            _assetOFT == address(0) || _lzEndpoint == address(0) || _owner == address(0)) {
            revert ZeroAddress();
        }
        
        vault = USDXYearnVaultWrapper(_vault);
        shareOFT = USDXShareOFTAdapter(_shareOFT);
        assetOFT = IERC20(_assetOFT);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        localEid = _localEid;
    }
    
    /**
     * @notice Deposit assets and send shares to destination chain
     * @param _params Deposit parameters
     * @param options LayerZero options
     */
    function deposit(
        DepositParams calldata _params,
        bytes calldata options
    ) external payable nonReentrant {
        if (_params.assets == 0) revert ZeroAmount();
        if (trustedRemotes[_params.dstEid] == bytes32(0)) revert InvalidRemote();
        
        // Generate operation ID
        bytes32 operationId = keccak256(
            abi.encodePacked(msg.sender, _params.assets, _params.dstEid, block.timestamp)
        );
        
        if (processedOperations[operationId]) revert OperationAlreadyProcessed();
        processedOperations[operationId] = true;
        
        // Transfer assets from user
        if (!assetOFT.transferFrom(msg.sender, address(this), _params.assets)) {
            revert TransferFailed();
        }
        
        // Approve vault wrapper to spend assets
        assetOFT.approve(address(vault), _params.assets);
        
        // Deposit into vault wrapper (vault is USDXYearnVaultWrapper)
        uint256 shares = vault.deposit(_params.assets, address(this));
        
        // Lock shares in share OFT adapter (this gives us OFT tokens)
        // Vault is ERC4626 which extends ERC20, so we can approve
        IERC20(address(vault)).approve(address(shareOFT), shares);
        shareOFT.lockSharesFrom(address(this), shares);
        
        // Send shares cross-chain using sendTo with custom receiver
        // Composer has OFT tokens and sends them to the user's address on destination chain
        // Note: sendTo encodes the receiver address in the payload, so shares go to _params.receiver
        shareOFT.sendTo{value: msg.value}(
            address(this),      // from: composer has the OFT tokens
            _params.dstEid,     // destination chain
            _params.receiver,   // receiver on destination (user)
            shares,             // amount to send
            options             // LayerZero options
        );
        
        emit DepositInitiated(operationId, msg.sender, _params.assets, _params.dstEid, _params.receiver);
        emit DepositCompleted(operationId, msg.sender, shares);
    }
    
    /**
     * @notice Redeem shares and send assets to destination chain
     * @param _params Redeem parameters
     * @param options LayerZero options
     */
    function redeem(
        RedeemParams calldata _params,
        bytes calldata options
    ) external payable nonReentrant {
        if (_params.shares == 0) revert ZeroAmount();
        if (trustedRemotes[_params.dstEid] == bytes32(0)) revert InvalidRemote();
        
        // Generate operation ID
        bytes32 operationId = keccak256(
            abi.encodePacked(msg.sender, _params.shares, _params.dstEid, block.timestamp)
        );
        
        if (processedOperations[operationId]) revert OperationAlreadyProcessed();
        processedOperations[operationId] = true;
        
        // Transfer share OFT tokens from user
        if (!shareOFT.transferFrom(msg.sender, address(this), _params.shares)) {
            revert TransferFailed();
        }
        
        // Unlock shares from share OFT adapter
        // This will burn the OFT tokens and unlock the underlying shares
        // Shares were locked by this contract during deposit, so we can unlock them
        shareOFT.unlockSharesFor(address(this), _params.shares);
        
        // Redeem from vault
        uint256 assets = vault.redeem(_params.shares, address(this), address(this));
        
        // Build payload for cross-chain transfer
        bytes memory payload = abi.encode(
            Action.REDEEM,
            operationId,
            _params.receiver,
            assets
        );
        
        // Send assets to destination chain
        ILayerZeroEndpoint.MessagingParams memory lzParams = ILayerZeroEndpoint.MessagingParams({
            dstEid: _params.dstEid,
            receiver: trustedRemotes[_params.dstEid],
            message: payload,
            options: options,
            payInLzToken: false
        });
        
        lzEndpoint.send{value: msg.value}(lzParams, msg.sender);
        
        emit RedeemInitiated(operationId, msg.sender, _params.shares, _params.dstEid, _params.receiver);
        emit RedeemCompleted(operationId, msg.sender, assets);
    }
    
    /**
     * @notice Receive cross-chain message
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
        (Action action, bytes32 operationId, bytes32 receiver, uint256 amount) = 
            abi.decode(payload, (Action, bytes32, bytes32, uint256));
        
        if (processedOperations[operationId]) revert OperationAlreadyProcessed();
        processedOperations[operationId] = true;
        
        if (action == Action.DEPOSIT) {
            // Mint share OFT tokens on destination chain
            // Note: This should be handled by the share OFT contract on destination chain
            // For now, we emit an event - actual minting happens via share OFT's lzReceive
        } else if (action == Action.REDEEM) {
            // Transfer assets to receiver on destination chain
            address receiverAddr = address(uint160(uint256(receiver)));
            if (!assetOFT.transfer(receiverAddr, amount)) {
                revert TransferFailed();
            }
        }
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
     * @notice Get share OFT address
     */
    function getShareOFT() external view returns (address) {
        return address(shareOFT);
    }
    
    /**
     * @notice Get asset OFT address
     */
    function getAssetOFT() external view returns (address) {
        return address(assetOFT);
    }
}
