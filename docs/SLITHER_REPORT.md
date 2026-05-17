# Slither Report

## Status

Slither was checked locally, but the `slither` executable is not installed in the current Windows environment.

Command attempted:

```powershell
Get-Command slither -ErrorAction SilentlyContinue
```

Result: no command found.

## Required Command For Final CI / Submission

Install Slither:

```bash
pipx install slither-analyzer
```

Then run:

```bash
slither . --filter-paths lib
```

Expected submission target:

- 0 High findings
- 0 Medium findings
- Low / Informational findings listed and justified in `docs/SECURITY_AUDIT.md`

## Current Manual Review Notes

- Privileged functions are protected by `onlyOwner` or Governor/Timelock.
- `PredictionMarket` uses `nonReentrant` for token-flow functions.
- ERC20 flows in `PredictionMarket` use `SafeERC20`.
- Oracle adapter rejects stale and negative prices.
- UUPS ownership initialization bug was fixed with `__Ownable_init(msg.sender)`.
