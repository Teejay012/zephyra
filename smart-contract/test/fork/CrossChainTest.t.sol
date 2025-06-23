// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockCCIPRouter} from "ccip/contracts/src/v0.8/ccip/test/mocks/MockRouter.sol";
import { DeployCrossChainTransfer } from "script/crossChain/DeployZephyraCrossChain.s.sol";
import { DeployReceiver } from "script/crossChain/DeployZephyraReceiver.s.sol";
import {HelperConfig} from "script/crossChain/CCHelperConfig.s.sol";
import {ZephyraCrossChainTransfer} from "src/ZephyraCrossChain.sol";
import {ZephyraReceiver} from "src/ZephyraReceiver.sol";
import {ZephyraStableCoin} from "src/ZephyraStableCoin.sol";
import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {console} from "forge-std/console.sol";

contract CrossChainTokenTransferTest is Test {
    ZephyraCrossChainTransfer xtx;
    ZephyraReceiver xReceiver;

    address public constant ZUSD_SEPOLIA = 0x9EcD7DC4200F74aBD24850075a00a3fDf6F79B48;
    address public constant ZUSD_ON_BASE = 0xdac3fcaF7b7FED69c9FB320c9008D7f2F704E949;
    address public constant WALLET = 0x186159375129Bc6ae88dA802977FdA3D2A6f80d3;

    uint64 constant DESTINATION_CHAIN = 10344971235874465080;
    uint256 constant TX_AMOUNT = 1e18; // 1 ZUSD

    uint256 sepoliaFork;
    uint256 baseSepoliaFork;

    function setUp() public {
        sepoliaFork = vm.createSelectFork("sepolia");
        baseSepoliaFork = vm.createFork("base-sepolia");

        xtx = new ZephyraCrossChainTransfer(
            0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            0x779877A7B0D9E8603169DdbD7836e478b4624789,
            0x792c6B6Cd8CdC39cA45D19438E8b53674CdB73E5
        );

        address owner = xtx.owner();
        vm.startPrank(owner);
        xtx.allowlistDestinationChain(DESTINATION_CHAIN, true);
        vm.stopPrank();

        vm.selectFork(baseSepoliaFork);
        xReceiver = new ZephyraReceiver(
            0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93
        );
    }

    function testZUSDBalance() public view {
        uint256 bal = IZephyraStableCoin(ZUSD_SEPOLIA).balanceOf(WALLET);
        console.log("ZUSD balance:", bal);
        assertGt(bal, 0);
    }

    function testXChainTx() public {
        vm.selectFork(sepoliaFork);
        vm.startPrank(WALLET);
        uint256 initialBalanceOnSepolia = IZephyraStableCoin(ZUSD_SEPOLIA).balanceOf(WALLET);
        // uint256 initialBalanceOnBase = IZephyraStableCoin(ZUSD_ON_BASE).balanceOf(WALLET);

        bytes32 messageId = xtx.transferTokensPayNative(
            DESTINATION_CHAIN,
            address(xReceiver),
            WALLET,
            TX_AMOUNT
        );

        // Assert that a valid message ID is returned
        assertTrue(messageId != bytes32(0));

        vm.stopPrank();
    }
}