// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseVault} from "../../src/BaseVault.sol";
import {MockToken} from "../test-contracts/MockToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract BaseVaultTest is Test {
    BaseVault public baseVault;
    MockToken public mockToken;
    address public USER = makeAddr("user"); //test address
    uint256 public constant FIRST_AMOUNT = 100;

    function setUp() external {
        mockToken = new MockToken();
        baseVault = new BaseVault(mockToken);
        mockToken.mint(USER, 1000 * 10 ** 18); //mint mock money for USER
    }

    function testEqTokenAddress() external view {
        assertEq(address(mockToken), address(baseVault.asset()));
    }
    function testVaultBegining() external view {
        assertEq(baseVault.totalShares(), 0);
    }
    function test_FirstDepositorGetsSharesEqualToAmount() external {
        vm.startPrank(USER);
        mockToken.approve(address(baseVault), type(uint256).max); //we have to use approve in this section if we use in BaseVault we approve to user can use token which in BaseVault
        baseVault.deposit(FIRST_AMOUNT);
        assertEq(FIRST_AMOUNT, baseVault.balanceOf(USER));
        vm.stopPrank();
    }
    function test_VaultBalanceIncreasesAfterDeposit() external {
        vm.startPrank(USER);
        mockToken.approve(address(baseVault), type(uint256).max); //we have to use approve in this section if we use in BaseVault we approve to user can use token which in BaseVault
        baseVault.deposit(FIRST_AMOUNT);
        assertEq(FIRST_AMOUNT, mockToken.balanceOf(address(baseVault)));
        vm.stopPrank();
    }
}
