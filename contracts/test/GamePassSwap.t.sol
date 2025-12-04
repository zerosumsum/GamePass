// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GamePassSwap} from "../src/GamePassSwap.sol";
import {GamePassToken} from "../src/GamePassToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing cUSD
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract GamePassSwapTest is Test {
    GamePassSwap public swap;
    GamePassToken public token;
    MockERC20 public cusd;
    
    address public owner = address(1);
    address public treasury = address(2);
    address public buyer = address(3);
    address public user1 = address(4);
    
    uint256 constant ONE_CELO = 1 ether;
    uint256 constant THIRTY_PASS = 30 * 10**18;

