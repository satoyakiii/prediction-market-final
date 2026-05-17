# Internal Security Audit Report

## Executive Summary

The reviewed protocol implements a UUPS prediction market, governance token, Governor + Timelock flow, ERC1155 outcome shares, ERC4626 fee vault, factory deployment, and Chainlink-style oracle adapter. The current local test suite builds and runs with Foundry and includes unit, fuzz, invariant, and optional fork-safe tests.

## Scope

Commit: local final defence workspace.

In scope:

- `src/PredictionMarket.sol`
- `src/GovernanceToken.sol`
- `src/PredictionGovernor.sol`
- `src/MarketFactory.sol`
- `src/OutcomeToken.sol`
- `src/FeeVault.sol`
- `src/OracleAdapter.sol`
- `src/MockCollateral.sol`
- `src/MockAggregatorV3.sol`

Out of scope:

- Third-party OpenZeppelin and Chainlink libraries.
- Mock-only deployment assumptions.

## Methodology

- Manual review of access control, CEI, external calls, and upgradeability.
- Foundry unit/fuzz/invariant tests.
- Static lint notes reviewed from `forge build`.
- Slither expected command:

```bash
slither . --filter-paths lib
```

## Findings

| ID | Severity | Title | Status |
|---|---:|---|---|
| S-01 | High | UUPS owner not initialized | Fixed |
| S-02 | Medium | CREATE2 prediction used caller instead of factory as deployer | Fixed |
| S-03 | Low | Oracle cast int256 to uint256 relies on prior sign check | Acknowledged |
| S-04 | Informational | Foundry lint prefers named imports | Acknowledged |
| G-01 | Gas | CREATE2 address hashing can be optimized in assembly | Acknowledged |

### S-01 UUPS owner not initialized

Location: `src/PredictionMarket.sol:64`

Description: the proxy initializer originally called `__Ownable2Step_init()` without initializing `OwnableUpgradeable` with an owner. All `onlyOwner` calls reverted.

Impact: protocol administration, upgrades, market creation, and resolution were unusable.

Recommendation: call `__Ownable_init(msg.sender)` during initialization.

Status: fixed and covered by tests.

### S-02 CREATE2 prediction mismatch

Location: `src/MarketFactory.sol`

Description: CREATE2 predicted address must use the factory contract as the deployer in the `0xff` preimage. The old prediction used an external deployer argument.

Impact: deterministic deployment address assertion failed.

Recommendation: hash with `address(this)` as the deployer and keep token initial owner separate.

Status: fixed and covered by tests.

### S-03 Oracle signed cast

Location: `src/OracleAdapter.sol`

Description: `uint256(answer)` can be unsafe if `answer < 0`.

Impact: negative prices could become huge unsigned values if unchecked.

Recommendation: retain the existing `if (answer < 0) revert NegativePrice();` check before casting.

Status: acknowledged; control is present.

## Access Control Review

- `PredictionMarket`: privileged functions use `onlyOwner`.
- `GovernanceToken`: minting uses `onlyOwner` and max supply cap.
- `OutcomeToken`: mint/burn use `onlyOwner`.
- `MarketFactory`: deployment functions use `onlyOwner`; ownership can be transferred to timelock.
- `PredictionGovernor`: governance actions execute through TimelockController.

## Reentrancy Review

- `buyShares` and `claimWinnings` use `nonReentrant`.
- State is updated before external token transfers.
- ERC20 interactions use `SafeERC20` in `PredictionMarket`.

## Case Study: Reentrancy

Before: a payout function that transfers before zeroing user shares can be reentered by a malicious token/hook.

After: `claimWinnings` zeroes winning shares before the transfer and is guarded by `nonReentrant`. Tests exercise loser/unresolved/claim flows.

## Case Study: Access Control

Before: missing Ownable initialization made owner checks unusable and could block the protocol.

After: initializer explicitly sets owner and owner-only tests pass. Non-owner create/deploy/upgrade paths revert.

## Governance Attack Analysis

- Flash-loan voting: ERC20Votes uses historical snapshots, so voting power must exist before proposal snapshot.
- Whale attacks: quorum is 4%, proposal threshold is 1%.
- Proposal spam: proposal threshold limits spam.
- Timelock bypass: actions in the governance test are executed by Timelock after delay.

## Oracle Attack Analysis

- Stale price: adapter reverts if `block.timestamp - updatedAt > maxAge`.
- Negative price: adapter reverts.
- Feed depeg/manipulation: production deployment should use canonical Chainlink feeds and monitor feed health.

## Slither Appendix

Run before submission:

```bash
slither . --filter-paths lib
```

Target submission requirement: zero High and zero Medium findings. Any Low/Informational finding should be listed here with justification.
