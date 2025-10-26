// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "safe-contracts/contracts/libraries/Enum.sol";
import "safe-contracts/contracts/Safe.sol";
import "safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import {Test} from "forge-std/Test.sol";
import {FxSwapModule} from "../../src/FxSwapModule.sol";
import {IFxSwapModule} from "../../src/interfaces/IFxSwapModule.sol";

// This contract contains utility functions for Safe operations in tests
contract SafeUtils is Test {
    // Safe Contracts
    Safe internal singleton = new Safe();
    SafeProxyFactory internal proxyFactory = new SafeProxyFactory();
    mapping(address => uint256) internal ownerPkOfSafe;

    // Creates a new Safe with a single owner
    function newSafe() internal returns (address, Safe) {
        uint256 ownerPk = vm.randomUint();
        address owner = payable(vm.addr(ownerPk));

        address[] memory owners = new address[](1);
        owners[0] = owner;

        bytes memory initData = abi.encodeWithSelector(
            Safe.setup.selector,
            owners, // owners
            1, // threshold
            address(0), // to
            bytes(""), // data
            address(0), // fallbackHandler
            address(0), // paymentToken
            0 // payment
        );

        Safe safeCreated =
            Safe(payable(proxyFactory.createProxyWithNonce(address(singleton), initData, vm.randomUint())));

        ownerPkOfSafe[address(safeCreated)] = ownerPk;

        return (owner, safeCreated);
    }

    // Enables a module on a Safe
    function enableModule(Safe safe, address module) internal returns (bool) {
        bytes memory enableModuleData = abi.encodeWithSelector(safe.enableModule.selector, module);

        bytes32 safeTxHash;

        safeTxHash = safe.getTransactionHash({
            to: address(safe),
            value: 0,
            data: enableModuleData,
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            _nonce: safe.nonce()
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPkOfSafe[address(safe)], safeTxHash);

        bytes memory signatures = abi.encodePacked(r, s, v);

        bool success = safe.execTransaction({
            to: address(safe),
            value: 0,
            data: enableModuleData,
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: signatures
        });

        return success;
    }

    // Signs the fx rate that the broker will provide for the swap
    function brokerSignFxRate(
        FxSwapModule fxSwapModule,
        address fromToken,
        address toToken,
        address receiver,
        IFxSwapModule.BrokerParam memory brokerParam
    ) internal view returns (bytes memory) {
        bytes32 swapTypeHash = keccak256(
            abi.encode(
                keccak256(
                    "swap(address fromToken,address toToken,address receiver,uint256 amount,uint256 fxRate,uint256 deadline)"
                ),
                fromToken,
                toToken,
                receiver,
                brokerParam.amount,
                brokerParam.fxRate,
                brokerParam.deadline
            )
        );

        (, string memory name, string memory version, uint256 chainId, address verifyingContract,,) =
            fxSwapModule.eip712Domain();

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, swapTypeHash));

        uint256 ownerPk = ownerPkOfSafe[brokerParam.broker];
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }
}
