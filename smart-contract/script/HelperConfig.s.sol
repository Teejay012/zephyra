// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";
import { MockV3Aggregator } from "test/mocks/MockV3Aggregator.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
    }

    NetworkConfig public activeNetworkConfig;

    uint8 private constant DECIMAlS = 8;
    int256 private constant WETH_USD_PRICE = 2000e8;
    int256 private constant WBTC_USD_PRICE = 1000e8;
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 private constant GOERLI_TESTNET = 43113;


    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaConfig();
        }else if (block.chainid == GOERLI_TESTNET) {
            activeNetworkConfig = getGoerliConfig();
        }else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        });
    }

    function getGoerliConfig() public pure returns (NetworkConfig memory fujiNetworkConfig) {
        fujiNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e,
            wbtcUsdPriceFeed: 0xA39434A63A52E749F02807ae27335515BA4b07F7,
            weth: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            wbtc: address(0)
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        if (activeNetworkConfig.weth != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockWethUsdPriceFeed = new MockV3Aggregator(DECIMAlS, WETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock();
        wethMock.mint(address(this), 1000e8);

        MockV3Aggregator mockWbtcUsdPriceFeed = new MockV3Aggregator(DECIMAlS, WBTC_USD_PRICE);
        ERC20Mock wbtcMock = new ERC20Mock();
        wbtcMock.mint(address(this), 1000e8);
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: address(mockWethUsdPriceFeed),
            wbtcUsdPriceFeed: address(mockWbtcUsdPriceFeed),
            weth: address(wethMock),
            wbtc: address(wbtcMock)
        });
    }
}