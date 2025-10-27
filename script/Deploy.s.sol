// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/KipuBankV2.sol";

contract DeployKipuBank is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Price Feed do ETH/USD na Sepolia (Chainlink)
        address ethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        
        console.log("Deploying KipuBankV2 with:");
        console.log("ETH/USD Price Feed:", ethUsdPriceFeed);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);
        
        KipuBank kipuBank = new KipuBank(ethUsdPriceFeed);
        
        console.log("KipuBank deployed at:", address(kipuBank));
        console.log("Max USD Bank Cap:", kipuBank.maxUsdBankCap());
        console.log("USD Withdrawal Limit:", kipuBank.usdWithdrawalLimit());
        
        vm.stopBroadcast();
    }
}
