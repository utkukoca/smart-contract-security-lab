# [F-02] Withdraw Always Reverts in InternalAccountingVault

| | |
|---|---|
| **Severity** | High |
| **Target** | `InternalAccountingVault.withdraw()` |
| **Category** | Accounting / Wrong state variable |
| **Status** | Found by invariant test · Fixed |

## Summary

`withdraw()` updates the wrong mapping. It subtracts the withdrawn tokens from
`balanceOf[address(this)]` (the share balance of the vault address) instead of
`balanceOfVault[address(this)]` (the vault's internal asset record). The share
balance of the vault is always 0, so the subtraction underflows and the
withdraw reverts. Users can deposit, but they can never take their money back.

## Description

The buggy line:

```solidity
balanceOf[address(this)] = balanceOf[address(this)] - tokenWithdrawAmount;
```

- `balanceOf` is the **shares** mapping. Nothing writes to
  `balanceOf[address(this)]`, so its value is always 0.
- In Solidity 0.8, `0 - x` (for any `x > 0`) reverts with
  `panic: arithmetic underflow or overflow (0x11)`.
- The compiler cannot catch this. `balanceOf` and `balanceOfVault` are both
  `mapping(address => uint256)`, so both versions are valid code.
- Reading a mapping key that was never written returns 0 with no error, so the
  bug stays silent until the subtraction.

## Reproduction

A user deposits 3 tokens, then withdraws all 3 shares:

| Step | Line | Calculation | Result |
|---|---|---|---|
| 1 | `tokenWithdrawAmount = shares * balanceOfVault / totalShares` | 3 × 3 / 3 | 3 |
| 2 | `balanceOf[msg.sender] -= shares` | 3 − 3 | 0 ✓ |
| 3 | `totalShares -= shares` | 3 − 3 | 0 ✓ |
| 4 | `balanceOf[address(this)] - tokenWithdrawAmount` | **0 − 3** | **panic 0x11** |
| 5 | `asset.transfer(...)` | — | never reached |

A partial withdraw fails the same way (withdraw 1 share: `0 − 1`). Any
withdraw that pays out more than 0 tokens reverts.

## Impact

All deposited funds are locked in the vault. No funds can be stolen, but no
user can ever withdraw.

## How it was found

1. I wrote an invariant test (`invariant_totalSharesEqualsSumOfBalances`) with
   a handler. The handler calls `deposit` and `withdraw` with random actors and
   bounded amounts. After every call, Foundry checks that the sum of user
   shares equals `totalShares`.
2. The first run passed, but the call table showed that 26,503 of 128,000
   calls reverted. By default Foundry ignores reverts, so the test was green
   while many calls did nothing.
3. I set `fail_on_revert = true`. The first failure was a bug in my handler
   (`bound()` with max < min when an actor has 0 tokens). I fixed the handler.
4. The next run failed inside the vault. Foundry shrank the failing sequence
   to 2 calls: `deposit(3)` then `withdraw(3)`. The trace showed the panic
   inside `withdraw()` with no `transfer` call under it, so the problem was in
   the math before the transfer.
5. Walking through `withdraw()` line by line with these numbers showed the
   wrong mapping.

**Why other tests missed it:** the unit tests only covered `BaseVault`, and
the attack tests for `InternalAccountingVault` checked deposits and share
price, never a normal withdraw.

## Fix

```diff
- balanceOf[address(this)] = balanceOf[address(this)] - tokenWithdrawAmount;
+ balanceOfVault[address(this)] = balanceOfVault[address(this)] - tokenWithdrawAmount;
```

After the fix, the invariant test runs 256 runs / 128,000 calls with 0
reverts.

Regression tests: `test/unit/InternalAccountingVault.t.sol`
(`test_Withdraw_UpdatesAllStatesCorrectly`,
`test_Partial_Withdraw_UpdatesAllStatesCorrectly`).

## Lessons

- A green invariant test with many reverts can hide bugs. Always check the
  revert count, or use `fail_on_revert = true`.
- Attack tests are not enough. Normal user flows (deposit → withdraw) need
  their own tests.
- `balanceOfVault` is a mapping that is only used with one key
  (`address(this)`). A single `uint256` state variable would be clearer and
  would make this kind of mistake much harder.