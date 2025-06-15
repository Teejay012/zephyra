// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { ZephyraStableCoin } from "src/ZephyraStableCoin.sol";
import { ZephyraNFT } from "src/ZephyraNFT.sol";
import { DeployZephyraNFT } from "script/NFT/DeployZphyraNFT.s.sol";
import { HelperConfig } from "script/NFT/NftHelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {CodeConstants} from "script/NFT/NftHelperConfig.s.sol";

contract ZephyNFTTest is Test, CodeConstants {

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RandomClick(address indexed user, bool success, uint256 timestamp);
    event NftMinted(address indexed to, uint256 tokenIdCounter);
    event RaffleEntered(address player);
    event RaffleRequestWinner(uint256 requestId);
    event RaffleWinner(address indexed winner);



    DeployZephyraNFT private deployer;
    HelperConfig private helperConfig;
    ZephyraNFT private zephy;
    ZephyraStableCoin private zusd;


    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;
    LinkToken link;


    address PLAYER = makeAddr("player");
    address PLAYER2 = makeAddr("player2");
    address PLAYER3 = makeAddr("player3");
    address zusdOwner;

    uint256 private constant MINT_AMOUNT = 100 * 10 ** 18;
    uint256 private constant RAFFLE_ENTRANCE_FEE = 0.01 ether;
    uint256 private constant STARTING_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;
    
    function setUp() public {
        deployer = new DeployZephyraNFT();
        (zephy, helperConfig, zusd) = deployer.run();
        address zephyOwner = zephy.owner();

        vm.deal(zephyOwner, STARTING_BALANCE);
        vm.deal(PLAYER, STARTING_BALANCE);
        vm.deal(PLAYER2, STARTING_BALANCE);
        vm.deal(PLAYER3, STARTING_BALANCE);

        zusdOwner = zusd.owner();
        vm.startPrank(zusdOwner);
        zusd.mint(zephyOwner, MINT_AMOUNT);
        zusd.mint(PLAYER, MINT_AMOUNT);
        zusd.mint(PLAYER2, MINT_AMOUNT);
        zusd.mint(PLAYER3, MINT_AMOUNT);
        vm.stopPrank();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        automationUpdateInterval = config.automationUpdateInterval;
        raffleEntranceFee = config.raffleEntranceFee;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        link = LinkToken(config.link);


        vm.startPrank(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
        // Add consumer (this is the critical missing part)
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).addConsumer(subscriptionId, address(zephy));
        vm.stopPrank();

        vm.startPrank(zephyOwner);

        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(zephyOwner, LINK_BALANCE);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subscriptionId, LINK_BALANCE);
        }
        link.approve(vrfCoordinatorV2_5, LINK_BALANCE);
        vm.stopPrank();
    }

    function testOwnerCanMintNFT() public {
        address actualOwner = zephy.owner();
        vm.prank(actualOwner);    
        zephy.safeMint(PLAYER);
        assertEq(zephy.balanceOf(PLAYER), 1, "Player should own one NFT after minting");    
    }


    function testInitialState() public view {
        assertEq(zephy.name(), "ZephyraNFT");
        assertEq(zephy.symbol(), "ZEPHY");
    }

    function testSafeMint() public {
        address actualOwner = zephy.owner();
        vm.prank(actualOwner);    
        zephy.safeMint(PLAYER);
        assertEq(zephy.ownerOf(0), PLAYER);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function testRaffleRevertsWHenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert

        vm.warp(block.timestamp + 1 days); // Move time forward to allow raffle to be open
        vm.expectRevert(ZephyraNFT.ZephyraNFT__NotEnoughEntryFee.selector);
        zephy.tryLuck();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.warp(block.timestamp + 1 days);
        zephy.tryLuck{value: raffleEntranceFee}();
        // Assert
        address playerRecorded = zephy.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testDontAllowPlayersToEnterWhileRaffleIsClosed() public {
        // Arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + 1 days);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        zephy.performUpkeep("");

        // Act / Assert
        vm.expectRevert(ZephyraNFT.ZephyraNFT__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        zephy.tryLuck{value: raffleEntranceFee}();
    }

    

    /*//////////////////////////////////////////////////////////////
                              CHECKUPKEEP
    //////////////////////////////////////////////////////////////*/
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = zephy.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + 1 days);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        zephy.performUpkeep("");
        ZephyraNFT.RaffleState raffleState = zephy.getRaffleState();
        // Act
        (bool upkeepNeeded,) = zephy.checkUpkeep("");
        // Assert
        assert(raffleState == ZephyraNFT.RaffleState.CLOSED);
        assert(upkeepNeeded == false);
    }


    /*//////////////////////////////////////////////////////////////
                             PERFORMUPKEEP
    //////////////////////////////////////////////////////////////*/
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + 1 days);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        // It doesnt revert
        zephy.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        // Arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + 1 days);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        vm.recordLogs();
        zephy.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Parse logs to find RaffleRequestWinner event
        bytes32 raffleRequestWinnerSig = keccak256("RaffleRequestWinner(uint256)");
        bytes32 requestId;
        bool found;

        for (uint i = 0; i < entries.length; i++) {
            Vm.Log memory log = entries[i];
            if (log.topics[0] == raffleRequestWinnerSig) {
                requestId = bytes32(log.data); // assuming requestId is first and only field
                found = true;
                break;
            }
        }

        // Assert
        assertTrue(found, "RaffleRequestWinner event not found");
        assertGt(uint256(requestId), 0, "requestId should be greater than 0");

        ZephyraNFT.RaffleState raffleState = zephy.getRaffleState();
        assertEq(uint256(raffleState), 1); // 1 = calculating
    }


    /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/
    modifier raffleEntered() {
        vm.startPrank(PLAYER);
        vm.warp(block.timestamp + 1 days);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        vm.stopPrank();
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public raffleEntered skipFork {
        // Arrange
        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // vm.mockCall could be used here...
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(0, address(zephy));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(1, address(zephy));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsNFT() public skipFork {

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(PLAYER);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.stopPrank();

        vm.startPrank(PLAYER2);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.stopPrank();

        vm.startPrank(PLAYER3);
        zephy.tryLuck{value: raffleEntranceFee}();
        vm.stopPrank();

        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        uint256 startingTimeStamp = zephy.getLastTimeStamp();

        // Act
        vm.recordLogs();
        zephy.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Parse logs to find RaffleRequestWinner event
        bytes32 raffleRequestWinnerSig = keccak256("RaffleRequestWinner(uint256)");
        bytes32 requestId;
        bool found;

        for (uint i = 0; i < entries.length; i++) {
            Vm.Log memory log = entries[i];
            if (log.topics[0] == raffleRequestWinnerSig) {
                requestId = bytes32(log.data); // assuming requestId is first and only field
                found = true;
                break;
            }
        }

        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(uint256(requestId), address(zephy));

        // Assert
        address recentWinner = zephy.getRecentWinner();
        ZephyraNFT.RaffleState raffleState = zephy.getRaffleState();
        uint256 winnerBalance = zephy.balanceOf(recentWinner);
        uint256 endingTimeStamp = zephy.getLastTimeStamp();

        console.log("The winner: ", recentWinner);
        assertEq(uint256(raffleState), 0);
        assertEq(winnerBalance, 1, "Winner should have 1 NFT");
        assertGt(endingTimeStamp, startingTimeStamp);
    }

}