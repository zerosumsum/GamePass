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
        // Exchange rate represents the payment amount for 30 PASS tokens
        celoExchangeRate = 1 ether; // 1 CELO = 30 PASS
        cusdExchangeRate = 17 * 10**16; // 0.17 cUSD = 30 PASS
        
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
        
        uint256 passAmount = (msg.value * 30 * 10**18) / celoExchangeRate;
        require(passAmount > 0, "Token amount must be greater than zero");
        
        gamePassToken.mint(msg.sender, passAmount);
        
        emit TokensPurchased(msg.sender, passAmount, "CELO");
    }
    
    /**
     * @dev Buy PASS tokens with cUSD
     * @param _cusdAmount Amount of cUSD to spend
     */
    function buyTokensWithCUSD(uint256 _cusdAmount) external nonReentrant {
        require(_cusdAmount >= minCusdPurchase, "Payment below minimum");
        require(_cusdAmount > 0, "Payment must be greater than zero");
        
        uint256 passAmount = (_cusdAmount * 30 * 10**18) / cusdExchangeRate;
        require(passAmount > 0, "Token amount must be greater than zero");
        
        cusdToken.safeTransferFrom(msg.sender, address(this), _cusdAmount);
        gamePassToken.mint(msg.sender, passAmount);
        
        emit TokensPurchased(msg.sender, passAmount, "cUSD");
    }
    
    /**
     * @dev Set CELO exchange rate (only owner)
     * @param _rate New exchange rate (wei per token)
     */
    function setCeloExchangeRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Exchange rate must be greater than zero");
        
        uint256 oldRate = celoExchangeRate;
        celoExchangeRate = _rate;
        
        emit CeloExchangeRateUpdated(oldRate, _rate);
    }
    
    /**
     * @dev Set cUSD exchange rate (only owner)
     * @param _rate New exchange rate (wei per token)
     */
    function setCusdExchangeRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Exchange rate must be greater than zero");
        
        uint256 oldRate = cusdExchangeRate;
        cusdExchangeRate = _rate;
        
        emit CusdExchangeRateUpdated(oldRate, _rate);
    }
    
    /**
     * @dev Set minimum CELO purchase amount (only owner)
     * @param _minAmount Minimum purchase amount in wei
     */
    function setMinCeloPurchase(uint256 _minAmount) external onlyOwner {
        minCeloPurchase = _minAmount;
    }
    
    /**
     * @dev Set minimum cUSD purchase amount (only owner)
     * @param _minAmount Minimum purchase amount in wei
     */
    function setMinCusdPurchase(uint256 _minAmount) external onlyOwner {
        minCusdPurchase = _minAmount;
    }
    
    /**
     * @dev Withdraw CELO from contract (only owner)
     */
    function withdrawCELO() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Withdraw cUSD from contract (only owner)
     */
    function withdrawCUSD() external onlyOwner {
        uint256 balance = cusdToken.balanceOf(address(this));
        cusdToken.safeTransfer(owner(), balance);
    }
}
