# Coverage Report

Generate the latest report:

```bash
forge coverage --report summary
forge coverage --report lcov
```

Latest local command:

```bash
forge coverage --ir-minimum --report summary
```

`--ir-minimum` is required in this repo because the full deployment script hits
`stack too deep` when Foundry disables IR for coverage.

Latest summary:

| File | Lines | Statements | Branches | Functions |
|---|---:|---:|---:|---:|
| `src/Counter.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/GovernanceToken.sol` | 77.78% | 66.67% | 0.00% | 75.00% |
| `src/MarketFactory.sol` | 88.89% | 81.25% | 0.00% | 100.00% |
| `src/MockAggregatorV3.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/MockCollateral.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/OracleAdapter.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/OutcomeToken.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/PredictionGovernor.sol` | 88.89% | 88.24% | 100.00% | 88.89% |
| `src/PredictionMarket.sol` | 87.80% | 86.05% | 73.68% | 100.00% |
| Total including scripts/tests | 64.83% | 56.79% | 47.06% | 88.24% |

The total is pulled down by `script/` files, which are not normally part of the
runtime protocol coverage target. The important defence point is that all 86
tests pass and the main source contracts have focused unit/fuzz/invariant tests.

Current local verification focus:

- Unit tests cover market lifecycle, factory, oracle, governance token, ERC1155, ERC4626, Governor/Timelock.
- Fuzz tests cover share buying, fee math, governance voting power, vault deposit/redeem, outcome token IDs.
- Invariant tests cover fee accounting, market count, vault asset/share accounting, valid resolution state, pool consistency.
- Optional fork-safe tests are present and only create forks when `MAINNET_RPC_URL` or `SEPOLIA_RPC_URL` is configured.
