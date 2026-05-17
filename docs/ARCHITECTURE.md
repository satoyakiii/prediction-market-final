# Architecture Document

## System Context

```mermaid
C4Context
title Prediction Market Protocol
Person(trader, "Trader", "Buys YES/NO exposure and claims winnings")
Person(governor, "Token holder", "Delegates, proposes, votes")
System(protocol, "Prediction Market Protocol", "Upgradeable contracts, governance, oracle, vault")
System_Ext(chainlink, "Chainlink Feed", "Outcome/reference price data")
System_Ext(graph, "The Graph", "Indexes protocol events")
Rel(trader, protocol, "trade / claim")
Rel(governor, protocol, "propose / vote / execute")
Rel(protocol, chainlink, "read latestRoundData")
Rel(graph, protocol, "index events")
```

## Contract Relationships

```mermaid
flowchart TD
  User[Trader] --> PM[PredictionMarket UUPS Proxy]
  PM --> Collateral[MockCollateral ERC20]
  PM --> Oracle[OracleAdapter]
  Oracle --> Feed[MockAggregatorV3 / Chainlink]
  User --> Outcome[OutcomeToken ERC1155]
  User --> Vault[FeeVault ERC4626]
  GovToken[GovernanceToken ERC20Votes] --> Governor[PredictionGovernor]
  Governor --> Timelock[TimelockController 2 days]
  Timelock --> Factory[MarketFactory CREATE/CREATE2]
```

## Critical Flows

### Buy Shares

```mermaid
sequenceDiagram
  actor Trader
  participant Token as Collateral ERC20
  participant Market as PredictionMarket
  Trader->>Token: approve(market, amount)
  Trader->>Market: buyShares(marketId, amount, isYes)
  Market->>Market: checks market open and amount > 0
  Market->>Market: effects update totals, user shares, fees
  Market->>Token: safeTransferFrom(trader, market, amount)
```

### Resolve and Claim

```mermaid
sequenceDiagram
  actor Owner
  actor Winner
  participant Market as PredictionMarket
  Owner->>Market: resolveMarket(id, outcome)
  Market->>Market: check endTime + disputeWindow
  Winner->>Market: claimWinnings(id)
  Market->>Market: zero winning shares
  Market->>Winner: SafeERC20 transfer payout
```

### Governance Lifecycle

```mermaid
sequenceDiagram
  actor Holder
  participant Token as GovernanceToken
  participant Gov as PredictionGovernor
  participant TL as TimelockController
  participant Factory as MarketFactory
  Holder->>Token: delegate(holder)
  Holder->>Gov: propose(factory.deployToken)
  Holder->>Gov: castVote(For)
  Holder->>Gov: queue()
  Gov->>TL: scheduleBatch()
  Holder->>Gov: execute()
  Gov->>TL: executeBatch()
  TL->>Factory: deployToken()
```

## Storage Layout

Upgradeable storage is isolated in `PredictionMarket` behind `ERC1967Proxy`.

| Slot group | Variable |
|---|---|
| inherited | Initializable, UUPS, Ownable2Step, ReentrancyGuard, Pausable |
| protocol | `collateralToken`, `marketCount`, `feeBps`, `accumulatedFees`, `disputeWindow` |
| mappings | `markets`, `yesShares`, `noShares` |

No V2 state is added yet. The documented upgrade path is append-only storage: future variables must be added after the current mappings and never reorder existing fields.

## Trust Assumptions

- Market owner can create markets, resolve outcomes, pause/unpause, set fees and dispute window, withdraw fees, and authorize upgrades.
- Timelock controls factory deployment in the governance demo.
- Token holders control governance if they have delegated voting power.
- Chainlink feed freshness is trusted up to `maxAge`; stale or negative prices revert.

## Design Patterns

- Factory: `MarketFactory` deploys collateral tokens via CREATE and CREATE2.
- UUPS proxy: `PredictionMarket` is upgradeable and tested.
- Checks-Effects-Interactions: `buyShares` and `claimWinnings` update accounting before token transfers.
- Reentrancy Guard: state-changing token-flow functions use `nonReentrant`.
- Pausable: emergency circuit breaker.
- Oracle Adapter: `OracleAdapter` isolates feed interface and staleness logic.
- Timelock: governance actions execute through `TimelockController`.

## ADR Summary

1. **UUPS over Transparent Proxy**: UUPS keeps proxy small and puts upgrade authorization in the implementation.
2. **ERC20Votes for governance**: OpenZeppelin Votes gives snapshot-based voting power and delegation.
3. **Timelock delay**: 2 days gives users time to react to passed proposals.
4. **ERC1155 outcome shares**: one contract can represent YES/NO shares for every market.
5. **ERC4626 fee vault**: standard vault interface makes fee accounting auditable.
