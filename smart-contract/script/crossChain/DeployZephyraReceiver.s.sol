// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { ZephyraReceiver } from "src/ZephyraReceiver.sol";
import { HelperConfig } from "script/crossChain/CCHelperConfig.s.sol";

contract DeployReceiver is Script {
    function run() external returns (ZephyraReceiver) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // Replace with the CCIP Router for the destination chain
        address CCIP_ROUTER = config.routerAddress;

        // Start broadcasting a transaction from the deployer
        vm.startBroadcast();

        ZephyraReceiver receiver = new ZephyraReceiver(CCIP_ROUTER);

        vm.stopBroadcast();

        return receiver;

        console.log("ZephyraReceiver deployed at:", address(receiver));
    }
}
