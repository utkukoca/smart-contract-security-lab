# [F-05] Denial of Service in VulnerableAuction.bid()

| | |
|---|---|
| **Severity** | High |
| **Target** | `VulnerableAuction.bid()` |
| **Category** | Denial of Service / Failed external call (push payment) |
| **Status** | Reproduced · Fixed |

## Summary

When a new bid is higher, `bid()` sends the old bid back to the old bidder in
the same transaction. If this refund fails, the whole `bid()` reverts. An
attacker bids from a contract that cannot receive ETH. After that, every
higher bid reverts, because the refund to the attacker always fails. Nobody
can outbid the attacker and the auction is blocked forever.

## Description

```solidity
if (msg.value > lastBid) {
    address oldGetter = lastGetter;
    uint256 oldBid = lastBid;
    lastGetter = msg.sender;                               // 1. update state
    lastBid = msg.value;
    (bool success, ) = oldGetter.call{value: oldBid}("");  // 2. refund old bidder
    if (!success) revert VulnerableAuction__PaymentUnsuccesfull(); // 3. revert if refund fails
}
```

- The refund is a **push payment**: the auction sends the ETH itself, inside
  the new bidder's transaction.
- A `call` with ETH to a contract that has no `receive()` and no payable
  `fallback()` fails and returns `success = false`.
- Step 3 turns this into a revert. So the old bidder decides if the new bid
  can succeed. The new bidder did nothing wrong, but their transaction fails.
- The attacker's contract (`AttackAuction`) has no `receive()`. That is the
  whole attack: the missing function is the weapon.

**Note on CEI:** the function follows Checks → Effects → Interactions (state
is updated before the `call`). CEI stops reentrancy (F-03), but it does not
help here. The problem is not the order. The problem is that the function
depends on a call to an address that the attacker controls.

## Attack scenario

| Step | What happens | Highest bidder | Highest bid | Auction ETH |
|---|---|---|---|---|
| 0 | User bids 1 ETH | User | 1 | 1 |
| 1 | Attacker contract bids 2 ETH. User gets 1 ETH back | Attacker contract | 2 | 2 |
| 2 | User bids 3 ETH → auction sends 2 ETH to attacker contract → no `receive()` → fails → revert | Attacker contract | 2 | 2 |
| … | Every higher bid fails the same way | Attacker contract | 2 | 2 |

The revert undoes step 2 completely, so the user keeps their 3 ETH. But the
attacker contract stays the highest bidder with only 2 ETH.

## Impact

- The auction stops working. No one can place a higher bid after the
  attacker.
- The attacker wins with a low price. They only need to bid a little more
  than the current bid, one time.
- No user funds are stolen. The cost for the attacker is their own bid, which
  stays in the auction.

## Proof of Concept

- File: `test/attacks/DosAttack.t.sol`
- Attacker contract: `AttackAuction` (no `receive()`, no `fallback()`)
- Tests:
  - `testAuction` — normal flow: a higher bid refunds the old bidder
  - `testDosAttack` — after the attacker's bid, a 3 ETH bid reverts with
    `VulnerableAuction__PaymentUnsuccesfull`; highest bidder, highest bid and
    auction balance do not change
  - `testDosAttackFixed` — the same attack on `VulnerableAuctionFixed`: the
    3 ETH bid succeeds, the user withdraws their refund, and only the
    attacker's own `withdraw()` reverts

```bash
forge test --match-path test/attacks/DosAttack.t.sol -vvvv
```

The `-vvvv` trace shows the failed `call` to `AttackAuction` inside `bid()`.

## Fix

`VulnerableAuctionFixed` uses **pull over push** (the withdrawal pattern).
`bid()` does not send ETH anymore. It only records the refund, and each
bidder takes their own money with `withdraw()`.

```diff
+ mapping(address => uint256) public pendingRefunds;

  if (msg.value > lastBid) {
-     address oldGetter = lastGetter;
-     uint256 oldBid = lastBid;
+     pendingRefunds[lastGetter] += lastBid;
      lastGetter = msg.sender;
      lastBid = msg.value;
-     (bool success, ) = oldGetter.call{value: oldBid}("");
-     if (!success) revert VulnerableAuction__PaymentUnsuccesfull();
  }
```

```solidity
function withdraw() public {
    uint256 amount = pendingRefunds[msg.sender];
    if (amount == 0) revert VulnerableAuctionFixed__NotTrueDebtAddress();
    pendingRefunds[msg.sender] = 0;                          // effect first
    (bool success, ) = msg.sender.call{value: amount}("");   // then send
    if (!success) revert VulnerableAuctionFixed__PaymentUnsuccesfull();
}
```

- `bid()` has no external call, so no other address can make it fail.
- If the attacker's contract cannot receive ETH, only the attacker's own
  `withdraw()` reverts. Other users are not affected.
- `withdraw()` sets the refund to 0 **before** it sends ETH (CEI), so it is
  not open to reentrancy (see F-03).

After the fix, with the same attack: the user bids 1 ETH, the attacker
contract bids 2 ETH, then a second user bids 3 ETH and it succeeds. The
auction holds 6 ETH (1 + 2 + 3) until the old bidders withdraw.

## Lessons

- Never let one user's failed payment block other users.
- An external call can fail on purpose. The receiver controls it.
- CEI protects against reentrancy, not against DoS. These are different
  problems with different fixes.

## References

- **King of the Ether Throne** — February 2016. Payments to the old "king"
  could fail when the receiver was a contract, and the game got stuck. The
  best-known example of this bug class.
  [Post-mortem](https://www.kingoftheether.com/postmortem.html)
- **SWC-113** — DoS with Failed Call.
  [swcregistry.io](https://swcregistry.io/docs/SWC-113)
- **Solidity docs** — withdrawal pattern.
  [docs.soliditylang.org](https://docs.soliditylang.org/en/latest/common-patterns.html#withdrawal-from-contracts)
