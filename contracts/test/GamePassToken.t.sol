// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GamePassToken} from "../src/GamePassToken.sol";

contract GamePassTokenTest is Test {
    GamePassToken public token;
    
    address public owner = address(1);
    address public treasury = address(2);
    address public rewardsContract = address(3);
    address public swapContract = address(4);
    address public user1 = address(5);
    address public user2 = address(6);
    
    uint256 constant MAX_SUPPLY = 1_000_000_000 * 10**18;
    uint256 constant TREASURY_INITIAL_SUPPLY = 500_000_000 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        
        token = new GamePassToken(
            "GamePass Token",
            "PASS",
            treasury
        );
        
        vm.stopPrank();
    }
    
    // ============ Initial Supply Tests ============
    
    function test_InitialSupplyMinting() public {
        assertEq(token.totalSupply(), TREASURY_INITIAL_SUPPLY, "Treasury should receive 50% of max supply");
        assertEq(token.balanceOf(treasury), TREASURY_INITIAL_SUPPLY, "Treasury balance should be 50% of max supply");
        assertEq(token.name(), "GamePass Token", "Token name should be correct");
        assertEq(token.symbol(), "PASS", "Token symbol should be correct");
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY, "Max supply should be 1 billion tokens");
    }
    
    // ============ Minting Tests ============
    
    function test_MintingFromRewardsContract() public {
        vm.startPrank(owner);
        token.setRewardsContract(rewardsContract);
        vm.stopPrank();
        
        uint256 mintAmount = 1000 * 10**18;
        
        vm.startPrank(rewardsContract);
        token.mint(user1, mintAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), mintAmount, "User1 should receive minted tokens");
        assertEq(token.totalSupply(), TREASURY_INITIAL_SUPPLY + mintAmount, "Total supply should increase");
    }
    
    function test_MintingFromSwapContract() public {
        vm.startPrank(owner);
        token.setSwapContract(swapContract);
        vm.stopPrank();
        
        uint256 mintAmount = 2000 * 10**18;
        
        vm.startPrank(swapContract);
        token.mint(user1, mintAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), mintAmount, "User1 should receive minted tokens");
        assertEq(token.totalSupply(), TREASURY_INITIAL_SUPPLY + mintAmount, "Total supply should increase");
    }
    
    function test_MintingFromOwner() public {
        uint256 mintAmount = 3000 * 10**18;
        
        vm.startPrank(owner);
        token.mint(user1, mintAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), mintAmount, "User1 should receive minted tokens");
        assertEq(token.totalSupply(), TREASURY_INITIAL_SUPPLY + mintAmount, "Total supply should increase");
    }
    
    function test_RevertWhen_MintingExceedsMaxSupply() public {
        vm.startPrank(owner);
        token.setRewardsContract(rewardsContract);
        vm.stopPrank();
        
        uint256 remainingSupply = MAX_SUPPLY - TREASURY_INITIAL_SUPPLY;
        uint256 excessAmount = remainingSupply + 1;
        
        vm.startPrank(rewardsContract);
        vm.expectRevert("Exceeds max supply");
        token.mint(user1, excessAmount);
        vm.stopPrank();
    }
    
    function test_RevertWhen_MintingToZeroAddress() public {
        vm.startPrank(owner);
        token.setRewardsContract(rewardsContract);
        vm.stopPrank();
        
        uint256 mintAmount = 1000 * 10**18;
        
        vm.startPrank(rewardsContract);
        vm.expectRevert("Cannot mint to zero address");
        token.mint(address(0), mintAmount);
        vm.stopPrank();
    }
    
    function test_RevertWhen_UnauthorizedMinting() public {
        vm.startPrank(user1);
        vm.expectRevert("Not authorized to mint");
        token.mint(user2, 1000 * 10**18);
        vm.stopPrank();
    }
    
    function test_MintingUpToMaxSupply() public {
        vm.startPrank(owner);
        token.setRewardsContract(rewardsContract);
        vm.stopPrank();
        
        uint256 remainingSupply = MAX_SUPPLY - TREASURY_INITIAL_SUPPLY;
        
        vm.startPrank(rewardsContract);
        token.mint(user1, remainingSupply);
        vm.stopPrank();
        
        assertEq(token.totalSupply(), MAX_SUPPLY, "Total supply should equal max supply");
        assertEq(token.balanceOf(user1), remainingSupply, "User1 should receive remaining supply");
    }
    
    // ============ Pause Functionality Tests ============
    
    function test_PauseUnpause() public {
        vm.startPrank(owner);
        
        // Should not be paused initially
        assertFalse(token.paused(), "Token should not be paused initially");
        
        // Pause the token
        token.pause();
        assertTrue(token.paused(), "Token should be paused");
        
        // Unpause the token
        token.unpause();
        assertFalse(token.paused(), "Token should be unpaused");
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_TransferWhilePaused() public {
        vm.startPrank(owner);
        token.mint(user1, 1000 * 10**18);
        token.pause();
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.expectRevert();
        token.transfer(user2, 100 * 10**18);
        vm.stopPrank();
    }
    
    function test_RevertWhen_TransferFromWhilePaused() public {
        vm.startPrank(owner);
        token.mint(user1, 1000 * 10**18);
        token.pause();
        vm.stopPrank();
        
        vm.startPrank(user1);
        token.approve(user2, 100 * 10**18);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.expectRevert();
        token.transferFrom(user1, user2, 100 * 10**18);
        vm.stopPrank();
    }
    
    function test_TransferAfterUnpause() public {
        vm.startPrank(owner);
        token.mint(user1, 1000 * 10**18);
        token.pause();
        token.unpause();
        vm.stopPrank();
        
        vm.startPrank(user1);
        token.transfer(user2, 100 * 10**18);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user2), 100 * 10**18, "Transfer should work after unpause");
    }
    
    function test_RevertWhen_PauseByNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.pause();
        vm.stopPrank();
    }
    
    function test_RevertWhen_UnpauseByNonOwner() public {
        vm.startPrank(owner);
        token.pause();
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.expectRevert();
        token.unpause();
        vm.stopPrank();
    }
    
    // ============ Access Control Tests ============
    
    function test_SetRewardsContract() public {
        vm.startPrank(owner);
        token.setRewardsContract(rewardsContract);
        vm.stopPrank();
        
        assertEq(token.rewardsContract(), rewardsContract, "Rewards contract should be set");
    }
    
    function test_RevertWhen_SetRewardsContractByNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.setRewardsContract(rewardsContract);
        vm.stopPrank();
    }
    
    function test_RevertWhen_SetRewardsContractToZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Rewards contract cannot be zero address");
        token.setRewardsContract(address(0));
        vm.stopPrank();
    }
    
    function test_SetSwapContract() public {
        vm.startPrank(owner);
        token.setSwapContract(swapContract);
        vm.stopPrank();
        
        assertEq(token.swapContract(), swapContract, "Swap contract should be set");
    }
    
    function test_RevertWhen_SetSwapContractByNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.setSwapContract(swapContract);
        vm.stopPrank();
    }
    
    function test_RevertWhen_SetSwapContractToZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Swap contract cannot be zero address");
        token.setSwapContract(address(0));
        vm.stopPrank();
    }
    
    function test_SetTreasury() public {
        address newTreasury = address(7);
        
        vm.startPrank(owner);
        token.setTreasury(newTreasury);
        vm.stopPrank();
        
        assertEq(token.treasury(), newTreasury, "Treasury should be updated");
    }
    
    function test_RevertWhen_SetTreasuryByNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.setTreasury(address(7));
        vm.stopPrank();
    }
    
    function test_RevertWhen_SetTreasuryToZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Treasury cannot be zero address");
        token.setTreasury(address(0));
        vm.stopPrank();
    }
    
    // ============ Event Tests ============
    
    function test_RewardsContractUpdatedEvent() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, true, false, false);
        emit GamePassToken.RewardsContractUpdated(address(0), rewardsContract);
        token.setRewardsContract(rewardsContract);
        
        address newRewardsContract = address(8);
        vm.expectEmit(true, true, false, false);
        emit GamePassToken.RewardsContractUpdated(rewardsContract, newRewardsContract);
        token.setRewardsContract(newRewardsContract);
        
        vm.stopPrank();
    }
    
    function test_SwapContractUpdatedEvent() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, true, false, false);
        emit GamePassToken.SwapContractUpdated(address(0), swapContract);
        token.setSwapContract(swapContract);
        
        address newSwapContract = address(9);
        vm.expectEmit(true, true, false, false);
        emit GamePassToken.SwapContractUpdated(swapContract, newSwapContract);
        token.setSwapContract(newSwapContract);
        
        vm.stopPrank();
    }
    
    function test_TreasuryUpdatedEvent() public {
        address newTreasury = address(10);
        
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, false);
        emit GamePassToken.TreasuryUpdated(treasury, newTreasury);
        token.setTreasury(newTreasury);
        vm.stopPrank();
    }
    
    function test_TokensMintedEvent() public {
        vm.startPrank(owner);
        token.setRewardsContract(rewardsContract);
        vm.stopPrank();
        
        uint256 mintAmount = 1000 * 10**18;
        
        vm.startPrank(rewardsContract);
        vm.expectEmit(true, false, false, true);
        emit GamePassToken.TokensMinted(user1, mintAmount, rewardsContract);
        token.mint(user1, mintAmount);
        vm.stopPrank();
    }
    
    // ============ Burn Tests ============
    
    function test_Burn() public {
        vm.startPrank(owner);
        token.mint(user1, 1000 * 10**18);
        vm.stopPrank();
        
        uint256 burnAmount = 200 * 10**18;
        
        vm.startPrank(user1);
        token.burn(burnAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), 1000 * 10**18 - burnAmount, "Balance should decrease after burn");
        assertEq(token.totalSupply(), TREASURY_INITIAL_SUPPLY + 1000 * 10**18 - burnAmount, "Total supply should decrease");
    }
    
    function test_BurnFrom() public {
        vm.startPrank(owner);
        token.mint(user1, 1000 * 10**18);
        vm.stopPrank();
        
        uint256 burnAmount = 200 * 10**18;
        
        vm.startPrank(user1);
        token.approve(user2, burnAmount);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.burnFrom(user1, burnAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), 1000 * 10**18 - burnAmount, "Balance should decrease after burnFrom");
        assertEq(token.totalSupply(), TREASURY_INITIAL_SUPPLY + 1000 * 10**18 - burnAmount, "Total supply should decrease");
    }
    
    function test_RevertWhen_BurnWhilePaused() public {
        vm.startPrank(owner);
        token.mint(user1, 1000 * 10**18);
        token.pause();
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.expectRevert();
        token.burn(100 * 10**18);
        vm.stopPrank();
    }
