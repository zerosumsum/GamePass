// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./GamePassToken.sol";

/**
 * @title GamePassRewards
 * @dev Contract for managing game scores, leaderboard, and reward distribution
 * Compatible with Celo network
 * 
 * Features:
 * - Score submission from backend only
 * - Leaderboard tracking (top 100 entries)
 * - Reward distribution based on rankings
 * - Prize pool management
 * - Minimum score threshold
 */
contract GamePassRewards is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    /// @dev GamePassToken contract instance
    GamePassToken public gamePassToken;
    
    /// @dev Backend validator address (only can submit scores)
    address public backendValidator;
    
    /// @dev Prize pool amount
    uint256 public prizePool;
    
    /// @dev Minimum score threshold to qualify for rewards
    uint256 public minScoreThreshold;
    
    /// @dev Maximum leaderboard size
    uint256 public constant MAX_LEADERBOARD_SIZE = 100;
    
    /// @dev Reward distribution percentages (in basis points, 10000 = 100%)
    uint256 public constant FIRST_PLACE_PERCENT = 4000;  // 40%
    uint256 public constant SECOND_PLACE_PERCENT = 2500; // 25%
    uint256 public constant THIRD_PLACE_PERCENT = 1500;  // 15%
    uint256 public constant PLACES_4_10_PERCENT = 1000;  // 10% split among 7 players
    uint256 public constant PARTICIPATION_PERCENT = 1000; // 10% split among all eligible
    
    /// @dev Leaderboard entry structure
    struct LeaderboardEntry {
        address player;
        uint256 score;
        uint256 timestamp;
        bool claimed;
    }
    
    /// @dev Leaderboard array (sorted by score descending)
    LeaderboardEntry[] public leaderboard;
    
    /// @dev Mapping from player address to their leaderboard index (0-indexed, +1 to distinguish from 0)
    mapping(address => uint256) public playerIndex;
    
    /// @dev Mapping to track if a player has claimed rewards
    mapping(address => bool) public hasClaimed;
    
    /// @dev Event emitted when a score is submitted
    event ScoreSubmitted(
        address indexed player,
        uint256 score,
        uint256 timestamp
    );
    
    /// @dev Event emitted when rewards are distributed
    event RewardsDistributed(
        address indexed player,
        uint256 amount,
        uint256 rank
    );
    
    /// @dev Event emitted when prize pool is funded
    event PrizePoolFunded(
        uint256 amount,
        uint256 newTotal
    );

