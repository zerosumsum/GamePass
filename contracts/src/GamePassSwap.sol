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
    
    /// @dev Exchange rate: CELO to PASS tokens (wei per token)
    /// Default: 1 CELO = 30 PASS tokens
    uint256 public celoExchangeRate;
    
    /// @dev Exchange rate: cUSD to PASS tokens (wei per token)
    /// Default: 0.17 cUSD = 30 PASS tokens
    uint256 public cusdExchangeRate;
    
    /// @dev Minimum CELO purchase amount
    uint256 public minCeloPurchase;
    
    /// @dev Minimum cUSD purchase amount
    uint256 public minCusdPurchase;
    
    /// @dev Event emitted when tokens are purchased
    event TokensPurchased(
        address indexed buyer,
        uint256 amount,
        string paymentMethod
    );
    
    /// @dev Event emitted when CELO exchange rate is updated
    event CeloExchangeRateUpdated(uint256 oldRate, uint256 newRate);
    
    /// @dev Event emitted when cUSD exchange rate is updated
    event CusdExchangeRateUpdated(uint256 oldRate, uint256 newRate);
    
    /**
     * @dev Constructor
     * @param _gamePassToken Address of GamePassToken contract
     * @param _cusdToken Address of cUSD token contract
     */
    constructor(
        address _gamePassToken,
        address _cusdToken
    ) Ownable(msg.sender) {
        require(_gamePassToken != address(0), "GamePassToken cannot be zero address");
        require(_cusdToken != address(0), "cUSD token cannot be zero address");
        
        gamePassToken = GamePassToken(_gamePassToken);
        cusdToken = IERC20(_cusdToken);
        
        // Default exchange rates: 1 CELO = 30 PASS, 0.17 cUSD = 30 PASS
        celoExchangeRate = 1 ether / 30; // 1 CELO / 30 PASS = 0.0333... CELO per PASS
        cusdExchangeRate = (17 * 10**16) / 30; // 0.17 cUSD / 30 PASS = 0.00566... cUSD per PASS
        
        // Minimum purchase: 0.01 CELO or 0.01 cUSD
        minCeloPurchase = 10**16; // 0.01 CELO
        minCusdPurchase = 10**16; // 0.01 cUSD
    }
    
    /**
     * @dev Buy PASS tokens with CELO (native currency)
     */
    function buyTokens() external payable nonReentrant {
        require(msg.value >= minCeloPurchase, "Payment below minimum");
        require(msg.value > 0, "Payment must be greater than zero");
        
        uint256 passAmount = (msg.value * 10**18) / celoExchangeRate;
        require(passAmount > 0, "Token amount must be greater than zero");
        
        gamePassToken.mint(msg.sender, passAmount);
        
        emit TokensPurchased(msg.sender, passAmount, "CELO");
    }

