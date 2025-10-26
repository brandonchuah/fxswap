// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "safe-contracts/contracts/libraries/Enum.sol";
import "safe-contracts/contracts/Safe.sol";
import "solady/utils/EIP712.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFxSwapModule.sol";

// This contract is a Safe module that allows brokers to turn their Safes into FX swap brokers
contract FxSwapModule is IFxSwapModule, EIP712 {
    uint256 public constant RATE_SCALE = 1e18;

    bytes32 public constant SWAP_TYPE_HASH = keccak256(
        "swap(address fromToken,address toToken,address receiver,uint256 amount,uint256 fxRate,uint256 deadline)"
    );

    /**
     * @dev Swaps tokens between two tokens using the brokers
     * @param fromToken The address of the token to swap from
     * @param toToken The address of the token to swap to
     * @param receiver The address to receive the swapped tokens
     * @param brokerParams The array of broker parameters, containing conversion details and signatures
     */
    function swap(address fromToken, address toToken, address receiver, BrokerParam[] calldata brokerParams) external {
        uint256 length = brokerParams.length;

        uint256 totalAmount;
        for (uint256 i = 0; i < length; i++) {
            totalAmount += brokerParams[i].amount;
        }

        IERC20(fromToken).transferFrom(msg.sender, address(this), totalAmount);

        for (uint256 i = 0; i < length; i++) {
            if (block.timestamp > brokerParams[i].deadline) {
                revert InvalidDeadline();
            }

            {
                bytes32 swapDataHash = _swapDataHash(
                    fromToken,
                    toToken,
                    receiver,
                    brokerParams[i].amount,
                    brokerParams[i].fxRate,
                    brokerParams[i].deadline
                );

                _verifyBrokerSignature(brokerParams[i].broker, swapDataHash, brokerParams[i].signature);
            }

            IERC20(fromToken).transfer(brokerParams[i].broker, brokerParams[i].amount);

            uint256 releaseAmount = (brokerParams[i].amount * brokerParams[i].fxRate) / RATE_SCALE;

            _releaseFromBroker(brokerParams[i].broker, receiver, toToken, releaseAmount);
        }

        // TODO: Use PYTH to get rate make to sure there is no huge diviation
    }

    function _verifyBrokerSignature(address broker, bytes32 structHash, bytes calldata signature) internal view {
        bytes32 hash = _hashTypedData(structHash);

        // Reverts if signature is not valid
        Safe(payable(broker)).checkSignatures(hash, abi.encodePacked(structHash), signature);
    }

    function _releaseFromBroker(address broker, address receiver, address toToken, uint256 toAmount) internal {
        bytes memory transferData = abi.encodeWithSelector(IERC20.transfer.selector, receiver, toAmount);

        bool success = Safe(payable(broker)).execTransactionFromModule(toToken, 0, transferData, Enum.Operation.Call);

        if (!success) {
            revert BrokerReleaseFailed();
        }
    }

    function _swapDataHash(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        uint256 fxRate,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_TYPE_HASH, fromToken, toToken, receiver, amount, fxRate, deadline));
    }

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "FxSwapModule";
        version = "1.0.0";
    }
}
