// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "safe-contracts/contracts/Safe.sol";
import {FxSwapModule} from "../src/FxSwapModule.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {SafeUtils} from "./utils/SafeUtils.t.sol";
import {IFxSwapModule} from "../src/interfaces/IFxSwapModule.sol";
import {console} from "forge-std/console.sol";

contract FxSwapModuleTest is SafeUtils {
    // Contracts
    MockERC20 public PYUSD = new MockERC20("PYUSD", "PYUSD");
    MockERC20 public XSGD = new MockERC20("XSGD", "XSGD");
    FxSwapModule public fxSwapModule = new FxSwapModule();
    Safe public broker;
    Safe public broker2;

    // User details

    uint256 public pkUser = vm.randomUint();
    address public user = payable(vm.addr(pkUser));

    function setUp() public {
        PYUSD.mint(user, 200 ether);

        (, broker) = newSafe();
        (, broker2) = newSafe();

        enableModule(broker, address(fxSwapModule));
        enableModule(broker2, address(fxSwapModule));

        XSGD.mint(address(broker), 200 ether);
        XSGD.mint(address(broker2), 200 ether);
    }

    // Test swapping 100 PYUSD to XSGD at a rate of 1:1.25
    function test_swap() public {
        vm.startPrank(user);

        uint256 amount = 100 ether; // 100 PYUSD
        uint256 fxRate = 125e16; // 1.25
        uint256 deadline = block.timestamp + 1 minutes; // 1 minute ttl

        PYUSD.approve(address(fxSwapModule), amount);

        IFxSwapModule.BrokerParam[]
            memory brokerParams = new IFxSwapModule.BrokerParam[](1);

        brokerParams[0] = IFxSwapModule.BrokerParam(
            address(broker),
            amount,
            fxRate,
            deadline,
            bytes("")
        );

        bytes memory signature = brokerSignFxRate(
            fxSwapModule,
            address(PYUSD),
            address(XSGD),
            user,
            brokerParams[0]
        );

        brokerParams[0].signature = signature;

        fxSwapModule.swap(address(PYUSD), address(XSGD), user, brokerParams);

        vm.stopPrank();

        uint256 expectedUserXSGD = (amount * fxRate) / 1e18;
        uint256 expectedBrokerXSGD = 200 ether - expectedUserXSGD;
        uint256 expectedUserPYUSD = 200 ether - amount;
        uint256 expectedBrokerPYUSD = amount;

        assertEq(XSGD.balanceOf(user), expectedUserXSGD);
        assertEq(PYUSD.balanceOf(user), expectedUserPYUSD);
        assertEq(XSGD.balanceOf(address(broker)), expectedBrokerXSGD);
        assertEq(PYUSD.balanceOf(address(broker)), expectedBrokerPYUSD);
    }

    // Test swapping 200 PYUSD to XSGD at a rate of 1:1.25 & 1:1.27 with 2 brokers
    function test_swap_multi_brokers() public {
        console.log("balance broker PYUSD", PYUSD.balanceOf(address(broker)));
        console.log("balance broker XSGD", XSGD.balanceOf(address(broker)));

        vm.startPrank(user);

        PYUSD.approve(address(fxSwapModule), 200 ether);

        IFxSwapModule.BrokerParam[]
            memory brokerParams = new IFxSwapModule.BrokerParam[](2);

        brokerParams[0] = IFxSwapModule.BrokerParam(
            address(broker),
            100 ether,
            125e16,
            block.timestamp + 1 minutes,
            bytes("")
        );
        brokerParams[1] = IFxSwapModule.BrokerParam(
            address(broker2),
            100 ether,
            127e16,
            block.timestamp + 1 minutes,
            bytes("")
        );

        bytes memory signature = brokerSignFxRate(
            fxSwapModule,
            address(PYUSD),
            address(XSGD),
            user,
            brokerParams[0]
        );
        bytes memory signature2 = brokerSignFxRate(
            fxSwapModule,
            address(PYUSD),
            address(XSGD),
            user,
            brokerParams[1]
        );

        brokerParams[0].signature = signature;
        brokerParams[1].signature = signature2;

        fxSwapModule.swap(address(PYUSD), address(XSGD), user, brokerParams);
    }
}
