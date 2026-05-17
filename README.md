# On-Chain Prediction Market Final Project

Full-stack decentralized protocol for binary prediction markets. The repo is a Foundry project with upgradeable market logic, CREATE/CREATE2 factory deployment, ERC20Votes governance, ERC1155 outcome shares, ERC4626 fee vault, Chainlink-style oracle adapter, tests, deployment scripts, frontend scaffold, subgraph scaffold, and defence documentation.

## Core Components

| Component | File | Purpose |
|---|---|---|
| UUPS prediction market | `src/PredictionMarket.sol` | Market creation, share buying, resolution, payouts, fees, pause/upgrade controls |
| Governance token | `src/GovernanceToken.sol` | ERC20Votes + ERC20Permit voting token |
| Governor + Timelock | `src/PredictionGovernor.sol` | 1 day voting delay, 1 week voting period, 4% quorum, 2 day timelock |
| Outcome shares | `src/OutcomeToken.sol` | ERC1155 YES/NO outcome token IDs |
| Fee vault | `src/FeeVault.sol` | ERC4626 tokenized vault for fee collateral |
| Factory | `src/MarketFactory.sol` | CREATE and CREATE2 collateral token deployment |
| Oracle adapter | `src/OracleAdapter.sol` | Chainlink-style staleness and negative-price checks |

## Quick Start

```bash
forge build
forge test -v
```

Current local status:

```text
86 tests total
86 passing in local verification after final additions
forge build successful
```

Use this command before defence:

```bash
forge test -q
```

## Deployment

Set environment variables:

```bash
export PRIVATE_KEY=...
export RPC_URL=...
```

Deploy:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify
```

Post-deployment check:

```bash
export GOVERNOR=0x...
export TIMELOCK=0x...
export FACTORY=0x...
forge script script/PostDeployCheck.s.sol:PostDeployCheck --rpc-url $RPC_URL
```

## Defence Demo Flow

1. Run `forge build`.
2. Run `forge test -q`.
3. Show `PredictionMarket` UUPS proxy deployment in `Deploy.s.sol`.
4. Show `PredictionGovernor` lifecycle test: propose -> vote -> queue -> execute.
5. Show ERC1155 outcome share tests and ERC4626 vault tests.
6. Open `frontend/index.html` and connect a wallet / read configured addresses.
7. Explain subgraph entities in `subgraph/schema.graphql`.

## Documentation

- Architecture: `docs/ARCHITECTURE.md`
- Security audit: `docs/SECURITY_AUDIT.md`
- Gas report: `docs/GAS_REPORT.md`
- Coverage summary: `docs/COVERAGE.md`
- Slither status: `docs/SLITHER_REPORT.md`
- Submission checklist: `docs/SUBMISSION_CHECKLIST.md`
- Final presentation: `docs/final-presentation.pdf`
- GraphQL queries: `subgraph/queries.md`

## Environment Files

`.env` is only needed for real testnet deployment or fork testing. It must not be committed.
Use `.env.example` as the safe template.
