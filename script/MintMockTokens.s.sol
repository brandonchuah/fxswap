// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {MockERC20} from "../src/mocks/MockERC20.sol";

contract MintMockTokens is Script {
    function run() external {
        if (block.chainId != 11155111) {
            revert("Only on Sepolia");
        }

        uint256 pk = vm.envUint("PRIVATE_KEY");
        address to = vm.envAddress("TO");
        address token = 0x8A0c939571ef36363a5B4526A28aC59f623ebf97;
        uint256 amount = 100 ether;

        vm.startBroadcast(pk);
        MockERC20(token).mint(to, amount);
        vm.stopBroadcast();

        console.log("Minted", amount, "token", token, "to", to);
    }
}
