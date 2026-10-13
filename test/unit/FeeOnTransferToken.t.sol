// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {FeeOnTransferToken} from "../../src/fee-on-transfer/FeeOnTransferToken.sol";
contract FeeOnTransferTokenTest is Test {
    FeeOnTransferToken feeOnTransferToken;
    uint256 DECIMALS = 10 ** 18;
    address CREATOR = makeAddr("creator");
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");

    function setUp() external {
        feeOnTransferToken = new FeeOnTransferToken(CREATOR);
        feeOnTransferToken.mint(USER1, 1000 * DECIMALS);
    }
    function testNoFeeOnMint() public {
        assertEq(feeOnTransferToken.balanceOf(USER1), 1000 * DECIMALS);
    }

    function testTransferTakesTenPercentFee() public {
        vm.prank(USER1);
        feeOnTransferToken.transfer(USER2, 100 * DECIMALS);
        assertEq(feeOnTransferToken.balanceOf(USER2), 90 * DECIMALS);
        assertEq(feeOnTransferToken.balanceOf(CREATOR), 10 * DECIMALS);
        assertEq(feeOnTransferToken.balanceOf(USER1), 900 * DECIMALS);
    }
}
