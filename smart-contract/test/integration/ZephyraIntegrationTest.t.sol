
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { DeployZephyra } from "script/DeployZephyra.s.sol";
import { ZephyraStableCoin } from "src/ZephyraStableCoin.sol";
import { ZephyraVault } from "src/ZephyraVault.sol";
import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { MockV3Aggregator } from "test/mocks/MockV3Aggregator.sol";
import { console } from "forge-std/console.sol";

contract ZephyraIntegrationTest is Test {
    DeployZephyra deployer;
    ZephyraStableCoin zusd;
    ZephyraVault vault;
    HelperConfig config;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address USER = makeAddr("user");
    address LIQUIDATOR = makeAddr("liquidator");

    uint256 private constant AMOUNT_COLLATERAL = 10 ether;
    uint256 private constant STARTING_BALANCE = 10 ether;
    uint256 private constant LIQUIDATOR_BALANCE = 1000 ether;
    uint256 private constant MINT_AMOUNT = 5 ether;
    uint256 private constant HEALTH_SCORE = 1e18;
    uint256 private constant ZUSD_MINT = 100e18;


    function setUp() public {
        deployer = new DeployZephyra();
        (zusd, vault, config, ,) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, , ) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_BALANCE);
        ERC20Mock(weth).mint(LIQUIDATOR, LIQUIDATOR_BALANCE);
        
        address actualOwner = zusd.owner(); // Assuming zusd inherits Ownable

        vm.startPrank(actualOwner);
        zusd.mint(LIQUIDATOR, ZUSD_MINT);
        vm.stopPrank();

        console.log("weth address: ", weth);
    }

    

    modifier depositCollateralAndMintZusd() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(vault), AMOUNT_COLLATERAL);
        vault.depositCollateral(weth, AMOUNT_COLLATERAL);
        uint256 zusdAmount = vault.getUsdValue(weth, MINT_AMOUNT);
        vault.mintZusd(zusdAmount);
        vm.stopPrank();
        _;
    }

    function testGetUsdValue() public view {
        uint256 amount = 15e18;
        uint256 expectedValue = 30000e18;
        uint256 actualValue = vault.getUsdValue(weth, amount);
        assertEq(actualValue, expectedValue, "The USD value is not correct");
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 amount = vault.getUsdValue(weth, 0.05 ether);

        uint256 expectedValue = 0.05 ether;
        uint256 actualValue = vault.getTokenAmountFromUsd(weth, amount);
        assertEq(actualValue, expectedValue, "The token amount is not correct");
    }

    function testRevertIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(vault), AMOUNT_COLLATERAL);
        vm.expectRevert(ZephyraVault.ZephyraVault__AmountShouldBeGreaterThanZero.selector);
        vault.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertIfTokenLengthDoesNotMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(ZephyraVault.ZephyraVault__CollateralTokenAndPricefeedMismatch.selector);
        new ZephyraVault(IZephyraStableCoin(address(zusd)), tokenAddresses, priceFeedAddresses);
    }

    function testRevertIfTokenCollateralNotCorrect() public {
        ERC20Mock ranToken = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert();
        vault.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(vault), AMOUNT_COLLATERAL);
        vault.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testDepositCollateralAndGetAccountInformation() public depositCollateral {
        (uint256 collateralValueInUsd, uint256 totalzusdMinted) = vault.getAccountInformation(USER);
        uint256 expectedTotalzusdMinted = 0;

        uint256 expectedCollateralValueInUsd = vault.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(totalzusdMinted, expectedTotalzusdMinted, "The total zusd minted is not correct");
        assertEq(
            collateralValueInUsd,
            expectedCollateralValueInUsd,
            "The collateral value in USD is not correct"
        );
    }

    function testIfDepositeRevertsCollateralIfAmountIsMoreThanZero() public {
        vm.startPrank(USER);

        vm.expectRevert(ZephyraVault.ZephyraVault__AmountShouldBeGreaterThanZero.selector);
        vault.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testDepositRevertsIfTransferFails() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(vault), AMOUNT_COLLATERAL);

        vm.mockCall(
            address(weth),
            abi.encodeWithSelector(IERC20(weth).transferFrom.selector, USER, address(vault), AMOUNT_COLLATERAL),
            abi.encode(false)
        );
        vm.expectRevert(ZephyraVault.ZephyraVault__TransferFailed.selector);
        vault.depositCollateral(weth, AMOUNT_COLLATERAL);
    }

    function testDepositCollateralAndMintZusd() public depositCollateral {
        uint256 zusdAmount = vault.getTokenAmountFromUsd(weth, 1000 ether);
        vm.startPrank(USER);
        vault.mintZusd(zusdAmount);
        vm.stopPrank();

        uint256 expectedBalance = zusd.balanceOf(USER);
        assertEq(expectedBalance, zusdAmount, "The zusd balance is not correct");
    }

    // Mint ==============

    function testMintZusd() public depositCollateral {
        vm.startPrank(USER);
        uint256 zusdAmount = vault.getUsdValue(weth, MINT_AMOUNT);
        vault.mintZusd(zusdAmount);
        vm.stopPrank();
    }

    function testRevertIfMintzusdAmountIsZero() public depositCollateral {
        vm.startPrank(USER);
        vm.expectRevert(ZephyraVault.ZephyraVault__AmountShouldBeGreaterThanZero.selector);
        vault.mintZusd(0);
        vm.stopPrank();
    }

    function testRevertIfMintzusdAmountIsMoreThanCollateral() public depositCollateral {
        vm.startPrank(USER);
        uint256 zusdAmount = vault.getUsdValue(weth, 1000 ether);
        uint256 collateralValue = vault.getCollateralValue(USER);
        uint256 calculateHealthFactor = vault.getCalculatedHealthFactor(collateralValue, zusdAmount);
        vm.expectRevert(abi.encodeWithSelector(ZephyraVault.ZephyraVault__BrokenHealthFactor.selector, calculateHealthFactor));
        vault.mintZusd(zusdAmount);
        vm.stopPrank();
    }

    function testRevertIfMintZusdTransferFails() public depositCollateral {
        vm.startPrank(USER);

        uint256 mintAmout = vault.getUsdValue(weth, MINT_AMOUNT);

        vm.mockCall(
            address(zusd),
            abi.encodeWithSelector(ERC20Mock(address(zusd)).mint.selector, USER, mintAmout),
            abi.encode(false)
        );

        vm.expectRevert(ZephyraVault.ZephyraVault__MintFailed.selector);
        vault.mintZusd(mintAmout);
        vm.stopPrank();
    }


    // Burn ==============

    function testBurnZusdReducesMintedAmount() public depositCollateral {
        vm.startPrank(USER);

        // Mint 100 zusd
        vault.mintZusd(100e18);

        uint256 zusdMintedBefore = vault.getMintedZusd(USER);

        // Approve zusd burn
        zusd.approve(address(vault), 50e18);

        // Burn 50 zusd
        vault.burnZusd(50e18);

        vm.stopPrank();

        // Check that only 50 zusd remains
        uint256 zusdMintedAfter = vault.getMintedZusd(USER);
        assertEq(zusdMintedAfter + 50e18, zusdMintedBefore);

        // Check user balance also reflects this
        // assertEq(zusd.balanceOf(USER), 50e18);
    }

    function testRevertIfBurnZusdAmountIsMoreThanBalance() public depositCollateral {
        uint256 mintAmount = 100e18;
        uint256 burnAmount = 200e18;
        vm.startPrank(USER);
        vault.mintZusd(mintAmount);
        zusd.approve(address(vault), burnAmount);
        vm.expectRevert();
        vault.burnZusd(burnAmount);
        vm.stopPrank();
    }

    function testRevertIfBurnZusdAmountIsZero() public {
        vm.startPrank(USER);
        vm.expectRevert(ZephyraVault.ZephyraVault__AmountShouldBeGreaterThanZero.selector);
        vault.burnZusd(0);
        vm.stopPrank();
    }

    function testRevertIfBurnZusdTransferFails() public depositCollateral {
        uint256 mintAmount = 100e18;
        uint256 burnAmount = 100e18;

        vm.startPrank(USER);

        vault.mintZusd(mintAmount);

        // Must match exact selector + arguments
        vm.mockCall(
            address(zusd),
            abi.encodeWithSelector(IERC20(zusd).transferFrom.selector, USER, address(vault), burnAmount),
            abi.encode(false)
        );

        vm.expectRevert(ZephyraVault.ZephyraVault__TransferFailed.selector);
        vault.burnZusd(burnAmount);

        vm.stopPrank();
    }

    function testUserCollateralBalance() public depositCollateral {
        vm.startPrank(USER);
        uint256 expectedBalance = AMOUNT_COLLATERAL;
        uint256 actualBalance = vault.getUserCollateralBalance(USER, weth);
        assertEq(expectedBalance, actualBalance);
        vm.stopPrank();
    }

    function test_RevertsIfMintedZusdBreaksHealthFactor() public depositCollateral {
        vm.startPrank(USER);
        uint256 zusdAmountToMint = vault.getUsdValue(weth, 6 ether);
        vault.updateUserCollateralPrice(weth, USER, 8 ether);
        vault.updateMintedValue(USER, zusdAmountToMint);
        uint256 calculatedUserHealthFactor = vault.getHealthFactor(USER);

        // if (calculatedUserHealthFactor >= HEALTH_SCORE) {
        //     console.log("Health factor is okay");
        // } else {
            console.log("Health factor is less than 1");
            console.log("calculatedUserHealthFactor: ", calculatedUserHealthFactor);
            vault.updateMintedValue(USER, 0);
            vm.expectRevert(abi.encodeWithSelector(ZephyraVault.ZephyraVault__BrokenHealthFactor.selector, calculatedUserHealthFactor));
            vault.mintZusd(zusdAmountToMint);
            vm.stopPrank();
        // }

    }


    function testLiquidate() public depositCollateralAndMintZusd {

        // Update the user minted zusd balance

        uint256 updatedZusdAmount = vault.getUsdValue(weth, 7 ether);
        vault.updateMintedValue(USER, updatedZusdAmount);

        // Liquidate
        vm.startPrank(LIQUIDATOR);
        uint256 zusdAmount = vault.getMintedZusd(USER);
        ERC20Mock(weth).approve(address(vault), LIQUIDATOR_BALANCE);
        vault.depositCollateral(weth, LIQUIDATOR_BALANCE);
        vault.mintZusd(zusdAmount);
        zusd.approve(address(vault), zusdAmount);
        vault.liquidate(weth, USER, zusdAmount);
        vm.stopPrank();
        uint256 userZusdMintedAfter = vault.getMintedZusd(USER);
        uint256 userCollateralDepositAfter = vault.getUserCollateralBalance(USER, weth);
        console.log("User zusd minted After: ", userZusdMintedAfter);
        console.log("User collateral deposit after: ", userCollateralDepositAfter);
        assertEq(userZusdMintedAfter, 0, "User zusd minted after liquidation should be zero");
        assertEq(userCollateralDepositAfter, 0, "User collateral deposit after liquidation should be zero");
    }



    function testLiquidateRevertsIfHealthFactorIsOkay() public depositCollateralAndMintZusd {
        vm.startPrank(LIQUIDATOR);
        uint256 zusdAmount = vault.getMintedZusd(USER);
        ERC20Mock(weth).approve(address(vault), LIQUIDATOR_BALANCE);
        vault.depositCollateral(weth, LIQUIDATOR_BALANCE);
        vault.mintZusd(zusdAmount);
        uint256 healthFactor = vault.getHealthFactor(USER);
        zusd.approve(address(vault), zusdAmount);
        vm.expectRevert(abi.encodeWithSelector(ZephyraVault.ZephyraVault__HealthFactorOkay.selector, healthFactor));
        vault.liquidate(weth, USER, zusdAmount);
        vm.stopPrank();
    }

    function testLiquidateRevertsIfLiquidatorHealthFactorNotOkay() public depositCollateralAndMintZusd {
        // Update the user minted zusd balance

        uint256 updatedZusdAmount = vault.getUsdValue(weth, 7 ether);
        vault.updateMintedValue(USER, updatedZusdAmount);
        
        vm.startPrank(LIQUIDATOR);
        uint256 zusdAmount = vault.getMintedZusd(USER);
        ERC20Mock(weth).approve(address(vault), LIQUIDATOR_BALANCE);
        vault.depositCollateral(weth, LIQUIDATOR_BALANCE);
        vault.mintZusd(zusdAmount);

        // Update the liquidator's health factor to be not okay
        uint256 updatedLiquidatorZusdAmount = vault.getUsdValue(weth, LIQUIDATOR_BALANCE);
        vault.updateMintedValue(LIQUIDATOR, updatedLiquidatorZusdAmount);

        uint256 healthFactor = vault.getHealthFactor(LIQUIDATOR);
        zusd.approve(address(vault), zusdAmount);
        vm.expectRevert(abi.encodeWithSelector(ZephyraVault.ZephyraVault__LiquidatorHealthFactorNotOkay.selector, healthFactor));
        vault.liquidate(weth, USER, zusdAmount);
        vm.stopPrank();
    }



    function testGetCollateralValue() public depositCollateral {
        vm.startPrank(USER);
        uint256 actualValue = vault.getCollateralValue(USER);
        uint256 expectedValue = vault.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(actualValue, expectedValue, "The collateral value is not correct");
        vm.stopPrank();
    }

    function testCalculateHealthFactor() public depositCollateral {
        vm.startPrank(USER);
        uint256 zusdAmount = vault.getUsdValue(weth, MINT_AMOUNT);
        zusd.approve(address(vault), zusdAmount);
        vault.mintZusd(zusdAmount);
        uint256 minTestValue = vault.getMintedZusd(USER);
        uint256 collateralValueInUsd = vault.getCollateralValue(USER);
        uint256 calculatedHealthFactor = vault.getCalculatedHealthFactor(collateralValueInUsd, minTestValue);
        assertEq(calculatedHealthFactor, HEALTH_SCORE, "The health factor is not correct");
        vm.stopPrank();
    }

    // function testCanBurnZusd() public depositCollateralAndMintZusd {
    //     vm.startPrank(LIQUIDATOR);
    //     uint256 userMintedzusd = vault.getMintedZusd(LIQUIDATOR);
    //     zusd.approve(address(vault), userMintedzusd);
    //     vault.burnZusd(userMintedzusd);
    //     uint256 actualBalance = vault.getMintedZusd(USER);
    //     assertEq(actualBalance, 0, "The minted zusd balance is not correct");
    //     vm.stopPrank();
    // }

    function testRedeemCollateral() public depositCollateral {
        vm.startPrank(USER);
        uint256 initialBalance = ERC20Mock(weth).balanceOf(USER);
        uint256 collateral = vault.getUserCollateralBalance(USER, weth);
        vault.redeemCollateral(weth, collateral);
        uint256 finalBalance = ERC20Mock(weth).balanceOf(USER);
        assertEq(finalBalance, initialBalance + collateral, "The collateral balance is not correct");
        vm.stopPrank();
    }

    function testRevertIfRedeemCollateralAmountIsMoreThanBalance() public depositCollateral {
        vm.startPrank(USER);
        uint256 collateralBalance = vault.getUserCollateralBalance(USER, weth);
        vm.expectRevert(ZephyraVault.ZephyraVault__InsufficientCollateral.selector);
        vault.redeemCollateral(weth, collateralBalance + 1);
        vm.stopPrank();
    }

    function testRevertIfRedeemCollateralAmountIsZero() public depositCollateral {
        vm.startPrank(USER);
        vm.expectRevert(ZephyraVault.ZephyraVault__AmountShouldBeGreaterThanZero.selector);
        vault.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertIfRedeemCollateralTransferFails() public depositCollateral {
        vm.startPrank(USER);
        uint256 collateralBalance = vault.getUserCollateralBalance(USER, weth);
        vm.mockCall(
            address(weth),
            abi.encodeWithSelector(IERC20(weth).transfer.selector, USER, collateralBalance),
            abi.encode(false)
        );
        
        vm.expectRevert(ZephyraVault.ZephyraVault__TransferFailed.selector);
        vault.redeemCollateral(weth, collateralBalance);
        vm.stopPrank();
    }

    function testAnyoneCantMintWithoutCollateral() public {
        vm.prank(USER);
        vm.expectRevert();
        vault.mintZusd(100e18);
    }

}
