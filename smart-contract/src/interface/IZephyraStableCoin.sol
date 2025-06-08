// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface  IZephyraStableCoin {
    function mint(address _account, uint256 _amount) external returns(bool);
    function burn(uint256 _amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}