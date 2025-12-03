// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title GamePassGem
 * @dev ERC721 NFT contract for GamePass play-to-earn game
 * Compatible with Celo network
 * NFTs are referred to as "GEMS" in the game
 */
contract GamePassGem is ERC721URIStorage, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Token price: 34 PASS tokens per Gem
    uint256 public constant PRICE_PER_GEM = 34 * 10**18; // 34 PASS tokens with 18 decimals
    
    // Maximum supply
    uint256 public maxSupply;
    
    // Current token ID counter
    uint256 private _tokenIdCounter;
    
    // Payment token address (GamePassToken - PASS)
    address public paymentToken;
    
    // Treasury address to receive payments
    address public treasury;
    
    // Claim conditions
    bool public claimActive;
    uint256 public claimStartTime;
    
    // Allowlist proof structure (for compatibility with Thirdweb)
    struct AllowlistProof {
        bytes32[] proof;
        uint256 quantityLimitPerWallet;
        uint256 pricePerToken;
        address currency;
    }
    
    // Events
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 startTokenId,
        uint256 quantityClaimed
    );
    
    event ClaimConditionsUpdated(
        bool active,
        uint256 startTime
    );

    /**
     * @dev Constructor
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _maxSupply Maximum supply of Gems
     * @param _paymentToken Address of PASS token for payment
     * @param _treasury Treasury address to receive payments
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _paymentToken,
        address _treasury
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_maxSupply > 0, "Max supply must be greater than 0");
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        require(_treasury != address(0), "Treasury cannot be zero address");
        
        maxSupply = _maxSupply;
        paymentToken = _paymentToken;
        treasury = _treasury;
        _tokenIdCounter = 1;
    }

