# Final Presentation: On-Chain Prediction Market

## Slide 1 — Title

On-Chain Prediction Market

Upgradeable binary markets with ERC20Votes governance, ERC1155 outcome shares, ERC4626 fee vault, Chainlink-style oracle checks, and Foundry test coverage.

## Slide 2 — Problem

Prediction markets need transparent market creation, reliable resolution, auditable payouts, and governance controls. The project demonstrates a complete protocol surface rather than a single isolated contract.

## Slide 3 — Architecture

The system centers on a UUPS `PredictionMarket` proxy. Traders use collateral to buy YES/NO exposure. Oracle data is wrapped by `OracleAdapter`. Governance is handled by `GovernanceToken`, `PredictionGovernor`, and `TimelockController`.

## Slide 4 — Smart Contracts

- `PredictionMarket`: market lifecycle, buying, resolving, claiming, fees
- `MarketFactory`: CREATE and CREATE2 deployment
- `OutcomeToken`: ERC1155 YES/NO outcome token IDs
- `FeeVault`: ERC4626 tokenized collateral vault
- `GovernanceToken`: ERC20Votes + ERC20Permit
- `PredictionGovernor`: Governor + Timelock

## Slide 5 — Governance Flow

The governance test demonstrates the full lifecycle:

propose -> vote -> queue -> timelock delay -> execute

The executed proposal calls `MarketFactory.deployToken` through the timelock.

## Slide 6 — Security

- Owner-only privileged functions
- UUPS owner initialization fixed
- ReentrancyGuard on token-flow functions
- Checks-Effects-Interactions for accounting
- SafeERC20 in market token transfers
- stale and negative oracle price reverts

## Slide 7 — Testing

Current local result:

86 tests passed, 0 failed, 0 skipped

Test categories include unit tests, fuzz tests, invariant tests, optional fork-safe tests, governance lifecycle tests, ERC1155 tests, and ERC4626 tests.

## Slide 8 — Frontend and Subgraph

The repo includes a lightweight frontend scaffold for wallet connection, contract reads, state-changing actions, governance vote action, and subgraph query demo.

The subgraph scaffold indexes Market, SharePurchase, Resolution, and FeeWithdrawal entities.

## Slide 9 — Deployment

`script/Deploy.s.sol` deploys collateral, oracle mock, governance token, outcome token, fee vault, prediction market implementation/proxy, factory, timelock, and governor.

`script/PostDeployCheck.s.sol` verifies core governance and ownership settings after deployment.

## Slide 10 — Defence Demo

1. Run `forge build`
2. Run `forge test`
3. Show `PredictionMarket.sol`
4. Show `PredictionGovernor.sol`
5. Show `FinalProjectAddons.t.sol`
6. Show README and architecture docs
7. Explain remaining network-only steps: L2 deployment addresses and live subgraph URL
