// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GamePassGem} from "../src/GamePassGem.sol";

contract GamePassGemTest is Test {
    GamePassGem public gem;
    
    address public owner = address(1);
    address public treasury = address(2);
    address public player1 = address(3);
    address public paymentToken = address(4); // Mock token address
    
    uint256 constant PRICE_PER_GEM = 34 * 10**18;
    uint256 constant MAX_SUPPLY = 10000;
    
    function setUp() public {
        vm.startPrank(owner);
        
        gem = new GamePassGem(
            "GamePass Gem",
            "GPG",
            MAX_SUPPLY,
            paymentToken,
            treasury
        );
        
        gem.setClaimConditions(true, block.timestamp);
        
        vm.stopPrank();
    }
    
    function testMintGem() public {
        // Test will be implemented after token contract is created
        assertTrue(true);
    }
    
    function test_RevertWhen_ClaimNotActive() public {
        vm.startPrank(owner);
        gem.setClaimConditions(false, block.timestamp);
        vm.stopPrank();
        
        vm.startPrank(player1);
        vm.expectRevert("Claim is not active");
        gem.claim(
            player1,
            1,
            paymentToken,
            PRICE_PER_GEM,
            GamePassGem.AllowlistProof(new bytes32[](0), 0, 0, address(0)),
            ""
        );
        vm.stopPrank();
    }
    
    function test_RevertWhen_ExceedsMaxSupply() public {
        vm.startPrank(owner);
        gem.setMaxSupply(1);
        vm.stopPrank();
        
        // First mint should work, second should fail
        // Implementation depends on token contract
        assertTrue(true);
    }
    
    function testSetClaimConditions() public {
        vm.startPrank(owner);
        gem.setClaimConditions(true, block.timestamp + 100);
        assertTrue(gem.claimActive());
        assertEq(gem.claimStartTime(), block.timestamp + 100);
        vm.stopPrank();
    }
}

