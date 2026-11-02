// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../LemonadeStand.sol";

contract LemonadeStandTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address buyer = makeAddr("buyer");
    lemonadeStand stand;

    function setUp() public {
        vm.startPrank(alice);
        stand = new lemonadeStand("Stand", "Fresh", "LMN", 10, "uri");
        stand.safeTransferFrom(alice, bob, 0, 1, "");
        vm.stopPrank();
        vm.deal(buyer, 100 ether);
    }

    function open(uint price) internal {
        vm.prank(alice);
        stand.edit("Fresh", price, true);
    }

    function test_ClosedStandRejectsSales() public {
        vm.prank(buyer);
        vm.expectRevert("the store is currently closed");
        stand.GlassOfLemonade{value: 1 ether}(1);
    }

    function test_OnlyEditorsCanEdit() public {
        vm.prank(buyer);
        vm.expectRevert("only an editor and edit contract");
        stand.edit("x", 1, true);
    }

    function test_UnderpaymentIsRejected() public {
        open(1 ether);
        vm.prank(buyer);
        vm.expectRevert("need more funds");
        stand.GlassOfLemonade{value: 1 ether}(2);
    }

    function test_SaleSplitsAcrossSharesAndCounts() public {
        open(1 ether);
        vm.prank(buyer);
        stand.GlassOfLemonade{value: 2 ether}(2);
        assertEq(stand.viewAccount(0), 0.2 ether);
        assertEq(stand.balanceOf(address(stand), stand.totalLemonadeSold()), 2);
        vm.prank(bob);
        stand.redeem();
        assertEq(bob.balance, 0.2 ether);
    }

    function test_OverpaymentIsRefunded() public {
        open(1 ether);
        vm.prank(buyer);
        stand.GlassOfLemonade{value: 3 ether}(1);
        assertEq(buyer.balance, 99 ether);
        assertEq(address(stand).balance, 1 ether);
    }
}
