// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//for solving inflation attack we create share when creating vault

contract DeadShareVault {
    error DeadShareVault__ZeroAmount();
    error DeadShareVault__WithdrawAmountIsMoreThanCurrentShare();

    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public balanceOf;

    constructor(IERC20 _asset, address _notActiveAddress, uint256 _amount) {
        asset = _asset;
        balanceOf[_notActiveAddress] = _amount;
        totalShares += _amount;
        //asset.transferFrom(msg.sender, address(this), _amount); chicken egg problem
    }

    function deposit(
        uint256 _amountToken
    ) public returns (uint256 _shareAmount) {
        uint256 shares;
        if (_amountToken == 0) {
            revert DeadShareVault__ZeroAmount();
        } else {
            if (totalShares == 0) {
                balanceOf[msg.sender] = balanceOf[msg.sender] + _amountToken;
                shares = _amountToken;
            } else {
                shares =
                    (_amountToken * totalShares) /
                    asset.balanceOf(address(this));
                balanceOf[msg.sender] += shares;
            }
        }

        asset.transferFrom(msg.sender, address(this), _amountToken);
        totalShares += shares;
        return (shares);
    }

    function withdraw(uint256 _shareAmount) public returns (uint256) {
        if (_shareAmount == 0) {
            revert DeadShareVault__ZeroAmount();
        } else {
            if (_shareAmount <= balanceOf[msg.sender]) {
                uint256 tokenWithdrawAmount = (_shareAmount *
                    asset.balanceOf(address(this))) / totalShares;
                balanceOf[msg.sender] -= _shareAmount;
                totalShares -= _shareAmount;
                asset.transfer(msg.sender, tokenWithdrawAmount);
                return (tokenWithdrawAmount);
            } else {
                revert DeadShareVault__WithdrawAmountIsMoreThanCurrentShare();
            }
        }
    }
}
