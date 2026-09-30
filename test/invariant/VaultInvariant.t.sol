pragma solidity ^0.8.20;

import {MockToken} from "../test-contracts/MockToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {InternalAccountingVault} from "../../src/InternalAccountingVault.sol";
import {VaultHandler} from "./Handler.sol";

contract VaultInvariantTest is Test {
    MockToken mockToken;
    InternalAccountingVault internalAccountingVault;
    VaultHandler vaultHandler;
    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");
    address public USER3 = makeAddr("user3");
    uint256 public FIRST_AMOUNT = 1000000;
    uint256 public DECIMALS = 10 ** 18;

    function setUp() public {
        mockToken = new MockToken();
        internalAccountingVault = new InternalAccountingVault(mockToken);
        address[] memory savers = new address[](3);
        savers[0] = USER;
        savers[1] = USER2;
        savers[2] = USER3;
        for (uint256 i = 0; i < savers.length; i++) {
            mockToken.mint(savers[i], FIRST_AMOUNT * DECIMALS);
            vm.prank(savers[i]);
            mockToken.approve(
                address(internalAccountingVault),
                type(uint256).max
            );
        }
        vaultHandler = new VaultHandler(
            mockToken,
            savers,
            internalAccountingVault
        );
        targetContract(address(vaultHandler));
    }
    function invariant_totalSharesEqualsSumOfBalances() external {
        address[] memory actors = vaultHandler.getActors();
        uint256 totalBalance;
        for (uint256 i = 0; i < actors.length; i++) {
            totalBalance += internalAccountingVault.balanceOf(actors[i]);
        }
        assertEq(totalBalance, internalAccountingVault.totalShares());
    }
}
