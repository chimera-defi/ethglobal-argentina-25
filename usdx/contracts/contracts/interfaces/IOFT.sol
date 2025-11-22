// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title IOFT
 * @notice Interface for Omnichain Fungible Token (OFT)
 * @dev Standard LayerZero OFT interface
 */
interface IOFT {
    function send(
        uint32 _dstEid,
        bytes32 _to,
        uint256 _amountLD,
        address _refundAddress,
        bytes calldata _composeMsg,
        bytes calldata _options
    ) external payable;

    function quoteSend(
        uint32 _dstEid,
        bytes32 _to,
        uint256 _amountLD,
        bool _payInLzToken,
        bytes calldata _options
    ) external view returns (uint256 nativeFee, uint256 lzTokenFee);
}
