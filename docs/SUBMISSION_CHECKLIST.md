# Submission Checklist

## Include In GitHub

- `src/`
- `test/`
- `script/`
- `docs/`
- `frontend/`
- `subgraph/`
- `.github/workflows/ci.yml`
- `.env.example`
- `foundry.toml`
- `foundry.lock`
- `.gitmodules`
- `README.md`

## Do Not Commit

- `.env`
- private keys
- `cache/`
- `out/`
- temporary screenshots or local IDE files

## Before Upload

```bash
forge build
forge test
forge fmt --check
forge coverage --ir-minimum --report summary
```

Expected test result:

```text
86 tests passed, 0 failed, 0 skipped
```

## Still Requires Real Network Inputs

These cannot be completed without a funded deployer key and RPC:

- L2 deployment transaction hashes
- verified explorer links
- live subgraph URL
- final frontend addresses

Use `.env.example` as the template for local secrets, but never submit `.env`.
