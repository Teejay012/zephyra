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
import {LinkToken} from "test/mocks/LinkToken.sol";
import {console} from "forge-std/console.sol";

contract CrossChainTokenTransferTest is Test {
    DeployCrossChainTransfer public deployer;
    DeployReceiver public deployReceiver;
    HelperConfig public helperConfig;
    ZephyraCrossChainTransfer public zephyraCrossChainTx;
    ZephyraReceiver public zephyraReceiver;
    ZephyraStableCoin public zusd;
    LinkToken public link;
    MockCCIPRouter public router;

    address user = makeAddr("user");
    address receiver = makeAddr("receiver");
    uint64 constant DESTINATION_CHAIN = 11155111; // example
    uint256 constant FEE = 0.01 ether; // example fee

    function setUp() public {
        deployer = new DeployCrossChainTransfer();
        deployReceiver = new DeployReceiver();

        (zephyraCrossChainTx, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        zephyraReceiver = deployReceiver.run();

        // Initializing the mock tokens and router
        zusd = ZephyraStableCoin(config.zusdAddress);
        link = LinkToken(config.linkTokenAddress);
        router = MockCCIPRouter(config.routerAddress);

        router.setFee(FEE); // mock fee for the router

        // Setup: minting tokens for the user
        address zusdOwner = zusd.owner();
        vm.startPrank(zusdOwner);
        zusd.mint(user, 1000 ether);
        vm.stopPrank();
        link.mint(user, 100 ether);

        console.log("User LINK Balance:", link.balanceOf(user));
        console.log("User ZUSD Balance:", zusd.balanceOf(user));

        // Allowlist destination chain
        address zephyraCrossChainTxOwner = zephyraCrossChainTx.owner();
        vm.startPrank(zephyraCrossChainTxOwner);
        zephyraCrossChainTx.allowlistDestinationChain(DESTINATION_CHAIN, true);
        vm.stopPrank();
    }


    function testTransferWithLINK() public {
        vm.startPrank(user);

        // Approve the protocol to spend ZUSD and LINK
        zusd.approve(address(zephyraCrossChainTx), 500 ether);
        link.approve(address(zephyraCrossChainTx), 1 ether);

        // Performing the transfer
        bytes32 messageId = zephyraCrossChainTx.transferTokensPayLINK(
            DESTINATION_CHAIN,
            address(zephyraReceiver),
            receiver,
            500 ether
        );

        // Assert that a valid message ID is returned
        assertTrue(messageId != bytes32(0));

        vm.stopPrank();
    }

    
    function testTransferWithNative() public {
        vm.startPrank(user);

        // Approve the protocol to spend ZUSD
        zusd.approve(address(zephyraCrossChainTx), 400 ether);
        vm.deal(user, FEE); // Sending some native token to the user for the fee

        // Performing the transfer with native token payment
        bytes32 messageId = zephyraCrossChainTx.transferTokensPayNative{value: FEE}(
            DESTINATION_CHAIN,
            address(zephyraReceiver),
            receiver,
            400 ether
        );

        // Assert that a valid message ID is returned
        assertTrue(messageId != bytes32(0));

        vm.stopPrank();
    }

    function testRevertIfNotAllowlisted() public {
        vm.startPrank(user);
        uint64 blockedChain = 9999999; // A chain that is not allowlisted
        zusd.approve(address(zephyraCrossChainTx), 200 ether);
        link.approve(address(zephyraCrossChainTx), 1 ether);

        vm.expectRevert(abi.encodeWithSelector(ZephyraCrossChainTransfer.ZephyraCrossChainTransfer__DestinationChainNotAllowlisted.selector, blockedChain));
        zephyraCrossChainTx.transferTokensPayLINK(blockedChain, address(zephyraReceiver), receiver, 200 ether);
        vm.stopPrank();
    }


    function testRevertIfNotEnoughLINK() public {
        vm.startPrank(user);
        zusd.approve(address(zephyraCrossChainTx), 300 ether);
        link.approve(address(zephyraCrossChainTx), 0.00001 ether); // too little

        vm.expectRevert(ZephyraCrossChainTransfer.ZephyraCrossChainTransfer__InsufficientLINKBalance.selector);
        zephyraCrossChainTx.transferTokensPayLINK(DESTINATION_CHAIN, address(zephyraReceiver), receiver, 300 ether);
        vm.stopPrank();
    }


    function testRevertIfNotEnoughZUSD() public {
        vm.startPrank(user);
        zusd.approve(address(zephyraCrossChainTx), 0.00001 ether); // too little
        link.approve(address(zephyraCrossChainTx), 1 ether);

        vm.expectRevert();
        zephyraCrossChainTx.transferTokensPayLINK(DESTINATION_CHAIN, address(zephyraReceiver), receiver, 500 ether);
        vm.stopPrank();
    }




    function test_getEstimatedFee() public {
        vm.startPrank(user);
        
        // Approve the protocol to spend ZUSD
        zusd.approve(address(zephyraCrossChainTx), 500 ether);
        link.approve(address(zephyraCrossChainTx), FEE); // Approve LINK for fee

        // Get estimated fee for the transfer
        uint256 estimatedFee = zephyraCrossChainTx.getEstimatedFee(DESTINATION_CHAIN, address(zephyraReceiver), receiver, 500 ether, true);

        // Assert that the estimated fee is greater than zero
        assertTrue(estimatedFee > 0, "Estimated fee should be greater than zero");

        vm.stopPrank();
    }
}
