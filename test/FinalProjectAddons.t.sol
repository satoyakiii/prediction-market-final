// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/FeeVault.sol";
import "../src/GovernanceToken.sol";
import "../src/MarketFactory.sol";
import "../src/MockCollateral.sol";
import "../src/OutcomeToken.sol";
import "../src/PredictionGovernor.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract FinalProjectAddonsTest is Test {
    MockCollateral public collateral;
    FeeVault public vault;
    OutcomeToken public outcomeToken;
    GovernanceToken public govToken;
    TimelockController public timelock;
    PredictionGovernor public governor;
    MarketFactory public factory;

    address owner = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        collateral = new MockCollateral("USD Coin", "USDC", owner);
        vault = new FeeVault(collateral);
        outcomeToken = new OutcomeToken(owner);
        govToken = new GovernanceToken(owner);
        factory = new MarketFactory(owner);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        timelock = new TimelockController(2 days, proposers, executors, owner);
        governor = new PredictionGovernor(govToken, timelock);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        factory.transferOwnership(address(timelock));

        collateral.mint(alice, 10_000 ether);
        collateral.mint(bob, 10_000 ether);
    }

    function test_outcomeToken_ids() public view {
        assertEq(outcomeToken.outcomeTokenId(0, true), 1);
        assertEq(outcomeToken.outcomeTokenId(0, false), 2);
        assertEq(outcomeToken.outcomeTokenId(7, true), 15);
        assertEq(outcomeToken.outcomeTokenId(7, false), 16);
    }

    function test_outcomeToken_mint_yes() public {
        outcomeToken.mint(alice, 1, true, 10);
        assertEq(outcomeToken.balanceOf(alice, 3), 10);
    }

    function test_outcomeToken_mint_no() public {
        outcomeToken.mint(bob, 2, false, 5);
        assertEq(outcomeToken.balanceOf(bob, 6), 5);
    }

    function test_outcomeToken_burn() public {
        outcomeToken.mint(alice, 1, true, 10);
        outcomeToken.burn(alice, 1, true, 4);
        assertEq(outcomeToken.balanceOf(alice, 3), 6);
    }

    function test_outcomeToken_onlyOwner_mint() public {
        vm.prank(alice);
        vm.expectRevert();
        outcomeToken.mint(alice, 1, true, 1);
    }

    function test_outcomeToken_onlyOwner_burn() public {
        outcomeToken.mint(alice, 1, true, 1);
        vm.prank(alice);
        vm.expectRevert();
        outcomeToken.burn(alice, 1, true, 1);
    }

    function test_vault_deposit_mintsShares() public {
        vm.startPrank(alice);
        collateral.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(shares, 100 ether);
        assertEq(vault.balanceOf(alice), 100 ether);
        assertEq(vault.totalAssets(), 100 ether);
    }

    function test_vault_withdraw_burnsShares() public {
        vm.startPrank(alice);
        collateral.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        uint256 shares = vault.withdraw(40 ether, alice, alice);
        vm.stopPrank();

        assertEq(shares, 40 ether);
        assertEq(vault.balanceOf(alice), 60 ether);
        assertEq(collateral.balanceOf(alice), 9_940 ether);
    }

    function test_vault_redeem() public {
        vm.startPrank(alice);
        collateral.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        uint256 assets = vault.redeem(25 ether, alice, alice);
        vm.stopPrank();

        assertEq(assets, 25 ether);
        assertEq(vault.balanceOf(alice), 75 ether);
    }

    function test_vault_previewDeposit() public view {
        assertEq(vault.previewDeposit(12 ether), 12 ether);
    }

    function test_vault_previewMint() public view {
        assertEq(vault.previewMint(12 ether), 12 ether);
    }

    function test_vault_previewWithdraw_afterDeposit() public {
        vm.startPrank(alice);
        collateral.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();
        assertEq(vault.previewWithdraw(10 ether), 10 ether);
    }

    function test_vault_previewRedeem_afterDeposit() public {
        vm.startPrank(alice);
        collateral.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();
        assertEq(vault.previewRedeem(10 ether), 10 ether);
    }

    function test_vault_twoDepositors_accounting() public {
        vm.prank(alice);
        collateral.approve(address(vault), 100 ether);
        vm.prank(alice);
        vault.deposit(100 ether, alice);

        vm.prank(bob);
        collateral.approve(address(vault), 50 ether);
        vm.prank(bob);
        vault.deposit(50 ether, bob);

        assertEq(vault.totalAssets(), 150 ether);
        assertEq(vault.balanceOf(alice), 100 ether);
        assertEq(vault.balanceOf(bob), 50 ether);
    }

    function test_governor_parameters() public view {
        assertEq(governor.votingDelay(), 1 days / 12);
        assertEq(governor.votingPeriod(), 1 weeks / 12);
        assertEq(governor.proposalThreshold(), 1_000 ether);
        assertEq(governor.quorumNumerator(), 4);
        assertEq(timelock.getMinDelay(), 2 days);
    }

    function test_governor_timelockLifecycle_deploysToken() public {
        govToken.delegate(owner);
        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(factory);
        calldatas[0] = abi.encodeCall(MarketFactory.deployToken, ("Gov Token", "GOV"));

        uint256 proposalId = governor.propose(targets, values, calldatas, "Deploy collateral token via governance");
        vm.roll(block.number + governor.votingDelay() + 1);

        governor.castVote(proposalId, 1);
        vm.roll(block.number + governor.votingPeriod() + 1);

        bytes32 descriptionHash = keccak256(bytes("Deploy collateral token via governance"));
        governor.queue(targets, values, calldatas, descriptionHash);
        vm.warp(block.timestamp + timelock.getMinDelay() + 1);
        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(factory.deployedCount(), 1);
    }

    function test_governor_proposalThresholdBlocksSmallHolder() public {
        assertTrue(govToken.transfer(alice, 999 ether));
        vm.prank(alice);
        govToken.delegate(alice);
        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(factory);
        calldatas[0] = abi.encodeCall(MarketFactory.deployToken, ("No", "NO"));

        vm.prank(alice);
        vm.expectRevert();
        governor.propose(targets, values, calldatas, "below threshold");
    }

    function test_timelockOwnsFactory() public view {
        assertEq(factory.owner(), address(timelock));
    }

    function test_timelockRejectsDirectFactoryCall() public {
        vm.expectRevert();
        factory.deployToken("Direct", "DIR");
    }

    function testFuzz_outcomeTokenId_isUnique(uint128 marketId) public view {
        uint256 yesId = outcomeToken.outcomeTokenId(marketId, true);
        uint256 noId = outcomeToken.outcomeTokenId(marketId, false);
        assertEq(noId, yesId + 1);
    }

    function testFuzz_vaultDepositWithdrawRoundTrip(uint128 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 1_000 ether);
        vm.startPrank(alice);
        collateral.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, alice);
        uint256 assets = vault.redeem(shares, alice, alice);
        vm.stopPrank();
        assertEq(assets, amount);
    }

    function testFuzz_vaultPreviewDeposit(uint128 rawAmount) public view {
        uint256 amount = bound(uint256(rawAmount), 1, 1_000 ether);
        assertEq(vault.previewDeposit(amount), amount);
    }

    function testFuzz_governanceVotingPower(uint128 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1 ether, 10_000 ether);
        assertTrue(govToken.transfer(alice, amount));
        vm.prank(alice);
        govToken.delegate(alice);
        vm.roll(block.number + 1);
        assertEq(govToken.getPastVotes(alice, block.number - 1), amount);
    }

    function testFork_chainIdReadable() public view {
        string memory rpc = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) return;
        assertGt(block.chainid, 0);
    }

    function testFork_canCreateOptionalMainnetFork() public {
        string memory rpc = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) return;
        uint256 forkId = vm.createFork(rpc);
        vm.selectFork(forkId);
        assertEq(block.chainid, 1);
    }

    function testFork_canCreateOptionalSepoliaFork() public {
        string memory rpc = vm.envOr("SEPOLIA_RPC_URL", string(""));
        if (bytes(rpc).length == 0) return;
        uint256 forkId = vm.createFork(rpc);
        vm.selectFork(forkId);
        assertEq(block.chainid, 11155111);
    }
}

contract FinalProjectInvariant is Test {
    MockCollateral public collateral;
    FeeVault public vault;
    address public alice = makeAddr("alice");

    function setUp() public {
        collateral = new MockCollateral("USD Coin", "USDC", address(this));
        vault = new FeeVault(collateral);
        collateral.mint(alice, 1_000_000 ether);
        vm.prank(alice);
        collateral.approve(address(vault), type(uint256).max);
    }

    function invariant_vaultAssetsCoverShares() public view {
        assertGe(vault.totalAssets(), vault.totalSupply());
    }

    function invariant_vaultSharePriceNonZeroWhenSupplyExists() public view {
        if (vault.totalSupply() > 0) {
            assertGt(vault.convertToAssets(1), 0);
        }
    }
}
