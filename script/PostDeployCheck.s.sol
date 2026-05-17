// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/PredictionGovernor.sol";
import "../src/MarketFactory.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract PostDeployCheck is Script {
    function run() external view {
        address governorAddress = vm.envAddress("GOVERNOR");
        address timelockAddress = vm.envAddress("TIMELOCK");
        address factoryAddress = vm.envAddress("FACTORY");

        PredictionGovernor governor = PredictionGovernor(payable(governorAddress));
        TimelockController timelock = TimelockController(payable(timelockAddress));
        MarketFactory factory = MarketFactory(factoryAddress);

        require(governor.votingDelay() == 1 days / 12, "wrong voting delay");
        require(governor.votingPeriod() == 1 weeks / 12, "wrong voting period");
        require(governor.quorumNumerator() == 4, "wrong quorum");
        require(timelock.getMinDelay() == 2 days, "wrong timelock delay");
        require(factory.owner() == timelockAddress, "factory not timelock-owned");

        console.log("Post-deployment checks passed");
    }
}
