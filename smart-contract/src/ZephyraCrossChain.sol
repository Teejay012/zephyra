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


/// @title - A simple contract for transferring tokens across chains.
contract ZephyraCrossChainTransfer is OwnerIsCreator {
    using SafeERC20 for IERC20;


    // ══════════════════════════════════════════
    // ══ ERRORS
    // ══════════════════════════════════════════


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


    event TokensTransferred(
        bytes32 indexed messageId, 
        uint64 indexed destinationChainSelector, 
        address receiver, 
        address token, 
        uint256 tokenAmount, 
        address feeToken, 
        uint256 fees 
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
    /// @notice Pay in LINK tokens for the fees.
    /// @notice the token must be in the list of supported tokens.
    /// @dev Assumes your contract has sufficient LINK tokens to pay for the fees.
    /// @param _destChain The identifier (aka selector) for the destination blockchain.
    /// @param _zephyraReceiver The address of the Zephyra receiver contract on the destination blockchain.
    /// @param _userWallet The address of the user wallet that should receive the tokens.
    /// @param _amount The amount of tokens to be transferred.
    /// @return messageId The ID of the message that was sent.

    function transferTokensPayLINK(
        uint64 _destChain,
        address _zephyraReceiver,
        address _userWallet,
        uint256 _amount
    )
        external
        onlyAllowlistedChain(_destChain)
        validateReceiver(_zephyraReceiver)
        validateReceiver(_userWallet)
        returns (bytes32 messageId)
    {
        if (_amount > i_zusd.balanceOf(msg.sender)) {
            revert ZephyraCrossChainTransfer__InsufficientZUSDBalance(i_zusd.balanceOf(msg.sender), _amount);
        }

        Client.EVM2AnyMessage memory evmMessage = _buildCCIPMessage(
            _zephyraReceiver,
            _userWallet,
            address(i_zusd),
            _amount,
            address(i_linkToken)
        );

        uint256 fee = i_router.getFee(_destChain, evmMessage);
        if (i_linkToken.balanceOf(msg.sender) < fee || i_linkToken.allowance(msg.sender, address(this)) < fee) {
            revert ZephyraCrossChainTransfer__InsufficientLINKBalance();
        }

        i_linkToken.transferFrom(msg.sender, address(this), fee);
        i_zusd.transferFrom(msg.sender, address(this), _amount);

        i_linkToken.approve(address(i_router), fee);
        i_zusd.approve(address(i_router), _amount);

        messageId = i_router.ccipSend(_destChain, evmMessage);

        emit TokensTransferred(
            messageId,
            _destChain,
            _userWallet,
            address(i_zusd),
            _amount,
            address(i_linkToken),
            fee
        );
    }










    /// @notice Transfer tokens to receiver on the destination chain.
    /// @notice Pay in native gas for the fees.
    /// @notice the token must be in the list of supported tokens.
    /// @dev Assumes your contract has sufficient ZUSD tokens to pay for the transfer amount.
    /// @param _destChain The identifier (aka selector) for the destination blockchain.
    /// @param _zephyraReceiver The address of the Zephyra receiver contract on the destination blockchain.
    /// @param _userWallet The address of the user wallet that should receive the tokens.
    /// @param _amount The amount of tokens to be transferred.
    /// @return messageId The ID of the message that was sent.

    function transferTokensPayNative(
        uint64 _destChain,
        address _zephyraReceiver,
        address _userWallet,
        uint256 _amount
    )
        external
        payable
        onlyAllowlistedChain(_destChain)
        validateReceiver(_zephyraReceiver)
        validateReceiver(_userWallet)
        returns (bytes32 messageId)
    {
        if (_amount > i_zusd.balanceOf(msg.sender)) {
            revert ZephyraCrossChainTransfer__InsufficientZUSDBalance(i_zusd.balanceOf(msg.sender), _amount);
        }

        // Build the CCIP message: feeToken = address(0) indicates native gas
        Client.EVM2AnyMessage memory evmMessage = _buildCCIPMessage(
            _zephyraReceiver,
            _userWallet,
            address(i_zusd),
            _amount,
            address(0) // native fee
        );

        uint256 fee = i_router.getFee(_destChain, evmMessage);
        if (msg.value < fee) {
            revert ZephyraCrossChainTransfer__InsufficientLINKBalance(); // Reuse for simplicity
        }

        i_zusd.transferFrom(msg.sender, address(this), _amount);
        i_zusd.approve(address(i_router), _amount);

        messageId = i_router.ccipSend{value: fee}(_destChain, evmMessage);

        emit TokensTransferred(
            messageId,
            _destChain,
            _userWallet,
            address(i_zusd),
            _amount,
            address(0),
            fee
        );
    }











    // ══════════════════════════════════════════
    // ══ PRIVATE FUNCTIONS
    // ══════════════════════════════════════════

    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
    /// @param receiverContract The address of the receiver.
    /// @param token The token to be transferred.
    /// @param amount The amount of the token to be transferred.
    /// @param feeToken The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address receiverContract,
        address userWallet,
        address token,
        uint256 amount,
        address feeToken
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: token,
            amount: amount
        });

        return Client.EVM2AnyMessage({
            receiver: abi.encode(receiverContract),
            data: abi.encode(userWallet, amount),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            feeToken: feeToken
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
    /// @param _destinationChainSelector The selector of the destination chain.
    /// @param _zephyraReceiver The address of the Zephyra receiver contract on the destination chain.
    /// @param _userWallet The actual user wallet to receive funds.
    /// @param _amount The amount of tokens to be transferred.
    /// @param payInLink Whether to pay the fees in LINK tokens or native gas.
    /// @return The estimated fee in wei.


    function getEstimatedFee(
        uint64 _destinationChainSelector,
        address _zephyraReceiver,   // Receiver contract on the destination chain
        address _userWallet,        // The actual user wallet to receive funds
        uint256 _amount,
        bool payInLink
    ) external view returns (uint256) {
        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            _zephyraReceiver,
            _userWallet,
            address(i_zusd),
            _amount,
            payInLink ? address(i_linkToken) : address(0)
        );

        return i_router.getFee(_destinationChainSelector, message);
    }

}
