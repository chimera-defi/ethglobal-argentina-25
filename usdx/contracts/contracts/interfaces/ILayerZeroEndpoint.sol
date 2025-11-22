// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title ILayerZeroEndpoint
 * @notice Interface for LayerZero Endpoint
 * @dev This interface matches LayerZero v2 endpoint
 */
interface ILayerZeroEndpoint {
    struct MessagingParams {
        uint32 dstEid;
        bytes32 receiver;
        bytes message;
        bytes options;
        bool payInLzToken;
    }

    struct MessagingReceipt {
        bytes32 guid;
        uint64 nonce;
        MessagingFee fee;
    }

    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    }

    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory receipt);

    function quote(
        MessagingParams calldata _params,
        address _sender
    ) external view returns (MessagingFee memory fee);

    function lzReceive(
        uint32 _srcEid,
        bytes32 _sender,
        bytes calldata _payload,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}
