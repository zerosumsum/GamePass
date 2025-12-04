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
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy GamePassToken
        token = new GamePassToken("GamePass Token", "PASS", treasury);
        
        // Deploy mock cUSD
        cusd = new MockERC20("Celo Dollar", "cUSD");
        
        // Deploy GamePassSwap
        swap = new GamePassSwap(address(token), address(cusd));
        
        // Set swap contract in token
        token.setSwapContract(address(swap));
        
        vm.stopPrank();
        
        // Give buyer some cUSD
        vm.prank(owner);
        cusd.mint(buyer, 1000 ether);
    }
    
    // ============ CELO Purchase Tests ============
    
    function test_BuyTokensWithCELO() public {
        uint256 celoAmount = 1 ether; // 1 CELO
        uint256 expectedPass = THIRTY_PASS; // 30 PASS tokens
        
        vm.deal(buyer, celoAmount);
        
        vm.startPrank(buyer);
        swap.buyTokens{value: celoAmount}();
        vm.stopPrank();
        
        assertEq(token.balanceOf(buyer), expectedPass, "Buyer should receive 30 PASS tokens");
    }
    
    function test_BuyTokensWithCELO_FractionalAmount() public {
        uint256 celoAmount = 0.5 ether; // 0.5 CELO
        uint256 expectedPass = 15 * 10**18; // 15 PASS tokens
        
        vm.deal(buyer, celoAmount);
        
        vm.startPrank(buyer);
        swap.buyTokens{value: celoAmount}();
        vm.stopPrank();
        
        assertEq(token.balanceOf(buyer), expectedPass, "Buyer should receive 15 PASS tokens");
    }
    
    function test_RevertWhen_BuyTokens_BelowMinimum() public {
        uint256 celoAmount = swap.minCeloPurchase() - 1;
        
        vm.deal(buyer, celoAmount);
        
        vm.startPrank(buyer);
        vm.expectRevert("Payment below minimum");
        swap.buyTokens{value: celoAmount}();
        vm.stopPrank();
    }
    
    function test_RevertWhen_BuyTokens_ZeroValue() public {
        vm.startPrank(buyer);
        vm.expectRevert("Payment must be greater than zero");
        swap.buyTokens{value: 0}();
        vm.stopPrank();
    }
    
    // ============ cUSD Purchase Tests ============
    
    function test_BuyTokensWithCUSD() public {
        uint256 cusdAmount = 17 * 10**16; // 0.17 cUSD
        uint256 expectedPass = THIRTY_PASS; // 30 PASS tokens
        
        vm.startPrank(buyer);
        cusd.approve(address(swap), cusdAmount);
        swap.buyTokensWithCUSD(cusdAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(buyer), expectedPass, "Buyer should receive 30 PASS tokens");
        assertEq(cusd.balanceOf(address(swap)), cusdAmount, "Swap should receive cUSD");
    }
    
    function test_BuyTokensWithCUSD_FractionalAmount() public {
        uint256 cusdAmount = 85 * 10**15; // 0.085 cUSD (half of 0.17)
        uint256 expectedPass = 15 * 10**18; // 15 PASS tokens
        
        vm.startPrank(buyer);
        cusd.approve(address(swap), cusdAmount);
        swap.buyTokensWithCUSD(cusdAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(buyer), expectedPass, "Buyer should receive 15 PASS tokens");
    }
    
    function test_RevertWhen_BuyTokensWithCUSD_BelowMinimum() public {
        uint256 cusdAmount = swap.minCusdPurchase() - 1;
        
        vm.startPrank(buyer);
        cusd.approve(address(swap), cusdAmount);
        vm.expectRevert("Payment below minimum");
        swap.buyTokensWithCUSD(cusdAmount);
        vm.stopPrank();
    }
    
    function test_RevertWhen_BuyTokensWithCUSD_InsufficientBalance() public {
        uint256 cusdAmount = 1000 ether; // More than buyer has
        
        vm.startPrank(buyer);
        cusd.approve(address(swap), cusdAmount);
        vm.expectRevert();
        swap.buyTokensWithCUSD(cusdAmount);
        vm.stopPrank();
    }

    
    function test_RevertWhen_BuyTokensWithCUSD_InsufficientAllowance() public {
        uint256 cusdAmount = 17 * 10**16;
        
        vm.startPrank(buyer);
        vm.expectRevert();
        swap.buyTokensWithCUSD(cusdAmount);
        vm.stopPrank();
    }
    
    // ============ Exchange Rate Tests ============
    
    function test_SetCeloExchangeRate() public {
        uint256 newRate = 2 ether; // New rate: 2 CELO = 30 PASS
        
        vm.startPrank(owner);
        swap.setCeloExchangeRate(newRate);
        vm.stopPrank();
        
        assertEq(swap.celoExchangeRate(), newRate, "CELO exchange rate should be updated");
    }
    
    function test_SetCusdExchangeRate() public {
        uint256 newRate = 34 * 10**16; // New rate: 0.34 cUSD = 30 PASS
        
        vm.startPrank(owner);
        swap.setCusdExchangeRate(newRate);
        vm.stopPrank();
        
        assertEq(swap.cusdExchangeRate(), newRate, "cUSD exchange rate should be updated");
    }
    
    function test_RevertWhen_SetCeloExchangeRate_Zero() public {
        vm.startPrank(owner);
        vm.expectRevert("Exchange rate must be greater than zero");
        swap.setCeloExchangeRate(0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_SetCusdExchangeRate_Zero() public {
        vm.startPrank(owner);
        vm.expectRevert("Exchange rate must be greater than zero");
        swap.setCusdExchangeRate(0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_SetCeloExchangeRate_NonOwner() public {
        vm.startPrank(buyer);
        vm.expectRevert();
        swap.setCeloExchangeRate(2 ether);
        vm.stopPrank();
    }
    
    function test_RevertWhen_SetCusdExchangeRate_NonOwner() public {
        vm.startPrank(buyer);
        vm.expectRevert();
        swap.setCusdExchangeRate(34 * 10**16);
        vm.stopPrank();
    }
    
    // ============ Event Tests ============
    
    function test_TokensPurchasedEvent_CELO() public {
        uint256 celoAmount = 1 ether;
        
        vm.deal(buyer, celoAmount);
        
        vm.startPrank(buyer);
        vm.expectEmit(true, false, false, true);
        emit GamePassSwap.TokensPurchased(buyer, THIRTY_PASS, "CELO");
        swap.buyTokens{value: celoAmount}();
        vm.stopPrank();
    }
    
    function test_TokensPurchasedEvent_cUSD() public {
        uint256 cusdAmount = 17 * 10**16;
        
        vm.startPrank(buyer);
        cusd.approve(address(swap), cusdAmount);
        vm.expectEmit(true, false, false, true);
        emit GamePassSwap.TokensPurchased(buyer, THIRTY_PASS, "cUSD");
        swap.buyTokensWithCUSD(cusdAmount);
        vm.stopPrank();
    }
    
    function test_CeloExchangeRateUpdatedEvent() public {
        uint256 newRate = 2 ether;
        
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit GamePassSwap.CeloExchangeRateUpdated(1 ether, newRate);
        swap.setCeloExchangeRate(newRate);
        vm.stopPrank();
    }
    
    function test_CusdExchangeRateUpdatedEvent() public {
        uint256 newRate = 34 * 10**16;
        
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit GamePassSwap.CusdExchangeRateUpdated(17 * 10**16, newRate);
        swap.setCusdExchangeRate(newRate);
        vm.stopPrank();
    }
    
    // ============ Withdrawal Tests ============
    
    function test_WithdrawCELO() public {
        uint256 celoAmount = 1 ether;
        
        vm.deal(buyer, celoAmount);
        vm.prank(buyer);
        swap.buyTokens{value: celoAmount}();
        
        uint256 contractBalance = address(swap).balance;
        
        vm.prank(owner);
        swap.withdrawCELO();
        
        assertEq(address(swap).balance, 0, "Contract balance should be zero");
    }
    
    function test_WithdrawCUSD() public {
        uint256 cusdAmount = 17 * 10**16;
        
        vm.startPrank(buyer);
        cusd.approve(address(swap), cusdAmount);
        swap.buyTokensWithCUSD(cusdAmount);
        vm.stopPrank();
        
        vm.prank(owner);
        swap.withdrawCUSD();
        
        assertEq(cusd.balanceOf(address(swap)), 0, "Contract balance should be zero");
    }
    
    function test_RevertWhen_WithdrawCELO_NonOwner() public {
        vm.startPrank(buyer);
        vm.expectRevert();
        swap.withdrawCELO();
        vm.stopPrank();
    }
    
    function test_RevertWhen_WithdrawCUSD_NonOwner() public {
        vm.startPrank(buyer);
        vm.expectRevert();
        swap.withdrawCUSD();
        vm.stopPrank();
    }
    
    // ============ Minimum Purchase Tests ============
    
    function test_SetMinCeloPurchase() public {
        uint256 newMin = 2 * 10**16; // 0.02 CELO
        
        vm.startPrank(owner);
        swap.setMinCeloPurchase(newMin);
        vm.stopPrank();
        
        assertEq(swap.minCeloPurchase(), newMin, "Minimum CELO purchase should be updated");
    }
    
    function test_SetMinCusdPurchase() public {
        uint256 newMin = 2 * 10**16; // 0.02 cUSD
        
        vm.startPrank(owner);
        swap.setMinCusdPurchase(newMin);
        vm.stopPrank();
        
        assertEq(swap.minCusdPurchase(), newMin, "Minimum cUSD purchase should be updated");
    }
    
    function test_RevertWhen_SetMinCeloPurchase_NonOwner() public {
        vm.startPrank(buyer);
        vm.expectRevert();
        swap.setMinCeloPurchase(2 * 10**16);
        vm.stopPrank();
    }
    
    function test_RevertWhen_SetMinCusdPurchase_NonOwner() public {
        vm.startPrank(buyer);
        vm.expectRevert();
        swap.setMinCusdPurchase(2 * 10**16);
        vm.stopPrank();
    }
    
    // ============ Integration Tests ============
    
    function test_FullWorkflow() public {
        // Multiple CELO purchases
        vm.deal(buyer, 3 ether);
        vm.startPrank(buyer);
        swap.buyTokens{value: 1 ether}();
        swap.buyTokens{value: 1 ether}();
        swap.buyTokens{value: 1 ether}();
        vm.stopPrank();
        
        assertEq(token.balanceOf(buyer), THIRTY_PASS * 3, "Buyer should have 90 PASS tokens");
        
        // cUSD purchase
        vm.startPrank(buyer);
        cusd.approve(address(swap), 17 * 10**16);
        swap.buyTokensWithCUSD(17 * 10**16);
        vm.stopPrank();
        
        assertEq(token.balanceOf(buyer), THIRTY_PASS * 4, "Buyer should have 120 PASS tokens");
    }
}
