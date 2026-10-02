// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableBank {
    mapping(address => uint256) public balanceOfUser;
    error VulnerableBank__MoneyNotSend();
    error VulnerableBank__UserBalanceIsZero();
    error VulnerableBank__DepositAmountIsZero();

    function deposit() public payable {
        if (msg.value == 0) revert VulnerableBank__DepositAmountIsZero();
        balanceOfUser[msg.sender] += msg.value;
    }
    function withdraw() public payable {
        uint256 balanceUser = balanceOfUser[msg.sender];
        if (balanceUser == 0) revert VulnerableBank__UserBalanceIsZero();
        (bool success, ) = msg.sender.call{value: balanceUser}("");
        if (!success) {
            revert VulnerableBank__MoneyNotSend();
        }
        balanceOfUser[msg.sender] = 0;
    }
}
