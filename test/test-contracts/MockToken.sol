// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MCK") {
        _mint(msg.sender, 1000 * 10 ** decimals()); //we cannot send 0.5 token so we use 10^18 like wei
    }

    function mint(address _toAddress, uint256 _amount) public {
        _mint(_toAddress, _amount);
    }
}
