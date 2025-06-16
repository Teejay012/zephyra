// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Local imports for the ZephyraSender contract.
import {IZephyraStableCoin} from "src/interface/IZephyraStableCoin.sol";

// Importing necessary interfaces and libraries from CCIP contracts.
import {IRouterClient} from "ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "ccip/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @title - A simple contract for transferring tokens across chains.
contract ZephyraCrossChainTransfer is OwnerIsCreator {
    using SafeERC20 for IERC20;


    // ══════════════════════════════════════════
    // ══ ERRORS
    // ══════════════════════════════════════════


    // Custom errors to provide more descriptive revert messages.
    error ZephyraCrossChainTransfer__NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error ZephyraCrossChainTransfer__NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error ZephyraCrossChainTransfer__FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error ZephyraCrossChainTransfer__DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error ZephyraCrossChainTransfer__InvalidReceiverAddress(); // Used when the receiver address is 0.
    error ZephyraCrossChainTransfer__InsufficientLINKBalance(); // Used when the user does not have enough LINK tokens to pay for the fees.
    error ZephyraCrossChainTransfer__InsufficientZUSDBalance(uint256 currentBalance, uint256 calculatedFees); // Used when the user does not have enough ZUSD tokens to pay for the transfer amount.

    

    // ══════════════════════════════════════════
    // ══ EVENTS
    // ══════════════════════════════════════════


    // Event emitted when the tokens are transferred to an account on another chain.
    event TokensTransferred(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );





    // ══════════════════════════════════════════ 
    // ══ STATE VARIABLES
    // ══════════════════════════════════════════


    // Mapping to keep track of allowlisted destination chains.
    mapping(uint64 => bool) public allowlistedChains;

    IRouterClient private i_router;

    IERC20 private i_linkToken;

    IERC20 private i_zusd;


    


    // ══════════════════════════════════════════
    // ══ CONSTRUCTOR
    // ══════════════════════════════════════════




    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    constructor(address _router, address _link, address _zephyraStableCoin) OwnerIsCreator() {
        i_router = IRouterClient(_router);
        i_linkToken = IERC20(_link);
        i_zusd = IERC20(_zephyraStableCoin);
    }



    

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is transferred to the contract without any data.
    receive() external payable {}

    fallback() external payable {}





    // ══════════════════════════════════════════
    // ══ MODIFIERS
    // ══════════════════════════════════════════



    /// @dev Modifier that checks if the chain with the given destinationChainSelector is allowlisted.
    /// @param _destinationChainSelector The selector of the destination chain.
    modifier onlyAllowlistedChain(uint64 _destinationChainSelector) {
        if (!allowlistedChains[_destinationChainSelector])
            revert ZephyraCrossChainTransfer__DestinationChainNotAllowlisted(_destinationChainSelector);
        _;
    }

    /// @dev Modifier that checks the receiver address is not 0.
    /// @param _receiver The receiver address.
    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert ZephyraCrossChainTransfer__InvalidReceiverAddress();
        _;
    }










    // ══════════════════════════════════════════
    // ══ EXTERNAL FUNCTIONS
    // ══════════════════════════════════════════


    /// @dev Updates the allowlist status of a destination chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be updated.
    /// @param allowed The allowlist status to be set for the destination chain.
    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedChains[_destinationChainSelector] = allowed;
    }

    /// @notice Transfer tokens to receiver on the destination chain.
    /// @notice pay in LINK.
    /// @notice the token must be in the list of supported tokens.
    /// @dev Assumes your contract has sufficient LINK tokens to pay for the fees.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _receiver The address of the recipient on the destination blockchain.
    /// @param _amount token amount.
    /// @return messageId The ID of the message that was sent.
    function transferTokensPayLINK(
        uint64 _destinationChainSelector,
        address _receiver,
        uint256 _amount
    )
        external
        onlyAllowlistedChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        if (_amount > i_zusd.balanceOf(msg.sender)) {
            revert ZephyraCrossChainTransfer__InsufficientZUSDBalance(i_zusd.balanceOf(msg.sender), _amount);
        }


        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        //  address(linkToken) means fees are paid in LINK
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            address(i_zusd),
            _amount,
            address(i_linkToken)
        );

        // Get the fee required to send the message
        uint256 fees = i_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        uint256 userLinkBalance = i_linkToken.balanceOf(msg.sender);

        if (userLinkBalance < fees)
            revert ZephyraCrossChainTransfer__InsufficientLINKBalance();

        uint256 allowance = i_linkToken.allowance(msg.sender, address(this));
        if (allowance < fees) {
            revert ZephyraCrossChainTransfer__InsufficientLINKBalance();
        }

        // Collect LINK fees from the user
        i_linkToken.transferFrom(msg.sender, address(this), fees);

        i_zusd.transferFrom(msg.sender, address(this), _amount);
        
        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        i_linkToken.approve(address(i_router), fees);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        i_zusd.approve(address(i_router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = i_router.ccipSend(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            address(i_zusd),
            _amount,
            address(i_linkToken),
            fees
        );

        // Return the message ID
        return messageId;
    }

    /// @notice Transfer tokens to receiver on the destination chain.
    /// @notice Pay in native gas such as ETH on Ethereum or POL on Polygon.
    /// @notice the token must be in the list of supported tokens.
    /// @dev Assumes your contract has sufficient native gas like ETH on Ethereum or POL on Polygon.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _receiver The address of the recipient on the destination blockchain.
    /// @param _amount token amount.
    /// @return messageId The ID of the message that was sent.
    function transferTokensPayNative(
        uint64 _destinationChainSelector,
        address _receiver,
        uint256 _amount
    )
        external
        onlyAllowlistedChain(_destinationChainSelector)
        validateReceiver(_receiver)
        payable
        returns (bytes32 messageId)
    {

        if (_amount > i_zusd.balanceOf(msg.sender)) {
            revert ZephyraCrossChainTransfer__NotEnoughBalance(i_zusd.balanceOf(msg.sender), _amount);
        }

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        // address(0) means fees are paid in native gas
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            address(i_zusd),
            _amount,
            address(0)
        );

        // Get the fee required to send the message
        uint256 fees = i_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > msg.value)
            revert ZephyraCrossChainTransfer__NotEnoughBalance(msg.value, fees);

        // Collect the token amount from the user
        // transfer the tokens from the user to the contract
        i_zusd.transferFrom(msg.sender, address(this), _amount);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        i_zusd.approve(address(i_router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = i_router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            address(i_zusd),
            _amount,
            address(0),
            fees
        );

        // Return the message ID
        return messageId;
    }










    // ══════════════════════════════════════════
    // ══ PRIVATE FUNCTIONS
    // ══════════════════════════════════════════

    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: "", // No data
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit and allowing out-of-order execution.
                    // Best Practice: For simplicity, the values are hardcoded. It is advisable to use a more dynamic approach
                    // where you set the extra arguments off-chain. This allows adaptation depending on the lanes, messages,
                    // and ensures compatibility with future CCIP upgrades. Read more about it here: https://docs.chain.link/ccip/concepts/best-practices/evm#using-extraargs
                    Client.EVMExtraArgsV1({
                        gasLimit: 200_000 // Gas limit for the callback on the destination chain
                    })
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }













    /// @notice Allows the contract owner to withdraw the entire balance of Ether from the contract.
    /// @dev This function reverts if there are no funds to withdraw or if the transfer fails.
    /// It should only be callable by the owner of the contract.
    /// @param _beneficiary The address to which the Ether should be transferred.
    function withdraw(address _beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert ZephyraCrossChainTransfer__NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = payable(_beneficiary).call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert ZephyraCrossChainTransfer__FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    /// @notice Allows the owner of the contract to withdraw all LINK tokens from the contract.
    /// @dev This function reverts with a 'ZephyraCrossChainTransfer__NothingToWithdraw' error if there are no LINK tokens to withdraw.
    /// @dev This function can only be called by the owner of the contract.
    /// @dev This function uses SafeERC20 to safely transfer LINK tokens.
    /// @dev This function is useful for recovering LINK tokens that were used to pay for CCIP fees.
    function withdrawLink(address _beneficiary) external onlyOwner {
        uint256 balance = i_linkToken.balanceOf(address(this));
        if (balance == 0) revert ZephyraCrossChainTransfer__NothingToWithdraw();
        i_linkToken.safeTransfer(_beneficiary, balance);
    }

    /// @notice Allows the owner of the contract to withdraw all tokens of a specific ERC20 token.
    /// @dev This function reverts with a 'ZephyraCrossChainTransfer__NothingToWithdraw' error if there are no tokens to withdraw.
    /// @param _beneficiary The address to which the tokens will be sent.
    /// @param _token The contract address of the ERC20 token to be withdrawn.
    function withdrawToken(
        address _beneficiary,
        address _token
    ) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert ZephyraCrossChainTransfer__NothingToWithdraw();

        IERC20(_token).safeTransfer(_beneficiary, amount);
    }









    // ══════════════════════════════════════════
    // ══ VIEW FUNCTIONS
    // ══════════════════════════════════════════
    /// @notice Get the estimated fee for sending a message to a destination chain.
    /// @dev This function calculates the fee required to send a message to a destination chain.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _receiver The address of the recipient on the destination blockchain.
    /// @param _amount The amount of tokens to be transferred.
    /// @param payInLink Whether to pay the fees in LINK or native gas.
    /// @return The estimated fee in wei for sending the message.


    function getEstimatedFee(
        uint64 _destinationChainSelector,
        address _receiver,
        uint256 _amount,
        bool payInLink
    ) external view returns (uint256) {
        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            _receiver,
            address(i_zusd),
            _amount,
            payInLink ? address(i_linkToken) : address(0)
        );
        return i_router.getFee(_destinationChainSelector, message);
    }
}
