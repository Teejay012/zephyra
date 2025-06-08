// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import { ZephyraStableCoin } from "src/ZephyraStableCoin.sol";

contract zusdTest is Test {
    ZephyraStableCoin zusd;

    address public USER = makeAddr("user");
    address public owner;

    uint256 private constant MINT_AMOUNT = 100e18;

    function setUp() public {
        zusd = new ZephyraStableCoin(MINT_AMOUNT);

        owner = address(zusd.owner());
    }

    function testMint() public {
        vm.startPrank(owner);
        zusd.mint(USER, MINT_AMOUNT);
        assertEq(zusd.balanceOf(USER), MINT_AMOUNT); 
        vm.stopPrank();
    }

    function testMintFailsIfAmountIsLessThanZero() public {
        vm.startPrank(owner);
        vm.expectRevert(ZephyraStableCoin.ZephyraStableCoin__AmountShouldBeGreaterThanZero.selector);
        zusd.mint(USER, 0);
        vm.stopPrank();
    }

    function testMintFailsIfAddressIsInvalid() public {
        vm.startPrank(owner);
        vm.expectRevert(ZephyraStableCoin.ZephyraStableCoin__AddressNotValid.selector);
        zusd.mint(address(0x0), 0);
        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(owner);
        zusd.mint(USER, MINT_AMOUNT);
        vm.stopPrank();
        vm.startPrank(USER);
        zusd.burn(MINT_AMOUNT);
        assertEq(zusd.balanceOf(USER), 0); 
        vm.stopPrank();
    }

    function testBurnFafilsIfAmountIsLessThanZero() public {
        vm.startPrank(USER);
        vm.expectRevert(ZephyraStableCoin.ZephyraStableCoin__AmountShouldBeGreaterThanZero.selector);
        zusd.burn(0);
        vm.stopPrank();
    }

    function testBurnFafilsIfBalanceIsLessThanAmount() public {
        vm.startPrank(USER);
        vm.expectRevert(ZephyraStableCoin.ZephyraStableCoin__InsufficientBalance.selector);
        zusd.burn(MINT_AMOUNT);
        vm.stopPrank();
    }
}