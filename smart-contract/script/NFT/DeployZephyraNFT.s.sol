// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./NftHelperConfig.s.sol";
import {ZephyraNFT} from "src/ZephyraNFT.sol";
// import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
// import {ZephyraStableCoin} from "src/ZephyraStableCoin.sol";
import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployZephyraNFT is Script {

    uint256 private constant ZEPHY_MIN_REQUIRED_BALANCE = 10 * 10**18; // 10 ZUSD

    function run() external returns (ZephyraNFT, HelperConfig, IZephyraStableCoin) {
        HelperConfig helperConfig = new HelperConfig(); 
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("ZephyraStableCoin", block.chainid);
        address zusdContractAddress = 0x792c6B6Cd8CdC39cA45D19438E8b53674CdB73E5;
        
        vm.startBroadcast(config.account);

        // To be removed
        // ZephyraStableCoin zusd = new ZephyraStableCoin(1000 * 10**18); // Mint 1000 ZUSD for testing

        IZephyraStableCoin zusd = IZephyraStableCoin(zusdContractAddress);


        ZephyraNFT zephy = new ZephyraNFT(
            address(zusd),
            ZEPHY_MIN_REQUIRED_BALANCE,
            config.raffleEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (zephy, helperConfig, zusd);
        console.log("Zephyra Stable Coin deployed at:", address(zusd));
        console.log("Zephyra Zephy NFT deployed at:", address(zephy));
    }
}