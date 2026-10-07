# [F-01] Inflation / Donation Attack on First Depositor

| | |
|---|---|
| **Severity** | Critical |
| **Target** | `BaseVault.deposit()` |
| **Category** | Rounding / Share price manipulation |
| **Status** | Reproduced · Mitigated |

## Summary

When the vault is empty, the first depositor gets shares 1:1 with the tokens
they deposit. The attacker deposits 1 wei and gets 1 share. Then the attacker
sends tokens directly to the vault. This breaks the share price. The next user
deposits real money but gets 0 shares, and the attacker takes that money with
their single share.

## Description

Shares are calculated like this:

```solidity
shares = amount * totalShares / totalAssets;
```

Three things together make the attack possible:

- **The denominator can be manipulated.** `totalAssets` reads the real token
  balance with `asset.balanceOf(address(this))`. Anyone can increase it by
  sending tokens directly to the vault, without getting any shares.
- **Solidity rounds down.** If the result of the division is less than 1, the
  user gets 0 shares.
- **The first deposit is special.** When `totalShares == 0`, the depositor gets
  shares 1:1, so the attacker can start with only 1 share.

When the numerator is small and the denominator is very big, the result
rounds down to 0. The attack works when the donation is bigger than the
victim's deposit.

## Attack scenario

1. The attacker deposits 1 wei and gets 1 share.
2. The attacker sends 900 tokens directly to the vault. No shares are minted.
3. The victim deposits 100 tokens:
   `100e18 * 1 / (900e18 + 1) = 0` → the victim gets 0 shares.
4. The attacker owns the only share, so they withdraw the whole vault,
   including the victim's 100 tokens.

## Impact

The victim loses their whole deposit and it goes to the attacker. In the PoC
the victim deposits 100e18 tokens and gets 0 shares. The attacker's net
profit is the victim's deposit (`FIRST_AMOUNT`).

## Proof of Concept

- File: `test/attacks/InflationAttack.t.sol`
- Test: `test_attack_FirstDepositorStealsVictimDeposit`
- Key check: `assertEq(0, baseVault.balanceOf(USER))`

```bash
forge test --match-path test/attacks/InflationAttack.t.sol -vv
```

## Mitigations

Two defended vaults were written and tested against the same attack
(`test/attacks/InflationAttack.Defended.t.sol`).

- **Dead shares (`DeadShareVault`):** At deployment, the vault mints some
  shares to a dead address and holds the matching tokens. The vault is never
  empty, so the attacker cannot start with 1 share. The attack is still
  possible, but it is not profitable: the attacker needs a huge amount of
  money (in the PoC, 1 billion tokens) to cause any damage.
  Tests: `test_attack_FirstDepositorStealsVictimDeposit_DeadShareVault`,
  `test_DeadShares_BreaksUnderMassiveDonation`.

- **Internal accounting (`InternalAccountingVault`):** The vault does not read
  its real token balance. It keeps its own record of deposited assets. Tokens
  sent directly to the vault do not change this record, so they cannot change
  the denominator. Trade-off: donated tokens stay stuck in the vault, nobody
  can withdraw them.
  Tests: `test_attack_FirstDepositorStealsVictimDeposit_InternalAccountingVault`,
  `test_InternalAccounting_ResistsMassiveDonation`.
  Note: the first version of this vault had a withdraw bug, see
  [F-02](F-02-withdraw-underflow.md).

## References

Real exploits where a donation changed an ERC-4626 share price:

- **Resupply / cvcrvUSD** — June 2025, ~$9.6M. The closest case to this
  finding: 1 wei deposit into an empty vault, then a large donation, then a
  rate that rounds down to zero.
  [Analysis (Ackee Blockchain)](https://ackee.xyz/blog/resupply-hack-analysis/)
- **Venus / wUSDM (zkSync)** — February 2025, ~$717k net bad debt. A donation
  inflated the wUSDM exchange rate used as collateral price.
  [Post-mortem (Venus)](https://community.venus.io/t/post-mortem-wusdm-donation-attack-on-venus-zksync/5004)
- **sDOLA / LlamaLend** — March 2026, ~$240k. A donation moved the sDOLA share
  price used by the lending market, and borrowers were liquidated.
  [Post-mortem (Curve governance)](https://gov.curve.finance/t/llamalend-sdola-long2-post-mortem/11020)
- **OpenZeppelin ERC-4626 docs** — virtual shares / decimals offset defense.
  [docs.openzeppelin.com](https://docs.openzeppelin.com/contracts/5.x/erc4626)