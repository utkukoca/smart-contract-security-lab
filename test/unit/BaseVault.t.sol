// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseVault} from "../../src/BaseVault.sol";
import {MockToken} from "../test-contracts/MockToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract BaseVaultTest is Test {
    BaseVault public baseVault;
    MockToken public mockToken;

    function setUp() external {
        mockToken = new MockToken();
        baseVault = new BaseVault(mockToken);
    }

    function testEqTokenAddress() external view {
        assertEq(address(mockToken), address(baseVault.asset()));
    }
    function testVaultBegining() external view {
        assertEq(baseVault.totalShares(), 0);
    }
}
