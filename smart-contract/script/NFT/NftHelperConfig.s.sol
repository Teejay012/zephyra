// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {LinkToken} from "test/mocks/LinkToken.sol";
import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;

    address public constant FOUNDRY_DEFAULT_SENDER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant AVALANCHE_FUJI_CHAIN_ID = 43113;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 gasLane;
        uint256 automationUpdateInterval;
        uint256 raffleEntranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2_5;
        address link;
        address account;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Local network state variables
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[AVALANCHE_FUJI_CHAIN_ID] = getAvalancheFujiConfig();
        networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getAvalancheFujiConfig()
        public
        pure
        returns (NetworkConfig memory fujiNetworkConfig)
    {
        fujiNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            gasLane: 0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887,
            automationUpdateInterval: 86400, // 24 hours
            raffleEntranceFee: 0.0005 ether,
            callbackGasLimit: 300000, // 300,000 gas
            vrfCoordinatorV2_5: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            account: 0x186159375129Bc6ae88dA802977FdA3D2A6f80d3
        });
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: 68266343087651619486944885948844956548801694477259066491391364738733153852762,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            automationUpdateInterval: 86400, // 24 hours
            raffleEntranceFee: 0.0005 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x186159375129Bc6ae88dA802977FdA3D2A6f80d3
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        
        if (localNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ You have deployed a mock conract!");
        console2.log("Make sure this was intentional");
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE,
                MOCK_GAS_PRICE_LINK,
                MOCK_WEI_PER_UINT_LINK
            );
        LinkToken link = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            automationUpdateInterval: 86400, // 24 hours
            raffleEntranceFee: 0.0005 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            link: address(link),
            account: FOUNDRY_DEFAULT_SENDER
        });
        vm.deal(localNetworkConfig.account, 100 ether);
        return localNetworkConfig;
    }
}