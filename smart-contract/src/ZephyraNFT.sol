// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract ZephyraNFT is ERC721, ERC721Pausable, VRFConsumerBaseV2Plus {


    // ══════════════════════════════════════════
    // ══ ERRORS
    // ══════════════════════════════════════════


    error ZephyraNFT__NotEnoughEntryFee();
    error ZephyraNFT__NotEnoughTokens(uint256 balance, uint256 required);
    error ZephyraNFT__CooldownActive(uint256 lastClickTime, uint256 cooldownTime);
    error ZephyraNFT__NotOwner();
    error ZephyraNFT__RaffleNotOpen();
    error ZephyraNFT__UpkeepNotNeeded(uint256 balance, uint256 playerLegnth, uint256 raffleState);
    error ZephyraNFT__TokenDoesNotExist(uint256 tokenId);
    error ZephyraNFT__PlayerCantEnterMoreThanOnce();


    // ══════════════════════════════════════════
    // ══ EVENTS
    // ══════════════════════════════════════════


    event RandomClick(address indexed user, bool success, uint256 timestamp);
    event NftMinted(address indexed to, uint256 tokenIdCounter);
    event RaffleEntered(address player);
    event RaffleRequestWinner(uint256 requestId);
    event RaffleWinner(address indexed winner);



    // ══════════════════════════════════════════
    // ══ TYPES
    // ══════════════════════════════════════════


    enum RaffleState {
        OPEN,
        CLOSED
    }


    // ══════════════════════════════════════════
    // ══ STATE VARIABLES
    // ══════════════════════════════════════════

    IZephyraStableCoin immutable i_zusd; // Zephyra token contract
    uint256 private immutable i_entryFee;
    uint256 private immutable i_interval;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;

    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    // uint256 private s_tryingInterval;

    uint256 public s_minRequiredBalance;

    uint256 public s_tokenIdCounter;
    mapping(address => bool) public s_hasEntered;
    mapping(address => bool) public s_hasClaimed;


    



    // ══════════════════════════════════════════
    // ══ MODIFIERS
    // ══════════════════════════════════════════

    /**
     * @notice Modifier to check if the user has enough Zephyra tokens.
     * @dev Reverts if the user's balance is less than the required minimum.
     */

    modifier isEligible() {
        if(i_zusd.balanceOf(msg.sender) < s_minRequiredBalance) {
            revert ZephyraNFT__NotEnoughTokens(i_zusd.balanceOf(msg.sender), s_minRequiredBalance);
        }
        _;
    }


    /**
     * @notice Modifier to check if the user is not on cooldown.
     * @dev Reverts if the last click time is within the cooldown period.
     */

    // modifier NotAvailableCurrently() {
    //     if(block.timestamp < s_lastTimeStamp + s_tryingInterval) {
    //         revert ZephyraNFT__CooldownActive(s_lastTimeStamp, s_tryingInterval);
    //     }
    //     _;
    // }

    /**
     * @notice Modifier to check if the user has not entered the raffle more than once.
     * @dev Reverts if the user has already entered.
     */

    modifier checkForDuplicates() {
        if (s_hasEntered[msg.sender]) {
            revert ZephyraNFT__PlayerCantEnterMoreThanOnce();
        }
        s_hasEntered[msg.sender] = true;
        _;
    }





    // ══════════════════════════════════════════
    // ══ CONSTRUCTOR
    // ══════════════════════════════════════════



    constructor(
        address _token,
        uint256 _minRequiredBalance,
        uint256 _entryFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) ERC721("ZephyraNFT", "ZEPHY") VRFConsumerBaseV2Plus(_vrfCoordinator) {
        require(_token != address(0), "Invalid token address");
        i_zusd = IZephyraStableCoin(_token);

        s_minRequiredBalance = _minRequiredBalance;

        i_entryFee = _entryFee;
        i_interval = _interval;
        i_keyHash = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        i_subscriptionId = _subscriptionId;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address _to) public onlyOwner {
        uint256 tokenIdCounter = s_tokenIdCounter;
        _safeMint(_to, tokenIdCounter);

        unchecked {
            s_tokenIdCounter++;
        }
        
        emit NftMinted(_to, tokenIdCounter);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }


    receive() external payable {}


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert ZephyraNFT__TokenDoesNotExist(tokenId);
        }

        string memory imageURI = "ipfs://bafkreihhlim2sqjyfvp23cxgqqpkuuo5hq6u2mkoyex4y3q6pcujia7b5a";
        
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(), 
                            '", "description":"An NFT for trusted users, with more than 10,000 ZUSD, 100% on Chain!", ',
                            '"attributes": [{"trait_type": "moodiness", "value": 100}], "image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }


    function tryLuck() public payable isEligible /* NotAvailableCurrently */ checkForDuplicates {

        if (msg.value < i_entryFee) {
            revert ZephyraNFT__NotEnoughEntryFee();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert ZephyraNFT__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }


    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasEth = address(this).balance > 0;
        bool hasPlayer = s_players.length > 1;
        upkeepNeeded = (timeHasPassed && isOpen && hasEth && hasPlayer);
        return (upkeepNeeded, "0x0");
    }



    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        
        if(!upkeepNeeded){
            revert ZephyraNFT__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CLOSED;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

        emit RaffleRequestWinner(requestId);
    }




    function fulfillRandomWords(uint256 /* requestId */, uint256[] calldata randomWords) internal override {
        // checks

        // Effects(Internal Contract State)
        
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address theWinner = s_players[indexOfWinner];

        s_recentWinner = theWinner;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        emit RaffleWinner(theWinner);

        // Interactions
        uint256 tokenIdCounter = s_tokenIdCounter;
        _safeMint(theWinner, tokenIdCounter);

        unchecked {
            s_tokenIdCounter++;
        }
        s_hasClaimed[theWinner] = true;
        
        emit NftMinted(theWinner, tokenIdCounter);
        

    }



    // A function to withdraw the Native Eth deposited


    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }



    // ══════════════════════════════════════════
    // ══ GETTERS
    // ══════════════════════════════════════════

    function getAllPlayers() external view returns (address payable[] memory) {
        return s_players;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
    
    function getEntryFee() external view returns (uint256) {
        return i_entryFee;
    }
}