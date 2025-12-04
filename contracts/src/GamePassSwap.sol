// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./GamePassToken.sol";

/**
 * @title GamePassSwap
 * @dev Contract for swapping CELO and cUSD for PASS tokens
 * Compatible with Celo network
 * 
 * Features:
 * - Buy PASS tokens with CELO (native currency)
 * - Buy PASS tokens with cUSD (stablecoin)
 * - Configurable exchange rates
 * - Direct token minting to buyers
 * - Owner-controlled rate updates
 */
contract GamePassSwap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    /// @dev GamePassToken contract instance
    GamePassToken public gamePassToken;
    
    /// @dev cUSD token address
    IERC20 public cusdToken;

