// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ILayerZeroEndpoint} from "../interfaces/ILayerZeroEndpoint.sol";

/**
 * @title MockLayerZeroEndpoint
 * @notice Mock LayerZero endpoint for testing purposes
 * @dev Simulates LayerZero endpoint behavior for local testing
 */
contract MockLayerZeroEndpoint is ILayerZeroEndpoint {
    uint32 public immutable localEid;
    
    // Track messages sent
    mapping(bytes32 => bool) public messagesSent;
    mapping(uint32 => address) public remoteContracts; // eid => contract address
    
    // Nonce tracking
    uint64 public nonce;
    
    event MessageSent(
        uint32 dstEid,
        bytes32 receiver,
        bytes message,
        address refundAddress
    );
    
    event MessageReceived(
        uint32 srcEid,
        bytes32 sender,
        bytes payload
    );
    
    constructor(uint32 _localEid) {
        localEid = _localEid;
    }
    
    /**
     * @notice Set remote contract address for testing
     */
    function setRemoteContract(uint32 eid, address contractAddr) external {
        remoteContracts[eid] = contractAddr;
    }
    
    /**
     * @notice Send a message (mock implementation)
     */
    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory receipt) {
        // Store message
        bytes32 messageHash = keccak256(abi.encode(_params, nonce));
        messagesSent[messageHash] = true;
        
        // Emit event
        emit MessageSent(_params.dstEid, _params.receiver, _params.message, _refundAddress);
        
        // Simulate delivery to remote contract (async - would happen in real LayerZero)
        // In tests, we'll call lzReceive manually on the destination contract
        address remoteContract = remoteContracts[_params.dstEid];
        // Note: In real LayerZero, this would be handled by the executor network
        // For testing, we manually trigger lzReceive on destination contracts
        
        receipt = MessagingReceipt({
            guid: messageHash,
            nonce: nonce++,
            fee: MessagingFee({
                nativeFee: msg.value,
                lzTokenFee: 0
            })
        });
        
        return receipt;
    }
    
    /**
     * @notice Quote fees (mock implementation)
     */
    function quote(
        MessagingParams calldata _params,
        address _sender
    ) external pure returns (MessagingFee memory fee) {
        // Return minimal fee for testing
        return MessagingFee({
            nativeFee: 0.001 ether,
            lzTokenFee: 0
        });
    }
    
    /**
     * @notice Receive message (called by remote endpoint)
     */
    function lzReceive(
        uint32 _srcEid,
        bytes32 _sender,
        bytes calldata _payload,
        address _executor,
        bytes calldata _extraData
    ) external payable {
        emit MessageReceived(_srcEid, _sender, _payload);
    }
}
