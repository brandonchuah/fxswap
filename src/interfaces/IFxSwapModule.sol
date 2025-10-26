// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IFxSwapModule {
    /**
     * @dev The parameters for a broker
     * @param broker The address of the broker
     * @param amount The amount of the source token to swap
     * @param fxRate The fx rate for the swap
     * @param deadline The deadline for the swap
     * @param signature The signature of the broker
     */
    struct BrokerParam {
        address broker;
        uint256 amount;
        uint256 fxRate;
        uint256 deadline;
        bytes signature;
    }

    error BrokerReleaseFailed();
    error InvalidDeadline();

    function swap(address fromToken, address toToken, address receiver, BrokerParam[] calldata brokerParams) external;
}
