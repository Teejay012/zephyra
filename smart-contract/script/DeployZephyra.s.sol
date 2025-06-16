// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";

import {ZephyraStableCoin} from "src/ZephyraStableCoin.sol";
import {ZephyraVault} from "src/ZephyraVault.sol";
import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";

contract DeployZephyra is Script {

    address[] private collateralTokens;
    address[] private collateralTokensPriceFeeds;

    uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // 1 million tokens with 18 decimals

    function run() external returns (ZephyraStableCoin, ZephyraVault, HelperConfig) {
         HelperConfig config = new HelperConfig();
        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc
        ) = config.activeNetworkConfig();

        collateralTokens = [weth, wbtc];
        collateralTokensPriceFeeds = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast();

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
        vm.stopBroadcast();

        return (zusd, vault, config);
        console.log("Zephyra Stable Coin deployed at:", address(zusd));
        console.log("Zephyra Vault deployed at:", address(vault));
    }
}