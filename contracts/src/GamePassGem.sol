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
 * 
 * Players must mint one Gem NFT (costs 34 PASS tokens) to unlock all games
 * One Gem unlocks access to all available games in the platform
 * Gems are transferable ERC721 tokens that can be traded or sold
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
    
    /**
     * @dev Claim/mint a Gem NFT
     * @param _receiver Address to receive the Gem
     * @param _quantity Number of Gems to mint
     * @param _currency Payment token address
     * @param _pricePerToken Price per token
     * @param _allowlistProof Allowlist proof (not used but for compatibility)
     * @param _data Additional data (not used)
     */
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof memory _allowlistProof,
        bytes memory _data
    ) external payable nonReentrant {
        require(claimActive, "Claim is not active");
        require(block.timestamp >= claimStartTime, "Claim has not started");
        require(_quantity == 1, "Can only claim one Gem at a time");
        require(_tokenIdCounter + _quantity - 1 <= maxSupply, "Exceeds max supply");
        require(_currency == paymentToken, "Invalid payment token");
        require(_pricePerToken == PRICE_PER_GEM, "Invalid price");
        
        uint256 totalPrice = PRICE_PER_GEM * _quantity;
        
        // Transfer payment tokens from user to treasury
        IERC20(paymentToken).safeTransferFrom(msg.sender, treasury, totalPrice);
        
        // Mint NFTs
        uint256 startTokenId = _tokenIdCounter;
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(_receiver, _tokenIdCounter);
            _tokenIdCounter++;
        }
        
        emit TokensClaimed(0, msg.sender, _receiver, startTokenId, _quantity);
    }
    
    /**
     * @dev Set claim conditions (only owner)
     * @param _active Whether claiming is active
     * @param _startTime When claiming can start
     */
    function setClaimConditions(bool _active, uint256 _startTime) external onlyOwner {
        claimActive = _active;
        claimStartTime = _startTime;
        emit ClaimConditionsUpdated(_active, _startTime);
    }
    
    /**
     * @dev Set max supply (only owner)
     * @param _maxSupply New maximum supply
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= _tokenIdCounter - 1, "Max supply cannot be less than current supply");
        require(_maxSupply > 0, "Max supply must be greater than 0");
        maxSupply = _maxSupply;
    }
    
    /**
     * @dev Get total supply of minted Gems
     * @return Total number of Gems minted
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter - 1;
    }
    
    /**
     * @dev Override base URI function
     * @param tokenId Token ID
     * @return Token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return super.tokenURI(tokenId);
    }
}
