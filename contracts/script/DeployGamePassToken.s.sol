// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {GamePassToken} from "../src/GamePassToken.sol";

contract DeployGamePassToken is Script {
    function run() external returns (GamePassToken) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        GamePassToken token = new GamePassToken(
            "GamePass Token",
            "PASS",
            treasury
        );
        
        vm.stopBroadcast();
        
        return token;
    }
}

