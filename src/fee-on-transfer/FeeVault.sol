// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeVault {
    IERC20 public immutable asset;
    mapping(address => uint256) public balanceOf;
    constructor(IERC20 _asset) {
        asset = _asset;
    }

    function deposit(uint256 amount) public {
        asset.transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] += amount;
    }
    function withdraw(uint256 amount) public {
        balanceOf[msg.sender] -= amount;
        asset.transfer(msg.sender, amount);
    }
}
