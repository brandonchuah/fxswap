// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {MockERC20} from "../src/mocks/MockERC20.sol";

contract DeployMocks is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        MockERC20 xsgd = new MockERC20("MockXSGD", "MockXSGD");

        vm.stopBroadcast();

        console.log("MockXSGD:", address(xsgd));
    }
}
