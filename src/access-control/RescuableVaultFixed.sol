// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {InternalAccountingVault} from "../InternalAccountingVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RescuableVaultFixed is InternalAccountingVault {
    address public immutable OWNER;
    error RescuableVaultFixed__NotOwner();

    constructor(IERC20 _asset) InternalAccountingVault(_asset) {
        OWNER = msg.sender;
    }

    function rescueTokens(address to) public {
        if (msg.sender != OWNER) revert RescuableVaultFixed__NotOwner();
        else {
            uint256 rescueTokenAmount = asset.balanceOf(address(this)) -
                balanceOfVault[address(this)];
            asset.transfer(to, rescueTokenAmount);
        }
    }
}
