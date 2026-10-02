// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VaultTestBase} from "../helpers/VaultTestBase.sol";
import {InternalAccountingVault} from "../../src/InternalAccountingVault.sol";

contract InternalAccountingVaultTest is VaultTestBase {
    function test_Deposit_UpdatesAllStatesCorrectly() external {
        //arrange
        vm.startPrank(USER);

        //act
        internalAccountingVault.deposit(FIRST_AMOUNT);
        vm.stopPrank();

        //assert

        //A.USER share holders increase
        assertEq(FIRST_AMOUNT, internalAccountingVault.balanceOf(USER));
        //B.VAULT token increase
        assertEq(
            FIRST_AMOUNT,
            internalAccountingVault.balanceOfVault(
                address(internalAccountingVault)
            )
        );
        //C.VAULT share holders increase
        assertEq(FIRST_AMOUNT, internalAccountingVault.totalShares());
    }

    function test_Withdraw_UpdatesAllStatesCorrectly() external {
        //arrange
        vm.startPrank(USER);

        //act
        internalAccountingVault.deposit(FIRST_AMOUNT);
        internalAccountingVault.withdraw(FIRST_AMOUNT);

        vm.stopPrank();

        //assert

        //A.USER share holders equal 0
        assertEq(0, internalAccountingVault.balanceOf(USER));
        //B.VAULT token equal 0
        assertEq(
            0,
            internalAccountingVault.balanceOfVault(
                address(internalAccountingVault)
            )
        );
        //C.VAULT share holders equal 0
        assertEq(0, internalAccountingVault.totalShares());
        //D.USER balance have to be same
        assertEq(STARTING_BALANCE, mockToken.balanceOf(USER));
    }
    function test_Partial_Withdraw_UpdatesAllStatesCorrectly() external {
        //arrange
        vm.startPrank(USER);

        //act
        internalAccountingVault.deposit(FIRST_AMOUNT);
        internalAccountingVault.withdraw(FIRST_AMOUNT / 2);

        vm.stopPrank();

        //assert

        //A.USER share holders
        assertEq(FIRST_AMOUNT / 2, internalAccountingVault.balanceOf(USER));
        //B.VAULT token
        assertEq(
            FIRST_AMOUNT / 2,
            internalAccountingVault.balanceOfVault(
                address(internalAccountingVault)
            )
        );
        //C.VAULT share holders
        assertEq(FIRST_AMOUNT / 2, internalAccountingVault.totalShares());
        //D.USER balance
        assertEq(
            STARTING_BALANCE - (FIRST_AMOUNT / 2),
            mockToken.balanceOf(USER)
        );
    }
}
