// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./NftHelperConfig.s.sol";
import {ZephyraNFT} from "src/ZephyraNFT.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {ZephyraStableCoin} from "src/ZephyraStableCoin.sol";
// import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";


import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployZephyraNFT is Script {

    uint256 private constant ZEPHY_MIN_REQUIRED_BALANCE = 10 * 10**18; // 10 ZUSD

    function run() external returns (ZephyraNFT, HelperConfig, ZephyraStableCoin) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        // AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        string memory zephySvg = vm.readFile("./img/zephy.svg");

        // if (config.subscriptionId == 0) {
        //     CreateSubscription createSubscription = new CreateSubscription();
        //     (config.subscriptionId, config.vrfCoordinatorV2_5) =
        //         createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

        //     FundSubscription fundSubscription = new FundSubscription();
        //     fundSubscription.fundSubscription(
        //         config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
        //     );

        //     helperConfig.setConfig(block.chainid, config);
        // }

        vm.startBroadcast(config.account);
        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("ZephyraStableCoin", block.chainid);

        // To be removed
        ZephyraStableCoin zusd = new ZephyraStableCoin(1000 * 10**18); // Mint 1000 ZUSD for testing

        ZephyraNFT zephy = new ZephyraNFT(
            address(zusd),
            svgToImageURI(zephySvg),
            ZEPHY_MIN_REQUIRED_BALANCE,
            config.raffleEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // We already have a broadcast in here
        // addConsumer.addConsumer(address(zephy), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);
        return (zephy, helperConfig, zusd);
    }




    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURI, svgBase64Encoded));
    }
}