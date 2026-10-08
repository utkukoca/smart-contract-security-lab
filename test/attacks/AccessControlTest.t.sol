// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {RescuableVault} from "../../src/access-control/RescuableVault.sol";
import {RescuableVaultFixed} from "../../src/access-control/RescuableVaultFixed.sol";

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../test-contracts/MockToken.sol";

contract AccessControlTest is Test {
    RescuableVault public rescuableVault;
    RescuableVaultFixed public rescuableVaultFixed;
    MockToken public mockToken;
    address public ATTACKER = makeAddr("attacker");
    address public USER = makeAddr("user");
    uint256 public STARTING_BALANCE = 100000;
    uint256 public DECIMALS = 10 ** 18;

    function setUp() external {
        mockToken = new MockToken();
        rescuableVault = new RescuableVault(mockToken);
        rescuableVaultFixed = new RescuableVaultFixed(mockToken);

        fund(USER, address(rescuableVault));
        fund(USER, address(rescuableVaultFixed));
    }

    function testStealToken() external {
        vm.prank(USER);
        mockToken.transfer(address(rescuableVault), 1000 * DECIMALS);
        vm.prank(ATTACKER);
        rescuableVault.rescueTokens(ATTACKER);
        assertEq(1000 * DECIMALS, mockToken.balanceOf(ATTACKER));
    }
    function testStealTokenFixed() external {
        vm.prank(USER);
        mockToken.transfer(address(rescuableVaultFixed), 1000 * DECIMALS);
        vm.prank(ATTACKER);
        vm.expectRevert(
            RescuableVaultFixed.RescuableVaultFixed__NotOwner.selector
        );
        rescuableVaultFixed.rescueTokens(ATTACKER);
    }
    function testOwner() external {
        vm.prank(USER);
        mockToken.transfer(address(rescuableVaultFixed), 1000 * DECIMALS);
        vm.prank(address(this));
        address RECEIVER = makeAddr("receiver");
        rescuableVaultFixed.rescueTokens(RECEIVER);
        assertEq(1000 * DECIMALS, mockToken.balanceOf(RECEIVER));
    }
    function testStealTokenIsAffectOtherFunction() external {
        vm.startPrank(USER);
        rescuableVault.deposit(1000 * DECIMALS);
        mockToken.transfer(address(rescuableVault), 1000 * DECIMALS);
        vm.stopPrank();
        vm.prank(ATTACKER);
        rescuableVault.rescueTokens(ATTACKER);
        vm.startPrank(USER);
        uint256 shareAmount = rescuableVault.balanceOf(USER);
        console.log(shareAmount);
        uint256 firstBalance = mockToken.balanceOf(USER);
        rescuableVault.withdraw(shareAmount);
        uint256 finalBalance = mockToken.balanceOf(USER);
        assertEq(0, rescuableVault.balanceOf(USER));
        assertEq(finalBalance - firstBalance, 1000 * DECIMALS);
    }

    function fund(address _address, address _contract) internal {
        mockToken.mint(_address, STARTING_BALANCE * DECIMALS); //mint mock money for _address
        vm.startPrank(_address);
        mockToken.approve(_contract, type(uint256).max); //we have to use approve in this section if we use in BaseVault we approve to user can use token which in BaseVault
        vm.stopPrank();
    }
}
