// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseVault} from "../../src/BaseVault.sol";
import {MockToken} from "../test-contracts/MockToken.sol";
import {Test, console} from "forge-std/Test.sol";

abstract contract VaultTestBase is Test {
    BaseVault public baseVault;
    MockToken public mockToken;

    address public USER = makeAddr("user"); //test address
    address public USER2 = makeAddr("user2"); //test address
    address public ATTACKER = makeAddr("attacker");

    uint256 public constant DECIMALS = 10 ** 18;
    uint256 public constant FIRST_AMOUNT = 100 * DECIMALS;
    uint256 public constant STARTING_BALANCE = 1000000000 * DECIMALS;

    function setUp() external {
        mockToken = new MockToken();
        baseVault = new BaseVault(mockToken);

        _fund(USER);
        _fund(USER2);
        _fund(ATTACKER);
    }

    function _fund(address _address) internal {
        mockToken.mint(_address, STARTING_BALANCE); //mint mock money for _address
        vm.prank(_address);
        mockToken.approve(address(baseVault), type(uint256).max); //we have to use approve in this section if we use in BaseVault we approve to user can use token which in BaseVault
    }
}
