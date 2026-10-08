// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract VulnerableAuction {
    address public lastGetter;
    uint256 public lastBid;
    error VulnerableAuction__LowBidAmount();
    error VulnerableAuction__PaymentUnsuccesfull();

    function bid() public payable {
        if (lastGetter == address(0)) {
            if (msg.value == 0) revert VulnerableAuction__LowBidAmount();
            else {
                lastGetter = msg.sender;
                lastBid = msg.value;
            }
        } else {
            if (msg.value > lastBid) {
                //if state-change action 
                //CEI
                address oldGetter = lastGetter;
                uint256 oldBid = lastBid;
                lastGetter = msg.sender;
                lastBid = msg.value;
                (bool success, ) = oldGetter.call{value: oldBid}(""); //if there are not receive or fallback automaticly revert
                if (!success) revert VulnerableAuction__PaymentUnsuccesfull();
            } else revert VulnerableAuction__LowBidAmount();
        }
    }
}
