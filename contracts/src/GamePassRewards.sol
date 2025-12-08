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
    
    /**
     * @dev Constructor
     * @param _gamePassToken Address of GamePassToken contract
     * @param _backendValidator Address of backend validator
     * @param _minScoreThreshold Minimum score threshold to qualify
     */
    constructor(
        address _gamePassToken,
        address _backendValidator,
        uint256 _minScoreThreshold
    ) Ownable(msg.sender) {
        require(_gamePassToken != address(0), "GamePassToken cannot be zero address");
        require(_backendValidator != address(0), "Backend validator cannot be zero address");
        
        gamePassToken = GamePassToken(_gamePassToken);
        backendValidator = _backendValidator;
        minScoreThreshold = _minScoreThreshold;
    }
    
    /**
     * @dev Submit a score for a player (only backend)
     * @param _player Address of the player
     * @param _score Score achieved by the player
     */
    function submitScore(address _player, uint256 _score) external {
        require(msg.sender == backendValidator, "Only backend can submit scores");
        require(_player != address(0), "Player cannot be zero address");
        require(_score >= minScoreThreshold, "Score below minimum threshold");
        
        uint256 currentIndex = playerIndex[_player];
        bool isNewEntry = (currentIndex == 0);
        
        // If player already has an entry, check if new score is higher
        if (!isNewEntry) {
            uint256 actualIndex = currentIndex - 1; // Convert from 1-indexed to 0-indexed
            require(_score > leaderboard[actualIndex].score, "New score must be higher");
            // Remove old entry
            _removeFromLeaderboard(actualIndex);
        }
        
        // Insert new entry in sorted order
        _insertIntoLeaderboard(_player, _score);
        
        emit ScoreSubmitted(_player, _score, block.timestamp);
    }
    
    /**
     * @dev Internal function to insert entry into leaderboard in sorted order
     * @param _player Address of the player
     * @param _score Score achieved
     */
    function _insertIntoLeaderboard(address _player, uint256 _score) internal {
        LeaderboardEntry memory newEntry = LeaderboardEntry({
            player: _player,
            score: _score,
            timestamp: block.timestamp,
            claimed: false
        });
        
        // Find insertion point (scores sorted descending)
        uint256 insertIndex = leaderboard.length;
        for (uint256 i = 0; i < leaderboard.length; i++) {
            if (_score > leaderboard[i].score) {
                insertIndex = i;
                break;
            }
        }
        
        // Insert at the found position
        if (insertIndex < leaderboard.length) {
            // Shift existing entries
            leaderboard.push(leaderboard[leaderboard.length - 1]);
            for (uint256 i = leaderboard.length - 1; i > insertIndex; i--) {
                leaderboard[i] = leaderboard[i - 1];
                playerIndex[leaderboard[i].player] = i + 1; // Update index (1-indexed)
            }
            leaderboard[insertIndex] = newEntry;
        } else {
            // Append to end
            leaderboard.push(newEntry);
        }
        
        // Update player index (1-indexed to distinguish from 0)
        playerIndex[_player] = insertIndex + 1;
        
        // Maintain max size
        if (leaderboard.length > MAX_LEADERBOARD_SIZE) {
            address removedPlayer = leaderboard[leaderboard.length - 1].player;
            playerIndex[removedPlayer] = 0; // Reset index
            leaderboard.pop();
        }
    }
    
    /**
     * @dev Internal function to remove entry from leaderboard
     * @param _index Index of entry to remove
     */
    function _removeFromLeaderboard(uint256 _index) internal {
        require(_index < leaderboard.length, "Index out of bounds");
        
        address removedPlayer = leaderboard[_index].player;
        
        // Shift entries left
        for (uint256 i = _index; i < leaderboard.length - 1; i++) {
            leaderboard[i] = leaderboard[i + 1];
            playerIndex[leaderboard[i].player] = i + 1; // Update index (1-indexed)
        }
        
        leaderboard.pop();
        playerIndex[removedPlayer] = 0; // Reset index
    }

