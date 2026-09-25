// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseVault} from "../../src/BaseVault.sol";
import {MockToken} from "../test-contracts/MockToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract BaseVaultTest is Test {
    BaseVault public baseVault;
    MockToken public mockToken;
    address public USER = makeAddr("user"); //test address
    address public USER2 = makeAddr("user2"); //test address
    uint256 public constant FIRST_AMOUNT = 100;

    function setUp() external {
        mockToken = new MockToken();
        baseVault = new BaseVault(mockToken);

        mockToken.mint(USER, 1000 * 10 ** 18); //mint mock money for USER
        vm.prank(USER);
        mockToken.approve(address(baseVault), type(uint256).max); //we have to use approve in this section if we use in BaseVault we approve to user can use token which in BaseVault

        mockToken.mint(USER2, 1000 * 10 ** 18); //mint mock money for USER2
        vm.prank(USER2);
        mockToken.approve(address(baseVault), type(uint256).max); //we have to use approve in this section if we use in BaseVault we approve to user can use token which in BaseVault
    }

    function testEqTokenAddress() external view {
        assertEq(address(mockToken), address(baseVault.asset()));
    }

    function testVaultBegining() external view {
        assertEq(baseVault.totalShares(), 0);
    }

    function test_Deposit_UpdatesAllStatesCorrectly() external {
        //arrange
        vm.startPrank(USER);

        //act
        baseVault.deposit(FIRST_AMOUNT);
        vm.stopPrank();

        //assert

        //A.USER share holders increase
        assertEq(FIRST_AMOUNT, baseVault.balanceOf(USER));
        //B.VAULT token increase
        assertEq(FIRST_AMOUNT, mockToken.balanceOf(address(baseVault)));
        //C.VAULT share holders increase
        assertEq(FIRST_AMOUNT, baseVault.totalShares());
    }

    function test_DepositAmount_Zero() external {
        //arrange
        vm.startPrank(USER);

        //act-asssert
        vm.expectRevert(BaseVault.BaseVault__ZeroAmount.selector);
        baseVault.deposit(0);
        vm.stopPrank();
    }

    function test_SameUserDepositsTwiceAccumulates() external {
        //arrange
        vm.startPrank(USER);

        //act
        baseVault.deposit(FIRST_AMOUNT);
        baseVault.deposit(FIRST_AMOUNT);
        vm.stopPrank();

        //assert
        assertEq(FIRST_AMOUNT + FIRST_AMOUNT, baseVault.balanceOf(USER));
        assertEq(FIRST_AMOUNT + FIRST_AMOUNT, baseVault.totalShares());
    }

    function test_SubsequentDepositsKeepProportion() external {
        //arrange-act
        vm.prank(USER);
        baseVault.deposit(FIRST_AMOUNT);
        vm.prank(USER2);
        baseVault.deposit(2 * FIRST_AMOUNT);

        //assert

        //USER1 DEPLOY 100 AND TAKE 100 SHARES USER2 DEPLOY 200 HAVE TO TAKE 200 1/3 AND 2/3
        assertEq(100, baseVault.balanceOf(USER));
        assertEq(200, baseVault.balanceOf(USER2));
    }
}
