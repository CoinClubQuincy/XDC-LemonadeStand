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

    function test_ZeroGlassPurchaseIsRejected() public {
        open(1 ether);
        vm.prank(buyer);
        vm.expectRevert("buy at least one glass");
        stand.GlassOfLemonade{value: 1 ether}(0);
    }

    function test_RefundReachesABuyerThatUsesMoreThan2300Gas() public {
        open(1 ether);
        GasHungryBuyer b = new GasHungryBuyer();
        vm.deal(address(b), 3 ether);
        b.buy(stand, 3 ether, 1);
        assertEq(address(b).balance, 2 ether);
    }

    function test_ABuyerThatRefusesARefundRevertsTheSale() public {
        open(1 ether);
        RefusingBuyer b = new RefusingBuyer();
        vm.deal(address(b), 3 ether);
        vm.expectRevert("refund failed");
        b.buy(stand, 3 ether, 1);
        assertEq(stand.viewAccount(0), 0);
    }

    function test_ABuyerReenteringDuringARefundPaysForEachGlass() public {
        open(1 ether);
        ReentrantBuyer b = new ReentrantBuyer();
        vm.deal(address(b), 5 ether);
        b.buy(stand);
        assertEq(stand.balanceOf(address(stand), stand.totalLemonadeSold()), 2);
        assertEq(address(stand).balance, 2 ether);
        assertEq(address(b).balance, 3 ether);
    }

    function test_TheStandRefusesOtherTokens() public {
        vm.prank(alice);
        vm.expectRevert("the stand does not accept tokens");
        stand.safeTransferFrom(alice, address(stand), 1, 1, "");
    }

    function test_EditorKeysDoNotEarnDividends() public {
        open(1 ether);
        uint editorKey = stand.editorToken();
        vm.prank(alice);
        stand.safeTransferFrom(alice, buyer, editorKey, 1, "");
        vm.startPrank(buyer);
        stand.GlassOfLemonade{value: 1 ether}(1);
        vm.expectRevert("only token holders can access");
        stand.redeem();
        vm.stopPrank();
    }

    function testFuzz_SalesKeepTheStandSolvent(uint40 price, uint8 amount, uint40 extra) public {
        amount = uint8(bound(amount, 1, 50));
        open(price);
        uint cost = uint(price) * amount;
        vm.deal(buyer, cost + extra);
        vm.prank(buyer);
        stand.GlassOfLemonade{value: cost + extra}(amount);
        assertEq(buyer.balance, extra);
        assertEq(address(stand).balance, cost);
        vm.prank(alice);
        stand.redeem();
        vm.prank(bob);
        stand.redeem();
        assertEq(alice.balance + bob.balance + address(stand).balance, cost);
        assertEq(address(stand).balance, stand.remainder());
    }
}

contract GasHungryBuyer {
    uint public refunds;
    function buy(lemonadeStand stand, uint value, uint amount) external {
        stand.GlassOfLemonade{value: value}(amount);
    }
    receive() external payable { refunds++; }
}

contract RefusingBuyer {
    function buy(lemonadeStand stand, uint value, uint amount) external {
        stand.GlassOfLemonade{value: value}(amount);
    }
}

contract ReentrantBuyer {
    lemonadeStand stand;
    bool entered;
    function buy(lemonadeStand _stand) external {
        stand = _stand;
        stand.GlassOfLemonade{value: 2 ether}(1);
    }
    receive() external payable {
        if (!entered) {
            entered = true;
            stand.GlassOfLemonade{value: 1 ether}(1);
        }
    }
}
