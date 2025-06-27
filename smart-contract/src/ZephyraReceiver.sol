    // // SPDX-License-Identifier: MIT
    // pragma solidity 0.8.24;

    // // Chainlink CCIP imports
    // import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
    // import {CCIPReceiver} from "ccip/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";

    // // OpenZeppelin ERC20
    // import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

    // /// @title ZephyraReceiver
    // /// @notice A receiver contract that handles incoming CCIP token transfers and forwards them to users
    // contract ZephyraReceiver is CCIPReceiver {


    //     error ZephyraReceiver__NoTokenReceived();
    //     error ZephyraReceiver__AmountMismatch();




    //     /// @notice Emitted when a message is successfully received and tokens are forwarded
    //     event MessageReceived(
    //         bytes32 indexed messageId,
    //         uint64 indexed sourceChainSelector,
    //         address indexed user,
    //         address token,
    //         uint256 amount
    //     );

    //     /// @notice Constructor sets the CCIP router address for this chain
    //     /// @param _router The address of the Chainlink CCIP router
    //     constructor(address _router) CCIPReceiver(_router) {}

    //     /// @notice Handles incoming CCIP messages with token transfers
    //     /// @dev This function is automatically called by the CCIP router
    //     /// @param message The full message containing token and data payload
    //     function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
    //         // Decode the original user wallet and amount from the data payload
    //         (address userWallet, uint256 expectedAmount) = abi.decode(message.data, (address, uint256));

    //         // Ensure there's at least one token

    //         if (message.destTokenAmounts.length == 0) {
    //             revert ZephyraReceiver__NoTokenReceived();
    //         }

    //         Client.EVMTokenAmount memory tokenInfo = message.destTokenAmounts[0];

    //         if (tokenInfo.amount < expectedAmount) {
    //             revert ZephyraReceiver__AmountMismatch();
    //         }

    //         // Forward the tokens to the actual user wallet
    //         IERC20(tokenInfo.token).transfer(userWallet, tokenInfo.amount);

    //         emit MessageReceived(
    //             message.messageId,
    //             message.sourceChainSelector,
    //             userWallet,
    //             tokenInfo.token,
    //             tokenInfo.amount
    //         );
    //     }
    // }
