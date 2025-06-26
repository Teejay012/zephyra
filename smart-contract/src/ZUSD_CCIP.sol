// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedZUSD {
    function mint(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ICCIPTransfer {
    function transferTokensPayLINK(
        uint64 destinationChainSelector,
        address receiver,
        address token,
        uint256 amount
    ) external payable;
}

contract ZUSDForwardAndWrapForCCIP {

    event ZUSDProcessed(address user, address receiver, uint256 amount);


    IERC20 public immutable i_zusd;
    IWrappedZUSD public immutable i_wrappedZusd;
    ICCIPTransfer public immutable i_ccipTransfer;
    address public immutable i_treasury; 

    constructor(
        address _zusd,
        address _wrappedZusd,
        address _ccipTransfer,
        address _treasury
    ) {
        i_zusd = IERC20(_zusd);
        i_wrappedZusd = IWrappedZUSD(_wrappedZusd);
        i_ccipTransfer = ICCIPTransfer(_ccipTransfer);
        i_treasury = _treasury;
    }

    function processAndSend(
        uint64 destinationChainSelector,
        address receiverOnDestChain,
        uint256 amount
    ) external {
        require(i_zusd.transferFrom(msg.sender, i_treasury, amount), "ZUSD transfer failed");

        i_wrappedZusd.mint(address(this), amount);

        i_wrappedZusd.approve(address(i_ccipTransfer), amount);

        i_ccipTransfer.transferTokensPayLINK(
            destinationChainSelector,
            receiverOnDestChain,
            address(i_wrappedZusd),
            amount
        );

        emit ZUSDProcessed(msg.sender, receiverOnDestChain, amount);
    }
}