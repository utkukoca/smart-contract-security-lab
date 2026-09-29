pragma solidity ^0.8.20;

import {MockToken} from "../test-contracts/MockToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {InternalAccountingVault} from "../../src/InternalAccountingVault.sol";

contract VaultHandler is Test {
    InternalAccountingVault internalAccountingVault;
    MockToken token;
    address[] actors; // önceden hazırlanmış kullanıcılar

    constructor(
        MockToken _token,
        address[] memory _actors,
        InternalAccountingVault _internalAccountingVault
    ) {
        token = _token;
        actors = _actors;
        internalAccountingVault = _internalAccountingVault;
    }

    function deposit(uint256 amount, uint256 actorSeed) external {
        address actor = actors[actorSeed % actors.length];
        amount = bound(amount, 1, token.balanceOf(actor));
        vm.prank(actor);
        internalAccountingVault.deposit(amount);
    }

    function withdraw(uint256 shares, uint256 actorSeed) external {
        address actor = actors[actorSeed % actors.length];
        if (internalAccountingVault.balanceOf(actor) == 0) return;
        shares = bound(shares, 1, internalAccountingVault.balanceOf(actor));
        vm.prank(actor);
        internalAccountingVault.withdraw(shares);
    }

    function getActors() public view returns (address[] memory) {
        return actors;
    }
}
