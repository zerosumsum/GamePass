// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GamePassRewards} from "../src/GamePassRewards.sol";
import {GamePassToken} from "../src/GamePassToken.sol";

contract GamePassRewardsTest is Test {
    GamePassRewards public rewards;
    GamePassToken public token;
    
    address public owner = address(1);
    address public backend = address(2);
    address public treasury = address(3);
    address public player1 = address(4);
    address public player2 = address(5);
    address public player3 = address(6);
    address public player4 = address(7);
    
    uint256 public constant MIN_SCORE_THRESHOLD = 10;
    uint256 public constant PRIZE_POOL_AMOUNT = 1000 * 10**18; // 1000 PASS tokens
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy GamePassToken
        token = new GamePassToken("GamePass Token", "PASS", treasury);
        
        // Deploy GamePassRewards
        rewards = new GamePassRewards(address(token), backend, MIN_SCORE_THRESHOLD);
        
        // Set rewards contract in token
        token.setRewardsContract(address(rewards));
        
        vm.stopPrank();
    }
}

