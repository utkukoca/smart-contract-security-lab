# [F-04] Missing Access Control in RescuableVault.rescueTokens()

| | |
|---|---|
| **Severity** | High |
| **Target** | `RescuableVault.rescueTokens()` |
| **Category** | Access control / Unprotected privileged function |
| **Status** | Reproduced · Fixed |

## Summary

`rescueTokens()` is an admin function. It sends the extra tokens in the vault
(tokens that were sent directly, not deposited) to any address. The contract
saves an `OWNER`, but the function never checks it. So anyone can call
`rescueTokens()` and send the extra tokens to themselves.

## Description

```solidity
address public immutable OWNER;

constructor(IERC20 _asset) InternalAccountingVault(_asset) {
    OWNER = msg.sender;                                    // saved, never used
}

function rescueTokens(address to) public {                 // no owner check
    uint256 rescueTokenAmount = asset.balanceOf(address(this)) -
        balanceOfVault[address(this)];
    asset.transfer(to, rescueTokenAmount);
}
```

- `RescuableVault` inherits `InternalAccountingVault`. That vault keeps its own
  asset record (`balanceOfVault`) and ignores tokens that are sent directly
  with `transfer`. This is the defense against F-01.
- Because of this, directly sent tokens are stuck: no share belongs to them.
  `rescueTokens()` exists so the owner can take them out.
- The amount is `real balance − internal record`. This is only the extra part.
- The function is `public` and has no `msg.sender` check. `OWNER` is written
  in the constructor but nothing reads it.
- The compiler cannot catch this. A function without an access check is valid
  code. Only a test that calls it from a wrong address shows the problem.

## Attack scenario

A user deposits 1,000 tokens, then sends 1,000 more tokens directly to the
vault by mistake.

| Step | What happens | Real balance | Internal record | Extra |
|---|---|---|---|---|
| 0 | User deposits 1,000 | 1,000 | 1,000 | 0 |
| 1 | User sends 1,000 directly with `transfer` | 2,000 | 1,000 | 1,000 |
| 2 | Attacker calls `rescueTokens(attacker)` | 1,000 | 1,000 | 0 |
| 3 | User withdraws all shares and gets 1,000 back | 0 | 0 | 0 |

The attacker pays only gas. The attacker can also watch the mempool and call
`rescueTokens()` before the owner does (front-running).

## Impact

Every token that is sent directly to the vault can be stolen by anyone. The
rescue function gives the tokens to the attacker instead of the owner.

Deposited funds are not affected. The function only moves the extra part, so
users can still withdraw their full deposit after the attack
(`testStealTokenIsAffectOtherFunction`). This is why the severity is High and
not Critical.

## Proof of Concept

- File: `test/attacks/AccessControlTest.t.sol`
- Tests:
  - `testStealToken` — attacker calls `rescueTokens` and gets 1,000 tokens
  - `testStealTokenIsAffectOtherFunction` — after the attack the user can
    still withdraw all shares
  - `testStealTokenFixed` — the same call reverts on `RescuableVaultFixed`

```bash
forge test --match-path test/attacks/AccessControlTest.t.sol -vv
```

## Fix

`RescuableVaultFixed` checks the caller before anything else:

```diff
+ error RescuableVaultFixed__NotOwner();

  function rescueTokens(address to) public {
+     if (msg.sender != OWNER) revert RescuableVaultFixed__NotOwner();
      uint256 rescueTokenAmount = asset.balanceOf(address(this)) -
          balanceOfVault[address(this)];
      asset.transfer(to, rescueTokenAmount);
  }
```

Other options:

- **OpenZeppelin `Ownable`:** the `onlyOwner` modifier does the same check and
  also lets the owner transfer ownership. Here `OWNER` is `immutable`, so the
  owner can never change.
- **`Ownable2Step`:** the new owner must accept, so ownership cannot go to a
  wrong address by mistake.
- **`AccessControl`:** roles, when more than one admin or more than one
  permission level is needed.

## Lessons

- Saving an owner is not access control. The check must be in every
  privileged function.
- Every `public` / `external` function that moves funds needs the question:
  who is allowed to call this?
- Write a test that calls each admin function from a random address and
  expects a revert.

## References

- **Parity multisig wallet** — July 2017, about 150,000 ETH. The `initWallet`
  function had no access check, so the attacker called it and became the
  owner of other people's wallets.
  [Explanation (OpenZeppelin)](https://blog.openzeppelin.com/on-the-parity-wallet-multisig-hack-405a8c12e8f7)
- **SWC-105** — Unprotected Ether Withdrawal.
  [swcregistry.io](https://swcregistry.io/docs/SWC-105)
- **OpenZeppelin access control** — `Ownable`, `Ownable2Step`, `AccessControl`.
  [docs.openzeppelin.com](https://docs.openzeppelin.com/contracts/5.x/access-control)
