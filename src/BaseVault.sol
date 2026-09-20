// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BaseVault {
    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public balanceOf;

    constructor(IERC20 _asset) {
        asset = _asset;
    }
}
