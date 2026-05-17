// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PredictionMarket is
    Initializable,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    struct Market {
        string question;
        uint256 endTime;
        uint256 resolvedAt;
        uint256 outcome;
        uint256 totalYes;
        uint256 totalNo;
        bool resolved;
    }

    IERC20 public collateralToken;
    uint256 public marketCount;
    uint256 public feeBps;
    uint256 public accumulatedFees;
    uint256 public disputeWindow;

    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => uint256)) public yesShares;
    mapping(uint256 => mapping(address => uint256)) public noShares;

    event MarketCreated(uint256 indexed marketId, string question, uint256 endTime);
    event SharesBought(uint256 indexed marketId, address indexed buyer, uint256 amount, bool isYes);
    event MarketResolved(uint256 indexed marketId, uint256 outcome);
    event WinningsClaimed(uint256 indexed marketId, address indexed claimer, uint256 payout);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event DisputeWindowUpdated(uint256 newWindow);
    event FeeBpsUpdated(uint256 newFeeBps);

    error MarketNotFound();
    error MarketAlreadyResolved();
    error MarketNotEnded();
    error MarketStillInDisputeWindow();
    error MarketEnded();
    error InvalidOutcome();
    error ZeroAmount();
    error NothingToClaim();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _collateralToken, uint256 _feeBps, uint256 _disputeWindow) public initializer {
        __Ownable_init(msg.sender);
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        collateralToken = IERC20(_collateralToken);
        feeBps = _feeBps;
        disputeWindow = _disputeWindow;
    }

    function createMarket(string calldata question, uint256 duration)
        external
        onlyOwner
        whenNotPaused
        returns (uint256 marketId)
    {
        marketId = marketCount++;
        markets[marketId] = Market({
            question: question,
            endTime: block.timestamp + duration,
            resolvedAt: 0,
            outcome: 0,
            totalYes: 0,
            totalNo: 0,
            resolved: false
        });
        emit MarketCreated(marketId, question, block.timestamp + duration);
    }

    function buyShares(uint256 marketId, uint256 amount, bool isYes) external nonReentrant whenNotPaused {
        if (marketId >= marketCount) revert MarketNotFound();
        if (amount == 0) revert ZeroAmount();
        Market storage m = markets[marketId];
        if (m.resolved) revert MarketAlreadyResolved();
        if (block.timestamp >= m.endTime) revert MarketEnded();

        uint256 fee = (amount * feeBps) / 10_000;
        uint256 netAmount = amount - fee;
        accumulatedFees += fee;

        if (isYes) {
            m.totalYes += netAmount;
            yesShares[marketId][msg.sender] += netAmount;
        } else {
            m.totalNo += netAmount;
            noShares[marketId][msg.sender] += netAmount;
        }

        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        emit SharesBought(marketId, msg.sender, netAmount, isYes);
    }

    function resolveMarket(uint256 marketId, uint256 outcome) external onlyOwner {
        if (marketId >= marketCount) revert MarketNotFound();
        Market storage m = markets[marketId];
        if (m.resolved) revert MarketAlreadyResolved();
        if (block.timestamp < m.endTime) revert MarketNotEnded();
        if (block.timestamp < m.endTime + disputeWindow) revert MarketStillInDisputeWindow();
        if (outcome != 1 && outcome != 2) revert InvalidOutcome();

        m.resolved = true;
        m.outcome = outcome;
        m.resolvedAt = block.timestamp;
        emit MarketResolved(marketId, outcome);
    }

    function claimWinnings(uint256 marketId) external nonReentrant {
        if (marketId >= marketCount) revert MarketNotFound();
        Market storage m = markets[marketId];
        if (!m.resolved) revert MarketAlreadyResolved();

        uint256 userShares;
        uint256 totalWinning;
        uint256 totalPool = m.totalYes + m.totalNo;

        if (m.outcome == 1) {
            userShares = yesShares[marketId][msg.sender];
            totalWinning = m.totalYes;
            yesShares[marketId][msg.sender] = 0;
        } else {
            userShares = noShares[marketId][msg.sender];
            totalWinning = m.totalNo;
            noShares[marketId][msg.sender] = 0;
        }

        if (userShares == 0) revert NothingToClaim();
        uint256 payout = (userShares * totalPool) / totalWinning;
        collateralToken.safeTransfer(msg.sender, payout);
        emit WinningsClaimed(marketId, msg.sender, payout);
    }

    function computePriceYul(uint256 yesPool, uint256 totalPool) external pure returns (uint256 price) {
        assembly {
            if iszero(totalPool) { revert(0, 0) }
            price := div(mul(yesPool, 1000000000000000000), totalPool)
        }
    }

    function computePriceSolidity(uint256 yesPool, uint256 totalPool) external pure returns (uint256) {
        require(totalPool > 0, "zero pool");
        return (yesPool * 1e18) / totalPool;
    }

    function withdrawFees(address to) external onlyOwner {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        collateralToken.safeTransfer(to, amount);
        emit FeesWithdrawn(to, amount);
    }

    function setFeeBps(uint256 _feeBps) external onlyOwner {
        feeBps = _feeBps;
        emit FeeBpsUpdated(_feeBps);
    }

    function setDisputeWindow(uint256 _window) external onlyOwner {
        disputeWindow = _window;
        emit DisputeWindowUpdated(_window);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
