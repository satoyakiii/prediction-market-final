# GraphQL Queries

```graphql
{
  markets(first: 10) {
    id
    question
    endTime
    resolved
    outcome
  }
}
```

```graphql
{
  sharePurchases(first: 10, orderBy: blockNumber, orderDirection: desc) {
    id
    buyer
    amount
    isYes
    market { id question }
  }
}
```

```graphql
{
  resolutions(first: 10) {
    id
    outcome
    market { id question }
  }
}
```

```graphql
{
  feeWithdrawals(first: 10) {
    id
    to
    amount
    blockNumber
  }
}
```

```graphql
{
  markets(where: { resolved: false }) {
    id
    question
    totalVolume
  }
}
```
