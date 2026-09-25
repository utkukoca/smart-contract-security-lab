// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VaultTestBase} from "../helpers/VaultTestBase.sol";
import {BaseVault} from "../../src/BaseVault.sol";

contract BaseVaultTest is VaultTestBase {
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
        assertEq(FIRST_AMOUNT, baseVault.balanceOf(USER));
        assertEq(FIRST_AMOUNT * 2, baseVault.balanceOf(USER2));
    }

    function test_DonationIncreasesSharePrice() external {
        //vault can increase but users have to be get fair shares
        vm.prank(USER);
        baseVault.deposit(FIRST_AMOUNT);

        vm.prank(ATTACKER);
        mockToken.transfer(address(baseVault), 900 * DECIMALS);

        vm.prank(USER2);
        baseVault.deposit(FIRST_AMOUNT);

        // assert
        // total value 1000 and total shares 100 so 1 shares equal to 10 --> USER2 deposit 100 so have to get 10 shares
        // TOKEN_AMOUNT = VAULT_ASSETS X DEPOSITOR_SHARES

        assertEq(10 * DECIMALS, baseVault.balanceOf(USER2));
    }

    function test_Withdraw_UpdatesAllStatesCorrectly() external {
        //arrange
        vm.startPrank(USER);

        //act
        baseVault.deposit(FIRST_AMOUNT);
        baseVault.withdraw(FIRST_AMOUNT);

        vm.stopPrank();

        //assert

        //A.USER share holders equal 0
        assertEq(0, baseVault.balanceOf(USER));
        //B.VAULT token equal 0
        assertEq(0, mockToken.balanceOf(address(baseVault)));
        //C.VAULT share holders equal 0
        assertEq(0, baseVault.totalShares());
        //D.USER balance have to be same
        assertEq(STARTING_BALANCE, mockToken.balanceOf(USER));
    }
    function test_Partial_Withdraw_UpdatesAllStatesCorrectly() external {
        //arrange
        vm.startPrank(USER);

        //act
        baseVault.deposit(FIRST_AMOUNT);
        baseVault.withdraw(FIRST_AMOUNT / 2);

        vm.stopPrank();

        //assert

        //A.USER share holders
        assertEq(FIRST_AMOUNT / 2, baseVault.balanceOf(USER));
        //B.VAULT token
        assertEq(FIRST_AMOUNT / 2, mockToken.balanceOf(address(baseVault)));
        //C.VAULT share holders
        assertEq(FIRST_AMOUNT / 2, baseVault.totalShares());
        //D.USER balance
        assertEq(
            STARTING_BALANCE - (FIRST_AMOUNT / 2),
            mockToken.balanceOf(USER)
        );
    }
}
