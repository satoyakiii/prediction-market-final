// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OutcomeToken
/// @notice ERC1155 YES/NO outcome share token used by the prediction-market protocol.
contract OutcomeToken is ERC1155, Ownable {
    constructor(address initialOwner) ERC1155("ipfs://prediction-market/{id}.json") Ownable(initialOwner) {}

    function outcomeTokenId(uint256 marketId, bool isYes) public pure returns (uint256) {
        return marketId * 2 + (isYes ? 1 : 2);
    }

    function mint(address to, uint256 marketId, bool isYes, uint256 amount) external onlyOwner {
        _mint(to, outcomeTokenId(marketId, isYes), amount, "");
    }

    function burn(address from, uint256 marketId, bool isYes, uint256 amount) external onlyOwner {
        _burn(from, outcomeTokenId(marketId, isYes), amount);
    }
}
