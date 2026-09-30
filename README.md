# smart-contract-security-lab

A hands-on smart contract security lab. I write contracts from scratch,
break them with attack PoCs, fix them, and test them with unit, attack and
invariant tests. Every finding has a written report.

The first module covers ERC-4626-style vaults.

> ⚠️ Educational code. Not for production use.

## Findings

| ID | Title | Target | Severity | Found by | Status |
|---|---|---|---|---|---|
| [F-01](docs/findings/F-01-inflation-attack.md) | Inflation / donation attack on first depositor | `BaseVault` | Critical | Attack PoC | Mitigated (2 defenses) |
| [F-02](docs/findings/F-02-withdraw-underflow.md) | Withdraw always reverts (wrong mapping → underflow) | `InternalAccountingVault` | High | Invariant test | Fixed |

## Vaults

| Contract | Idea | Status |
|---|---|---|
| `BaseVault` | Simple vault. Share price reads the real token balance. | Vulnerable to F-01 (on purpose) |
| `DeadShareVault` | Mints dead shares at deployment, so the vault is never empty. | F-01 becomes very expensive, not impossible |
| `InternalAccountingVault` | Keeps its own asset record and ignores donations. | Resists F-01 · F-02 fixed |

## Testing approach

- **Unit tests** (`test/unit/`) — normal user flows: deposit, withdraw, edge
  cases and reverts.
- **Attack PoCs** (`test/attacks/`) — each attack is a test. The same attack
  also runs against the defended vaults to show the defense works.
- **Invariant tests** (`test/invariant/`) — a handler calls `deposit` and
  `withdraw` with random actors and amounts. After every call, Foundry checks
  that the sum of user shares equals `totalShares`. It runs with
  `fail_on_revert = true`, so hidden reverts fail the test. This is how F-02
  was found.

## Structure

```
src/
  BaseVault.sol
  DeadShareVault.sol
  InternalAccountingVault.sol
test/
  unit/            BaseVault.t.sol, InternalAccountingVault.t.sol
  attacks/         InflationAttack.t.sol, InflationAttack.Defended.t.sol
  invariant/       VaultInvariant.t.sol, Handler.sol
  helpers/         VaultTestBase.sol
  test-contracts/  MockToken.sol
docs/
  findings/        F-01-inflation-attack.md, F-02-withdraw-underflow.md
```

## Run

Requires [Foundry](https://book.getfoundry.sh/).

```bash
git clone --recurse-submodules <repo-url>
cd smart-contract-security-lab
forge build
forge test
```

Run one group:

```bash
forge test --match-path "test/unit/*" -vv
forge test --match-path "test/attacks/*" -vv
forge test --match-path test/invariant/VaultInvariant.t.sol -vv
```
