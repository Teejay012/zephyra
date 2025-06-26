// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ZUSDForwardAndWrapForCCIP} from "src/ZUSD_CCIP.sol";

contract ZusdCCIPDeploy is Script {
    address private constant ZUSD = 0x792c6B6Cd8CdC39cA45D19438E8b53674CdB73E5; 
    address private constant WRAPPED_ZUSD = 0x51C751935DeaBd0BB45aAEbaFAaE3179A98427da; 
    address private constant CCIP_TRANSFER = 0x708ccC43D27eFF4F057DE2A19f6bDC3e1Fa39bE5; 
    address private constant TREASURY = 0x186159375129Bc6ae88dA802977FdA3D2A6f80d3; 

    function run() external {
        ZUSDForwardAndWrapForCCIP zusdCCIP;
        vm.startBroadcast();

        zusdCCIP = new ZUSDForwardAndWrapForCCIP(
            ZUSD,
            WRAPPED_ZUSD,
            CCIP_TRANSFER,
            TREASURY
        );

        vm.stopBroadcast();
        console.log("ZUSD Forward and Wrap for CCIP deployed successfully.");
        console.log("ZUSD Address:", ZUSD);
        console.log("Wrapped ZUSD Address:", WRAPPED_ZUSD);
        console.log("CCIP Transfer Address:", CCIP_TRANSFER);
        console.log("Treasury Address:", TREASURY);
        console.log("Contract deployed at:", address(zusdCCIP));
    }
}