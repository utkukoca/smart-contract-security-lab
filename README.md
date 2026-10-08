# smart-contract-security-lab

A hands-on smart contract security lab. I write contracts from scratch,
break them with attack PoCs, fix them, and test them with unit, attack and
invariant tests. Every finding has a written report.

Modules: **ERC-4626 vaults** · **Reentrancy** · **Access control** · **Denial of Service**

> ⚠️ Educational code. Not for production use.

## Findings

| ID | Title | Target | Severity | Found by | Status |
|---|---|---|---|---|---|
| [F-01](docs/findings/inflation_f01.md) | Inflation / donation attack on first depositor | `BaseVault` | Critical | Attack PoC | Mitigated (2 defenses) |
| [F-02](docs/findings/inflation_f02.md) | Withdraw always reverts (wrong mapping → underflow) | `InternalAccountingVault` | High | Invariant test | Fixed |
| [F-03](docs/findings/reentrancy_f03.md) | Reentrancy: ETH sent before balance update | `VulnerableBank` | Critical | Attack PoC | Reproduced · Fix planned |
| [F-04](docs/findings/access_control_f04.md) | Missing access control: anyone can call `rescueTokens` | `RescuableVault` | High | Attack PoC | Fixed |
| [F-05](docs/findings/dos_f05.md) | DoS: a bidder that cannot receive ETH blocks all higher bids | `VulnerableAuction` | High | Attack PoC | Reproduced · Fix planned |

## Contracts

### Vaults

| Contract | Idea | Status |
|---|---|---|
| `BaseVault` | Simple vault. Share price reads the real token balance. | Vulnerable to F-01 (on purpose) |
| `DeadShareVault` | Mints dead shares at deployment, so the vault is never empty. | F-01 becomes very expensive, not impossible |
| `InternalAccountingVault` | Keeps its own asset record and ignores donations. | Resists F-01 · F-02 fixed |

### Reentrancy

| Contract | Idea | Status |
|---|---|---|
| `VulnerableBank` | ETH bank that sends ETH before updating the balance. | Vulnerable to F-03 (on purpose) |

### Access control

| Contract | Idea | Status |
|---|---|---|
| `RescuableVault` | `InternalAccountingVault` with a rescue function for directly sent tokens. No owner check. | Vulnerable to F-04 (on purpose) |
| `RescuableVaultFixed` | Same vault. `rescueTokens` reverts if the caller is not the owner. | F-04 fixed |

### Denial of Service

| Contract | Idea | Status |
|---|---|---|
| `VulnerableAuction` | Auction that refunds the old bidder inside `bid()` and reverts if the refund fails. | Vulnerable to F-05 (on purpose) |

## Testing approach

- **Unit tests** (`test/unit/`) — normal user flows: deposit, withdraw, edge
  cases and reverts.
- **Attack PoCs** (`test/attacks/`) — each attack is a test. The same attack
  also runs against the defended contracts to show the defense works.
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
  reentrancy/      VulnerableBank.sol
  access-control/  RescuableVault.sol, RescuableVaultFixed.sol
  dos/             VulnerableAuction.sol
test/
  unit/            BaseVault.t.sol, InternalAccountingVault.t.sol
  attacks/         InflationAttack.t.sol, InflationAttack.Defended.t.sol,
                   ReentrancyAttacker.t.sol, AccessControlTest.t.sol,
                   DosAttack.t.sol
  invariant/       VaultInvariant.t.sol, Handler.sol
  helpers/         VaultTestBase.sol
  test-contracts/  MockToken.sol
docs/
  findings/        inflation_f01.md, inflation_f02.md,
                   reentrancy_f03.md, access_control_f04.md,
                   dos_f05.md
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

See the reentrancy staircase in the trace:

```bash
forge test --match-path test/attacks/ReentrancyAttacker.t.sol -vvvv
```