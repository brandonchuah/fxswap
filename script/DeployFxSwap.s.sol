// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {FxSwapModule} from "../src/FxSwapModule.sol";

contract DeployFxSwap is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        FxSwapModule fxSwapModule = new FxSwapModule();

        vm.stopBroadcast();

        console.log("FxSwapModule:", address(fxSwapModule));
    }
}
