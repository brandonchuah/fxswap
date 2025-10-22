// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IFxSwapModule {
    struct BrokerParam {
        address broker;
        uint256 amount;
        uint256 fxRate;
        uint256 deadline;
        bytes signature;
    }

    error BrokerReleaseFailed();
    error InvalidDeadline();

    function swap(
        address fromToken,
        address toToken,
        address receiver,
        BrokerParam[] calldata brokerParams
    ) external;
}
