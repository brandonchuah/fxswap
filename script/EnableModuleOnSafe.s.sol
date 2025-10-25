// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {Enum} from "safe-contracts/contracts/libraries/Enum.sol";
import {Safe} from "safe-contracts/contracts/Safe.sol";

contract EnableModuleOnSafe is Script {
    function run() external {
        if (block.chainid != 11155111) revert("Only on Sepolia");

        uint256 pk = vm.envUint("PRIVATE_KEY");
        address safeAddr = 0xF16bD86AC718886F0550689A574D4552dEC0253E; // deployed broker's safe address
        address module = 0x091E1C4c0c4e184D90117Cb51436D4d661f138A3; // deployed fx swap module address

        vm.startBroadcast(pk);

        Safe safe = Safe(payable(safeAddr));
        bytes memory data = abi.encodeWithSelector(safe.enableModule.selector, module);

        bytes32 txHash = safe.getTransactionHash({
            to: address(safe),
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            _nonce: safe.nonce()
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, txHash);
        bytes memory signatures = abi.encodePacked(r, s, v);

        bool success = safe.execTransaction({
            to: address(safe),
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: signatures
        });

        vm.stopBroadcast();

        console.log("Safe:", address(safe));
        console.log("Module:", module);
        console.log("Enabled:", success);
    }
}
