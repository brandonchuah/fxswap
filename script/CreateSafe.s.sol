// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {Safe} from "safe-contracts/contracts/Safe.sol";
import {SafeProxyFactory} from "safe-contracts/contracts/proxies/SafeProxyFactory.sol";

contract CreateSafe is Script {
    function run() external {
        if (block.chainid != 11155111) revert("Only on Sepolia");

        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(pk);

        vm.startBroadcast(pk);

        address singletonAddr = 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA; // safe v1.3.0 singleton
        address factoryAddr = 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC; // safe v1.3.0 factory

        address[] memory owners = new address[](1);
        owners[0] = owner;

        bytes memory initData = abi.encodeWithSelector(
            Safe.setup.selector, owners, uint256(1), address(0), bytes(""), address(0), address(0), uint256(0)
        );

        Safe safe =
            Safe(payable(SafeProxyFactory(factoryAddr).createProxyWithNonce(singletonAddr, initData, vm.randomUint())));

        vm.stopBroadcast();

        console.log("Safe:", address(safe));
        console.log("Owner:", owner);
    }
}
