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
        uint256 deployerKey;
        // address owner;
    }

    NetworkConfig public activeNetworkConfig;

    uint8 private constant DECIMAlS = 8;
    int256 private constant WETH_USD_PRICE = 2000e8;
    int256 private constant WBTC_USD_PRICE = 1000e8;
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 private constant AVALANCHE_FUJI_TESTNET = 43113;

    uint256 public DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaConfig();
        }else if (block.chainid == AVALANCHE_FUJI_TESTNET) {
            activeNetworkConfig = getFujiConfig();
        }else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
            // owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });
    }

    function getFujiConfig() public view returns (NetworkConfig memory fujiNetworkConfig) {
        fujiNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x86d67c3D38D2bCeE722E601025C25a575021c6EA,
            wbtcUsdPriceFeed: 0x31CF013A08c6Ac228C94551d535d5BAfE19c602a,
            weth: 0x9668f5f55f2712Dd2dfa316256609b516292D554,
            wbtc: 0x3a1efc8620D9d2B486E53B573A175ae633B172Be,
            deployerKey: vm.envUint("PRIVATE_KEY")
            // owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
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
            wbtc: address(wbtcMock),
            deployerKey: DEFAULT_ANVIL_KEY
            // owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });
    }
}