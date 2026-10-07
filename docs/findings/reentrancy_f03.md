# [F-03] Reentrancy in VulnerableBank.withdraw()

| | |
|---|---|
| **Severity** | Critical |
| **Target** | `VulnerableBank.withdraw()` |
| **Category** | Reentrancy / Wrong order of operations |
| **Status** | Reproduced · Fix planned |

## Summary

`withdraw()` sends ETH to the user **before** it sets the user's balance to 0.
If the user is a contract, its `receive()` function runs during the transfer
and can call `withdraw()` again. The balance is still not 0, so the bank pays
again. The attacker repeats this until the bank is empty.

## Description

```solidity
function withdraw() public {
    uint256 balanceUser = balanceOfUser[msg.sender];          // 1. read balance
    if (balanceUser == 0) revert VulnerableBank__UserBalanceIsZero();
    (bool success, ) = msg.sender.call{value: balanceUser}(""); // 2. send ETH
    if (!success) revert VulnerableBank__MoneyNotSend();
    balanceOfUser[msg.sender] = 0;                             // 3. update balance
}
```

- `call` gives control to the receiver. When ETH is sent with empty data
  (`""`), the receiver contract's `receive()` runs automatically.
- Inside `receive()`, the attacker can call `withdraw()` again. At this point
  step 3 has not run yet, so `balanceOfUser[attacker]` still shows the old
  balance and the check passes.
- The function breaks the **Checks → Effects → Interactions (CEI)** rule: the
  state update (effect) comes after the external call (interaction).

**Note on `-=`:** if step 3 was `balanceOfUser[msg.sender] -= balanceUser`,
Solidity 0.8's underflow check would revert while the nested calls return
(`0 - 1`), and this simple version of the attack would fail. That is luck, not
a defense: the same code with `= 0` or inside `unchecked` is still exploitable.

## Attack scenario

Two users deposit 5 ETH each (bank: 10 ETH). The attacker uses 1 ETH.

| Step | What happens | Bank ETH | Attacker's recorded balance |
|---|---|---|---|
| 0 | Attacker contract deposits 1 ETH | 11 | 1 |
| 1 | `withdraw()` → bank sends 1 ETH → attacker's `receive()` runs | 10 | 1 (not updated yet) |
| 2 | `receive()` calls `withdraw()` again → bank sends 1 ETH | 9 | 1 |
| … | same loop | … | 1 |
| 11 | 11th transfer | 0 | 1 |
| 12 | Bank is empty, `receive()` stops. Nested calls return, each sets the balance to 0 | 0 | 0 |

The attacker's `receive()` must stop when the bank has less than 1 ETH. One
more `withdraw()` would fail, the `!success` check would revert, and the revert
would undo the whole attack.

## Impact

All ETH in the bank can be stolen. In the PoC the attacker deposits 1 ETH and
takes 11 ETH: their own 1 ETH plus 10 ETH of other users.

## Proof of Concept

- File: `test/attacks/Reentrancy.t.sol`
- Attacker contract: `Attacker` (re-enters from `receive()`)
- Test: `test_Attacker`
- Key checks: bank balance is 0, attacker contract balance is 11 ETH

```bash
forge test --match-path test/attacks/Reentrancy.t.sol -vvvv
```

The `-vvvv` trace shows the nested `withdraw()` calls like a staircase.

## Recommendation

To be implemented and tested in the next step:

- **CEI:** set the balance to 0 **before** sending ETH. A re-entered call then
  sees a balance of 0 and reverts.
- **Reentrancy guard:** OpenZeppelin `ReentrancyGuard` and its `nonReentrant`
  modifier block a second entry while the first call is still running.
- Use both together (defense in depth).

## References

- **The DAO** — June 2016, about 3.6M ETH. The classic reentrancy hack; it led
  to the Ethereum / Ethereum Classic split.
  [Explanation (Chainlink)](https://blog.chain.link/reentrancy-attacks-and-the-dao-hack)
- **Curve / Vyper** — July 2023, about $70M across several pools. A compiler
  bug broke the built-in reentrancy lock, so contracts that looked protected
  were not. Lesson: test your guard, do not just trust it.
  [Post-mortem (Vyper)](https://hackmd.io/@vyperlang/HJUgNMhs2)
- **Solidity docs** — security considerations, reentrancy.
  [docs.soliditylang.org](https://docs.soliditylang.org/en/latest/security-considerations.html#reentrancy)
- **OpenZeppelin ReentrancyGuard**
  [docs.openzeppelin.com](https://docs.openzeppelin.com/contracts/5.x/api/utils#ReentrancyGuard)