// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Local imports for the ZephyraSender contract.
import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";

// Importing necessary interfaces and libraries from CCIP contracts.
import {IRouterClient} from "ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "ccip/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "ccip/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract ZephyraSender is OwnerIsCreator {

    // ══════════════════════════════════════════
    // ══ ERRORS
    // ══════════════════════════════════════════

    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.


    // ══════════════════════════════════════════
    // ══ EVENTS
    // ══════════════════════════════════════════

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        uint256 tokenAmount, // The amount of token sent
        string text, // The text being sent.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );





    // ══════════════════════════════════════════ 
    // ══ STATE VARIABLES
    // ══════════════════════════════════════════

    IRouterClient private s_router;

    LinkTokenInterface private s_linkToken;

    IZephyraStableCoin private s_zephyraStableCoin;




    // ══════════════════════════════════════════
    // ══ CONSTRUCTOR
    // ══════════════════════════════════════════




    /**
     * @notice Constructor to initialize the contract with the CCIP router and Link token.
     * @param _router The address of the CCIP router.
     * @param _linkToken The address of the LINK token contract.
     * @param _zephyraStableCoin The address of the Zephyra stablecoin contract.
     */
    constructor(
        address _router,
        address _linkToken,
        IZephyraStableCoin _zephyraStableCoin
    ) OwnerIsCreator() {
        s_router = IRouterClient(_router);
        s_linkToken = LinkTokenInterface(_linkToken);
        s_zephyraStableCoin = _zephyraStableCoin;
    }





    // ══════════════════════════════════════════
    // ══ EXTERNAL FUNCTIONS
    // ══════════════════════════════════════════


    /**
     * @notice Sends a message to another chain using CCIP.
     * @param _destinationChainSelector The chain selector of the destination chain.
     * @param _receiver The address of the receiver on the destination chain.
     * @param _tokenAmount The amount of token to send.
     * @param _text The text to send.
     */
    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        uint256 _tokenAmount,
        string memory _text
    ) external returns (bytes32 messageId) {
        // Transfer token from user to this contract
        s_zephyraStableCoin.transferFrom(msg.sender, address(this), _tokenAmount);
        s_zephyraStableCoin.approve(address(s_router), _tokenAmount);

        // Build the message
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(s_zephyraStableCoin), // The address of the Zephyra stablecoin contract
            amount: _tokenAmount // The amount of tokens to send
        });

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: abi.encode(_text), // ABI-encoded string
            tokenAmounts: tokenAmounts, // Array of token amounts to send
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and allowing out-of-order execution.
                // Best Practice: For simplicity, the values are hardcoded. It is advisable to use a more dynamic approach
                // where you set the extra arguments off-chain. This allows adaptation depending on the lanes, messages,
                // and ensures compatibility with future CCIP upgrades. Read more about it here: https://docs.chain.link/ccip/concepts/best-practices/evm#using-extraargs
                Client.EVMExtraArgsV1({
                    gasLimit: 200_000 // Gas limit for the callback on the destination chain
                })
            ),
            feeToken: address(s_linkToken) // The token used to pay CCIP fees, in this case, LINK token.

        });


        // Get the fee required to send the message
        uint256 fees = s_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Ensure the contract has enough balance to cover the fees.
        if (s_linkToken.balanceOf(address(this)) < fees) {
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);
        }

        // // Transfer the tokens from the sender to this contract.
        // s_zephyraStableCoin.transferFrom(msg.sender, address(this), _tokenAmount);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        s_linkToken.approve(address(s_router), fees);

        // Send the message through the router and store the returned message ID
        messageId = s_router.ccipSend(_destinationChainSelector, evm2AnyMessage);


        // Emit an event for the sent message.
        emit MessageSent(
            messageId, // The unique ID of the CCIP message
            _destinationChainSelector, // The chain selector of the destination chain
            _receiver, // The address of the receiver on the destination chain
            _tokenAmount, // The amount of token sent
            _text, // The text being sent
            address(s_linkToken), // The token address used to pay CCIP fees
            fees // The fees paid for sending the CCIP message
        );

        
        // Return the message ID for reference.

        return messageId;
    }
    /**
     * @notice Returns the address of the Zephyra stablecoin contract.
     * @return The address of the Zephyra stablecoin contract.
     */
    function zephyraStableCoin() external view returns (address) {
        return address(s_zephyraStableCoin);
    }
}