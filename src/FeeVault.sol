// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FeeVault
/// @notice ERC4626 tokenized vault for protocol fee collateral.
contract FeeVault is ERC4626 {
    constructor(IERC20 asset_) ERC20("Prediction Fee Vault", "pFEE") ERC4626(asset_) {}
}
