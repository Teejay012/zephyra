// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Importing necessary interfaces and libraries from CCIP contracts.
import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "ccip/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @title - A simple contract for receiving string data across chains.

contract ZephyraReceiver is CCIPReceiver {
    // ══════════════════════════════════════════
    // ══ EVENTS
    // ══════════════════════════════════════════

    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text, // The text that was received.
        uint256 tokenAmount // The amount of token sent.
    );

    // ══════════════════════════════════════════
    // ══ STATE VARIABLES
    // ══════════════════════════════════════════

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    uint256 private s_lastReceivedTokenAmount; // Store the last received token amount.
    string private s_lastReceivedText; // Store the last received text.

    // ══════════════════════════════════════════
    // ══ CONSTRUCTOR
    // ══════════════════════════════════════════

    constructor(address router) CCIPReceiver(router) {}

    // ══════════════════════════════════════════
    // ══ OVERRIDES
    // ══════════════════════════════════════════

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        // Store the last received message details
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text
        s_lastReceivedTokenAmount = any2EvmMessage.destTokenAmounts.length > 0
            ? any2EvmMessage.destTokenAmounts[0].amount // fetch the token amount sent
            : 0; // if no token amounts, set to 0


        // Emit the MessageReceived event with the details of the received message

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            abi.decode(any2EvmMessage.data, (string)), // fetch the text sent
            any2EvmMessage.destTokenAmounts[0].amount // fetch the token amount sent
        );
    }

    /// @notice Fetches the details of the last received message.
    /// @return messageId The ID of the last received message.
    /// @return text The last received text.
    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text, uint256 tokenAmount)
    {
        return (s_lastReceivedMessageId, s_lastReceivedText, s_lastReceivedTokenAmount);
    }
}

// 0xC04F6E050CD3e86011C4C2A7707C4A9B0AE0b3b7