# Gas Optimization Report

## Summary

The project uses optimizer settings in `foundry.toml`:

```toml
optimizer = true
optimizer_runs = 200
```

## Benchmarked Areas

| Area | Baseline | Optimized / Current |
|---|---|---|
| Price math | Solidity division | Inline Yul equivalent in `computePriceYul` |
| Token transfers | raw ERC20 calls | `SafeERC20` for robust return handling |
| Deployment | CREATE only | CREATE and CREATE2 factory paths |
| Governance execution | direct owner calls | Timelock batch execution |

## Yul vs Solidity

`PredictionMarket` exposes both:

- `computePriceSolidity(uint256,uint256)`
- `computePriceYul(uint256,uint256)`

The tests assert equivalent output. During defence, run:

```bash
forge test --match-test test_computePrice_yul_vs_solidity -vv
```

## L1 vs L2 Gas Comparison Template

Fill with actual explorer or `forge script` output after deployment.

| Operation | L1 estimated gas | L2 testnet gas | Notes |
|---|---:|---:|---|
| Deploy PredictionMarket implementation | TBD | TBD | UUPS implementation |
| Deploy ERC1967Proxy | TBD | TBD | initializer call included |
| createMarket | TBD | TBD | owner-only |
| buyShares | TBD | TBD | ERC20 transferFrom |
| resolveMarket | TBD | TBD | owner-only |
| claimWinnings | TBD | TBD | payout transfer |

## Future Optimizations

- Use assembly for CREATE2 prediction hash if gas is critical.
- Pack market fields where safe.
- Emit compact indexed event fields for subgraph indexing.
