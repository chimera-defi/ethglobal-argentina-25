// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../USDXToken.sol";

/**
 * @title CrossChainBridge
 * @notice Simplified cross-chain bridge for USDX transfers
 * @dev For MVP: Uses a trusted relayer instead of LayerZero/Hyperlane
 */
contract CrossChainBridge is AccessControl, ReentrancyGuard {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    USDXToken public immutable usdxToken;
    uint256 public immutable chainId;

    struct PendingTransfer {
        address user;
        uint256 amount;
        uint256 destinationChainId;
        address destinationAddress;
        uint256 timestamp;
        bool completed;
    }

    mapping(bytes32 => bool) public processedTransfers;
    mapping(bytes32 => PendingTransfer) public pendingTransfers;
    mapping(uint256 => bool) public supportedChains; // destination chainId => supported

    uint256 public transferNonce;

    event TransferInitiated(
        bytes32 indexed transferId,
        address indexed user,
        uint256 amount,
        uint256 sourceChainId,
        uint256 destinationChainId,
        address destinationAddress
    );

    event TransferCompleted(
        bytes32 indexed transferId,
        address indexed user,
        uint256 amount,
        uint256 sourceChainId,
        uint256 destinationChainId
    );

    constructor(address _usdxToken, uint256 _chainId) {
        usdxToken = USDXToken(_usdxToken);
        chainId = _chainId;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setSupportedChain(uint256 destinationChainId, bool supported) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supportedChains[destinationChainId] = supported;
    }

    /**
     * @notice Initiate cross-chain transfer by burning USDX
     */
    function transferCrossChain(
        uint256 amount,
        uint256 destinationChainId,
        address destinationAddress
    ) external nonReentrant returns (bytes32 transferId) {
        require(amount > 0, "CrossChainBridge: amount must be greater than 0");
        require(supportedChains[destinationChainId], "CrossChainBridge: unsupported destination chain");
        require(destinationAddress != address(0), "CrossChainBridge: invalid destination address");
        
        // Burn USDX on source chain using burnForCrossChain
        usdxToken.burnForCrossChain(amount, destinationChainId, destinationAddress);
        
        // Create transfer record
        transferId = keccak256(abi.encodePacked(
            chainId,
            destinationChainId,
            msg.sender,
            destinationAddress,
            amount,
            transferNonce++,
            block.timestamp
        ));
        
        pendingTransfers[transferId] = PendingTransfer({
            user: msg.sender,
            amount: amount,
            destinationChainId: destinationChainId,
            destinationAddress: destinationAddress,
            timestamp: block.timestamp,
            completed: false
        });
        
        emit TransferInitiated(
            transferId,
            msg.sender,
            amount,
            chainId,
            destinationChainId,
            destinationAddress
        );
        
        return transferId;
    }

    /**
     * @notice Complete cross-chain transfer by minting USDX (called by relayer)
     */
    function completeTransfer(
        bytes32 transferId,
        uint256 sourceChainId,
        address sourceUser,
        uint256 amount,
        address destinationAddress
    ) external onlyRole(RELAYER_ROLE) nonReentrant {
        require(!processedTransfers[transferId], "CrossChainBridge: transfer already processed");
        require(supportedChains[sourceChainId], "CrossChainBridge: unsupported source chain");
        require(amount > 0, "CrossChainBridge: amount must be greater than 0");
        
        processedTransfers[transferId] = true;
        
        // Mint USDX on destination chain using mintFromCrossChain
        bytes32 messageHash = keccak256(abi.encodePacked(transferId, sourceChainId, sourceUser, amount));
        usdxToken.mintFromCrossChain(destinationAddress, amount, sourceChainId, messageHash);
        
        emit TransferCompleted(
            transferId,
            sourceUser,
            amount,
            sourceChainId,
            chainId
        );
    }

    function getPendingTransfer(bytes32 transferId) external view returns (PendingTransfer memory) {
        return pendingTransfers[transferId];
    }
}
