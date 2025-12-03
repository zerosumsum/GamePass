// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title GamePassToken
 * @dev ERC20 token contract for GamePass platform
 * Compatible with Celo network
 * 
 * Features:
 * - Standard ERC20 functionality
 * - Burnable tokens
 * - Pausable transfers
 * - Maximum supply of 1 billion tokens
 * - Minting capabilities for rewards and swap contracts
 * - Treasury receives 50% of supply on deployment
 */
contract GamePassToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ReentrancyGuard {
    /// @dev Maximum supply: 1 billion tokens
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;
    
    /// @dev Address of the rewards contract that can mint tokens
    address public rewardsContract;
    
    /// @dev Address of the swap contract that can mint tokens
    address public swapContract;
    
    /// @dev Treasury address that receives initial supply
    address public treasury;
    
    /// @dev Event emitted when rewards contract is updated
    event RewardsContractUpdated(address indexed oldContract, address indexed newContract);
    
    /// @dev Event emitted when swap contract is updated
    event SwapContractUpdated(address indexed oldContract, address indexed newContract);
    
    /// @dev Event emitted when treasury is updated
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    
    /// @dev Event emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 amount, address indexed minter);
    
    /**
     * @dev Constructor
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _treasury Treasury address to receive 50% of max supply
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _treasury
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_treasury != address(0), "Treasury cannot be zero address");
        
        treasury = _treasury;
        
        // Mint 50% of max supply to treasury
        uint256 treasuryAmount = MAX_SUPPLY / 2;
        _mint(treasury, treasuryAmount);
        
        emit TokensMinted(treasury, treasuryAmount, msg.sender);
    }

