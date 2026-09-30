// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//attackers can sent money thanks to token transfer so instad of reading asset in contract not using ERC20
contract InternalAccountingVault {
    error InternalAccountingVault__ZeroAmount();
    error InternalAccountingVault__WithdrawAmountIsMoreThanCurrentShare();

    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public balanceOfVault;

    constructor(IERC20 _asset) {
        asset = _asset;
    }

    function deposit(
        uint256 _amountToken
    ) public returns (uint256 _shareAmount) {
        uint256 shares;
        if (_amountToken == 0) {
            revert InternalAccountingVault__ZeroAmount();
        } else {
            if (totalShares == 0) {
                balanceOf[msg.sender] = balanceOf[msg.sender] + _amountToken;
                balanceOfVault[address(this)] =
                    balanceOfVault[address(this)] +
                    _amountToken;
                shares = _amountToken;
            } else {
                shares =
                    (_amountToken * totalShares) /
                    balanceOfVault[address(this)];
                balanceOf[msg.sender] += shares;
                balanceOfVault[address(this)] =
                    balanceOfVault[address(this)] +
                    _amountToken;
            }
        }

        asset.transferFrom(msg.sender, address(this), _amountToken);
        totalShares += shares;
        return (shares);
    }

    function withdraw(uint256 _shareAmount) public returns (uint256) {
        if (_shareAmount == 0) {
            revert InternalAccountingVault__ZeroAmount();
        } else {
            if (_shareAmount <= balanceOf[msg.sender]) {
                uint256 tokenWithdrawAmount = ((_shareAmount *
                    balanceOfVault[address(this)]) / totalShares);
                balanceOf[msg.sender] -= _shareAmount;
                totalShares -= _shareAmount;
                balanceOfVault[address(this)] =
                    balanceOfVault[address(this)] -
                    tokenWithdrawAmount;
                asset.transfer(msg.sender, tokenWithdrawAmount);
                return (tokenWithdrawAmount);
            } else {
                revert InternalAccountingVault__WithdrawAmountIsMoreThanCurrentShare();
            }
        }
    }
}
