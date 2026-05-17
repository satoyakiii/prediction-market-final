# Deployments

## Local / Anvil

Use:

```bash
anvil
forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
```

## L2 Testnet

Required target: Arbitrum Sepolia, Optimism Sepolia, Base Sepolia, or zkSync Sepolia.

| Network | Contract | Address | Verified |
|---|---|---|---|
| Base Sepolia / Arbitrum Sepolia | MockCollateral | TODO | TODO |
| Base Sepolia / Arbitrum Sepolia | PredictionMarket proxy | TODO | TODO |
| Base Sepolia / Arbitrum Sepolia | GovernanceToken | TODO | TODO |
| Base Sepolia / Arbitrum Sepolia | OutcomeToken | TODO | TODO |
| Base Sepolia / Arbitrum Sepolia | FeeVault | TODO | TODO |
| Base Sepolia / Arbitrum Sepolia | TimelockController | TODO | TODO |
| Base Sepolia / Arbitrum Sepolia | PredictionGovernor | TODO | TODO |
| Base Sepolia / Arbitrum Sepolia | MarketFactory | TODO | TODO |

After deployment:

```bash
GOVERNOR=0x... TIMELOCK=0x... FACTORY=0x... forge script script/PostDeployCheck.s.sol:PostDeployCheck --rpc-url $RPC_URL
```
