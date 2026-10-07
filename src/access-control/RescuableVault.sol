// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {InternalAccountingVault} from "../InternalAccountingVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RescuableVault is InternalAccountingVault {
    address immutable public OWNER;

    constructor(IERC20 _asset) InternalAccountingVault(_asset) {
        OWNER = msg.sender;
    }

    function rescueTokens(address to) public {
        uint256 rescueTokenAmount =
            asset.balanceOf(address(this)) -
            balanceOfVault[address(this)];
        asset.transfer(to, rescueTokenAmount);
    }
}
