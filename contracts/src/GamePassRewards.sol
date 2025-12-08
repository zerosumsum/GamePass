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

