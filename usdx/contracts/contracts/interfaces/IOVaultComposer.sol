// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title IOVaultComposer
 * @notice Interface for OVault Composer
 * @dev Handles cross-chain vault operations
 */
interface IOVaultComposer {
    enum Action {
        DEPOSIT,
        REDEEM
    }

    struct DepositParams {
        uint256 assets;
        uint32 dstEid;
        bytes32 receiver;
    }

    struct RedeemParams {
        uint256 shares;
        uint32 dstEid;
        bytes32 receiver;
    }

    function deposit(
        DepositParams calldata _params,
        bytes calldata _options
    ) external payable;

    function redeem(
        RedeemParams calldata _params,
        bytes calldata _options
    ) external payable;
}
