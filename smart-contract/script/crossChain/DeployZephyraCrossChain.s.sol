// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;
import {Script} from "forge-std/Script.sol";
import { HelperConfig } from "script/crossChain/CCHelperConfig.s.sol";
import {ZephyraCrossChainTransfer} from "src/ZephyraCrossChain.sol";

contract DeployCrossChainTransfer is Script {
    function run() external returns (ZephyraCrossChainTransfer, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();

        ZephyraCrossChainTransfer zephyraCrossChainTx = new ZephyraCrossChainTransfer(
            config.routerAddress,
            config.linkTokenAddress,
            config.zusdAddress
        );

        vm.stopBroadcast();

        return (zephyraCrossChainTx, helperConfig);
    }
}