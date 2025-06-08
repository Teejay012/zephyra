// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract ZephyraStableCoin is ERC20Burnable, Ownable, Pausable {

    error ZephyraStableCoin__AddressNotValid();
    error ZephyraStableCoin__AmountShouldBeGreaterThanZero();
    error ZephyraStableCoin__InsufficientBalance();

    constructor(uint256 _initialSupply) ERC20("Zephyra", "ZUSD") Ownable(msg.sender) {
        _mint(msg.sender, _initialSupply);
    }

    function mint(address _account, uint256 _amount) external onlyOwner returns(bool) {
        if(_account == address(0)) {
            revert ZephyraStableCoin__AddressNotValid();
        }

        if (_amount == 0) {
            revert ZephyraStableCoin__AmountShouldBeGreaterThanZero();
        }

        _mint(_account, _amount);

        return true;
    }

    function burn(uint256 _amount) public override {

        uint256 balance = balanceOf(msg.sender);

        if (_amount == 0) {
            revert ZephyraStableCoin__AmountShouldBeGreaterThanZero();
        }

        if (balance < _amount) {
            revert ZephyraStableCoin__InsufficientBalance();
        }

        super.burn(_amount);
    }
}