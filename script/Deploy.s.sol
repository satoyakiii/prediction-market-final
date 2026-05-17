// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/PredictionMarket.sol";
import "../src/GovernanceToken.sol";
import "../src/MarketFactory.sol";
import "../src/MockCollateral.sol";
import "../src/OutcomeToken.sol";
import "../src/FeeVault.sol";
import "../src/PredictionGovernor.sol";
import "../src/OracleAdapter.sol";
import "../src/MockAggregatorV3.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1. Mock collateral (testnet only)
        MockCollateral collateral = new MockCollateral("USD Coin", "USDC", deployer);
        console.log("MockCollateral:", address(collateral));

        // 2. Mock Chainlink aggregator (testnet)
        MockAggregatorV3 aggregator = new MockAggregatorV3(1e8, 8);
        console.log("MockAggregator:", address(aggregator));

        // 3. Oracle adapter — staleness 1 hour
        OracleAdapter oracleAdapter = new OracleAdapter(address(aggregator), 3600);
        console.log("OracleAdapter:", address(oracleAdapter));

        // 4. Governance token
        GovernanceToken govToken = new GovernanceToken(deployer);
        console.log("GovernanceToken:", address(govToken));

        // 4b. Outcome shares and ERC4626 fee vault
        OutcomeToken outcomeToken = new OutcomeToken(deployer);
        FeeVault feeVault = new FeeVault(collateral);
        console.log("OutcomeToken:", address(outcomeToken));
        console.log("FeeVault:", address(feeVault));

        // 5. PredictionMarket implementation + UUPS proxy
        PredictionMarket impl = new PredictionMarket();
        bytes memory initData = abi.encodeCall(PredictionMarket.initialize, (address(collateral), 30, 1 hours));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        PredictionMarket predictionMarket = PredictionMarket(address(proxy));
        console.log("PredictionMarket (proxy):", address(predictionMarket));
        console.log("PredictionMarket (impl):", address(impl));

        // 6. Factory
        MarketFactory factory = new MarketFactory(deployer);
        console.log("MarketFactory:", address(factory));

        // 6b. Governor + 2-day timelock
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        TimelockController timelock = new TimelockController(2 days, proposers, executors, deployer);
        PredictionGovernor governor = new PredictionGovernor(govToken, timelock);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        factory.transferOwnership(address(timelock));
        console.log("TimelockController:", address(timelock));
        console.log("PredictionGovernor:", address(governor));

        // 7. Create first demo market
        predictionMarket.createMarket("Will ETH exceed $5000 by end of 2025?", 30 days);
        console.log("Demo market created: id=0");

        vm.stopBroadcast();

        // Summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network:          ", block.chainid);
        console.log("Deployer:         ", deployer);
        console.log("Collateral:       ", address(collateral));
        console.log("GovernanceToken:  ", address(govToken));
        console.log("OutcomeToken:     ", address(outcomeToken));
        console.log("FeeVault:         ", address(feeVault));
        console.log("PredictionMarket: ", address(predictionMarket));
        console.log("MarketFactory:    ", address(factory));
        console.log("Timelock:         ", address(timelock));
        console.log("Governor:         ", address(governor));
        console.log("OracleAdapter:    ", address(oracleAdapter));
    }
}
