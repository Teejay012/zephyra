// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";

import {ZephyraStableCoin} from "src/ZephyraStableCoin.sol";
import {ZephyraVault} from "src/ZephyraVault.sol";
import {ZephyraSender} from "src/learn-crross-chain/ZephyraSender.sol";
import {ZephyraReceiver} from "src/learn-crross-chain/ZephyraReceiver.sol";
import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";


// n instead of deploying all in one contract, i'll split everything
// n and also, i'll replace sender and receiver, I updated the cross-chainn

contract DeployZephyra is Script {

    address[] private collateralTokens;
    address[] private collateralTokensPriceFeeds;

    uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // 1 million tokens with 18 decimals

    address private constant AVALANCHE_FUJI_ROUTER = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address private constant LINK_TOKEN_CONTRACT_ADDRESS = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;

    address private constant SEPOLIA_ROUTER = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;

    function run() external returns (ZephyraStableCoin, ZephyraVault, HelperConfig, ZephyraSender, ZephyraReceiver) {
         HelperConfig config = new HelperConfig();
        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
            // address owner
        ) = config.activeNetworkConfig();

        collateralTokens = [weth, wbtc];
        collateralTokensPriceFeeds = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);

        // Deploying the Zephyra Stable Coin and Vault
        ZephyraStableCoin zusd = new ZephyraStableCoin(INITIAL_SUPPLY);

        // Setting up the Zephyra Vault with the stable coin and collateral tokens
        // and their respective price feeds.
        ZephyraVault vault = new ZephyraVault(
            IZephyraStableCoin(address(zusd)),
            collateralTokens,
            collateralTokensPriceFeeds
        );

        // Transfer ownership of the stable coin to the vault
        // This allows the vault to manage the stable coin, including minting and burning.
        zusd.transferOwnership(address(vault));

        // Deploying the Zephyra Sender and Receiver contracts
        // The sender will be used to send messages across chains using CCIP.
        // The receiver will handle incoming messages on the destination chain.
        ZephyraSender sender = new ZephyraSender(
            AVALANCHE_FUJI_ROUTER,
            LINK_TOKEN_CONTRACT_ADDRESS,
            IZephyraStableCoin(address(zusd))
        );
        ZephyraReceiver receiver = new ZephyraReceiver(
            SEPOLIA_ROUTER
        );
        vm.stopBroadcast();
        return (zusd, vault, config, sender, receiver);
        console.log("Zephyra Stable Coin deployed at:", address(zusd));
        console.log("Zephyra Vault deployed at:", address(vault));
        console.log("Zephyra Sender deployed at:", address(sender));
        console.log("Zephyra Receiver deployed at:", address(receiver));
    }
}