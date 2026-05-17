// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MockCollateral.sol";

/// @title MarketFactory
/// @notice Deploys MockCollateral tokens via CREATE and CREATE2 (Factory pattern)
contract MarketFactory is Ownable {
    event TokenCreated(address indexed token, bytes32 salt, bool wasCREATE2);

    address[] public deployedTokens;

    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Deploy a new MockCollateral using regular CREATE
    function deployToken(string memory name, string memory symbol) external onlyOwner returns (address token) {
        token = address(new MockCollateral(name, symbol, msg.sender));
        deployedTokens.push(token);
        emit TokenCreated(token, bytes32(0), false);
    }

    /// @notice Deploy a new MockCollateral using CREATE2 (deterministic address)
    function deployTokenCREATE2(string memory name, string memory symbol, bytes32 salt)
        external
        onlyOwner
        returns (address token)
    {
        bytes memory bytecode =
            abi.encodePacked(type(MockCollateral).creationCode, abi.encode(name, symbol, msg.sender));
        assembly {
            token := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(token)) { revert(0, 0) }
        }
        deployedTokens.push(token);
        emit TokenCreated(token, salt, true);
    }

    /// @notice Predict the CREATE2 address without deploying
    function predictAddress(string memory name, string memory symbol, bytes32 salt, address initialOwner)
        external
        view
        returns (address)
    {
        bytes memory bytecode =
            abi.encodePacked(type(MockCollateral).creationCode, abi.encode(name, symbol, initialOwner));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }

    function deployedCount() external view returns (uint256) {
        return deployedTokens.length;
    }
}
