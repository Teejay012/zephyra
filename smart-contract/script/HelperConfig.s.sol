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
    uint256 private constant AVALANCHE_FUJI_TESTNET = 43113;
    uint256 private constant BASE_SEPOLIA_ID = 84532;


    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaConfig();
        }else if (block.chainid == AVALANCHE_FUJI_TESTNET) {
            activeNetworkConfig = getAvalancheFuji();
        }else if (block.chainid == BASE_SEPOLIA_ID) {
            activeNetworkConfig = getBaseSepoliaConfig();
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

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory baseNetworkConfig) {
        baseNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1,
            wbtcUsdPriceFeed: 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298,
            weth: 0x4200000000000000000000000000000000000006,
            wbtc: 0x29f2D40B0605204364af54EC677bD022dA425d03
        });
    }

    function getAvalancheFuji() public pure returns (NetworkConfig memory fujiNetworkConfig) {
        fujiNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD,
            wbtcUsdPriceFeed: 0x31CF013A08c6Ac228C94551d535d5BAfE19c602a,
            weth: address(0),
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