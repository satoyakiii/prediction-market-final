// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IAggregatorV3 {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

/// @title OracleAdapter
/// @notice Wraps Chainlink feed with staleness check — reverts if price is older than maxAge
contract OracleAdapter {
    IAggregatorV3 public immutable feed;
    uint256 public immutable maxAge; // seconds

    error StalePrice(uint256 updatedAt, uint256 maxAge);
    error NegativePrice();

    constructor(address _feed, uint256 _maxAge) {
        feed = IAggregatorV3(_feed);
        maxAge = _maxAge;
    }

    /// @notice Returns latest price, reverts if stale or negative
    function getPrice() external view returns (uint256 price, uint8 decimals) {
        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();
        if (block.timestamp - updatedAt > maxAge) revert StalePrice(updatedAt, maxAge);
        if (answer < 0) revert NegativePrice();
        // forge-lint: disable-next-line(unsafe-typecast)
        price = uint256(answer);
        decimals = feed.decimals();
    }
}
