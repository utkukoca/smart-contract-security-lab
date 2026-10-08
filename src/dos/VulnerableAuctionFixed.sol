// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract VulnerableAuctionFixed {
    address public lastGetter;
    uint256 public lastBid;
    mapping(address => uint256) public pendingRefunds;
    uint256 public debtBid;
    error VulnerableAuctionFixed__LowBidAmount();
    error VulnerableAuctionFixed__PaymentUnsuccesfull();
    error VulnerableAuctionFixed__NotTrueDebtAddress();

    function bid() public payable {
        if (lastGetter == address(0)) {
            if (msg.value == 0) revert VulnerableAuctionFixed__LowBidAmount();
            else {
                lastGetter = msg.sender;
                lastBid = msg.value;
            }
        } else {
            if (msg.value > lastBid) {
                //if state-change action
                //CEI

                pendingRefunds[lastGetter] += lastBid;
                lastGetter = msg.sender;
                lastBid = msg.value;
            } else revert VulnerableAuctionFixed__LowBidAmount();
        }
    }

    function withdraw() public {
        uint256 amount = pendingRefunds[msg.sender];
        if (amount == 0) revert VulnerableAuctionFixed__NotTrueDebtAddress();
        pendingRefunds[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert VulnerableAuctionFixed__PaymentUnsuccesfull();
    }
}
