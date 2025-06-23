// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";
import {MockCCIPRouter} from "ccip/contracts/src/v0.8/ccip/test/mocks/MockRouter.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {ZephyraStableCoin} from "src/ZephyraStableCoin.sol";


abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant AVALANCHE_FUJI_CHAIN_ID = 43113;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}


contract HelperConfig is Script, CodeConstants {
    struct NetworkConfig {
        address routerAddress;
        address linkTokenAddress;
        address zusdAddress;
    }

    NetworkConfig public localNetworkConfig;

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;



    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
        networkConfigs[AVALANCHE_FUJI_CHAIN_ID] = getAvalancheFujiConfig();
        networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilEthConfig();
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        NetworkConfig memory config = networkConfigs[chainId];
        if (config.routerAddress == address(0)) {
            revert("HelperConfig__InvalidChainId");
        }
        return config;
    }

    function getSepoliaEthConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            linkTokenAddress: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            zusdAddress: 0x792c6B6Cd8CdC39cA45D19438E8b53674CdB73E5
        });
    }

    function getBaseSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            linkTokenAddress: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
            zusdAddress: 0xc350BDbc791BBa066257bfE97e899903B2549B41
        });
    }

    function getAvalancheFujiConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
            linkTokenAddress: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            zusdAddress: 0x792c6B6Cd8CdC39cA45D19438E8b53674CdB73E5
        });
    }

    function getOrCreateAnvilEthConfig() internal returns (NetworkConfig memory) {

        if (localNetworkConfig.routerAddress != address(0)) {
            return localNetworkConfig;
        }
        
        localNetworkConfig = NetworkConfig({
            routerAddress: address(new MockCCIPRouter()), // Mock price feed
            linkTokenAddress: address(new LinkToken()),
            zusdAddress: address(new ZephyraStableCoin(1000 ether))
        });
        
        return localNetworkConfig;
    }
}