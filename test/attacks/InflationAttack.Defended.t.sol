// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {VaultTestBase} from "../helpers/VaultTestBase.sol";
import {DeadShareVault} from "../../src/DeadShareVault.sol";
import {InternalAccountingVault} from "../../src/InternalAccountingVault.sol";

// attack:   Inflation / donation (first depositor)
// aeverity: Critical
// aarget:   BaseVault.deposit()
// Summary:  Attacker seeds the vault with 1 wei (very low amount), donates directly to inflate
//           the share price, and the next depositor receives 0 shares. When depositer try to buy
//          shares this amount will increase vault asset and asset price of attacker's shares increase

contract InflationAttack is VaultTestBase {
    uint256 constant ATTACKER_SHARE_AMOUNT = 1;

    function test_attack_FirstDepositorStealsVictimDeposit_DeadShareVault()
        external
    {
        vm.startPrank(ATTACKER);
        deadShareVault.deposit(ATTACKER_SHARE_AMOUNT);
        mockToken.transfer(address(deadShareVault), 900 * DECIMALS);
        vm.stopPrank();

        vm.prank(USER);
        deadShareVault.deposit(FIRST_AMOUNT);

        // assert
        // TOKEN_AMOUNT = VAULT_ASSETS X DEPOSITOR_SHARES
        // solution is 0.111... but solidity always rounds down so USER get 0 shares but ASSET AMOUNT increased now ATTACKER 1 shares equalt to aprx. 1000

        /*
        assertEq(0, baseVault.balanceOf(USER));
        assertEq(
            900 * DECIMALS + FIRST_AMOUNT + 1,
            mockToken.balanceOf(address(baseVault))
        );
        */

        vm.prank(ATTACKER);
        deadShareVault.withdraw(ATTACKER_SHARE_AMOUNT);

        assertGt(
            STARTING_BALANCE + FIRST_AMOUNT,
            mockToken.balanceOf(ATTACKER)
        );
    }

    function test_attack_FirstDepositorStealsVictimDeposit_InternalAccountingVault()
        external
    {
        vm.startPrank(ATTACKER);
        internalAccountingVault.deposit(ATTACKER_SHARE_AMOUNT);
        mockToken.transfer(address(internalAccountingVault), 900 * DECIMALS);
        vm.stopPrank();

        vm.prank(USER);
        internalAccountingVault.deposit(FIRST_AMOUNT);

        // assert
        // TOKEN_AMOUNT = VAULT_ASSETS X DEPOSITOR_SHARES
        // solution is 0.111... but solidity always rounds down so USER get 0 shares but ASSET AMOUNT increased now ATTACKER 1 shares equalt to aprx. 1000

        /*
        assertEq(0, baseVault.balanceOf(USER));
        assertEq(
            900 * DECIMALS + FIRST_AMOUNT + 1,
            mockToken.balanceOf(address(baseVault))
        );
        */

        vm.prank(ATTACKER);
        internalAccountingVault.withdraw(ATTACKER_SHARE_AMOUNT);

        assertGt(
            STARTING_BALANCE + FIRST_AMOUNT,
            mockToken.balanceOf(ATTACKER)
        );
    }
}
