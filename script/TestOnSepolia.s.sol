// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/KipuBankV2.sol";

contract TestOnSepolia is Script {
    address constant KIPUBANK_ADDRESS = 0xaD0B6A54Af33fe4e5cC3cCf2Caa2Fe54B049Ac91;
    
    function run() external {
        require(KIPUBANK_ADDRESS != address(0), "Update KIPUBANK_ADDRESS first!");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        KipuBank kipuBank = KipuBank(payable(KIPUBANK_ADDRESS));
        
        console.log("\n=== KipuBank Contract Information ===");
        console.log("Contract Address:", address(kipuBank));
        console.log("Tester Address:", deployer);
        console.log("Tester Balance:", deployer.balance / 1e18, "ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("\n=== Test 1: Contract Info ===");
        uint256 maxUsdBankCap = kipuBank.maxUsdBankCap();
        uint256 usdWithdrawalLimit = kipuBank.usdWithdrawalLimit();
        uint256 depositCountBefore = kipuBank.depositCount();
        uint256 withdrawCountBefore = kipuBank.withdrawCount();
        
        console.log("Max USD Bank Cap:", maxUsdBankCap / 1e8, "USD");
        console.log("USD Withdrawal Limit:", usdWithdrawalLimit / 1e8, "USD");
        console.log("Deposit Count:", depositCountBefore);
        console.log("Withdraw Count:", withdrawCountBefore);
        
        console.log("\n=== Test 2: Deposit ETH ===");
        uint256 depositAmount = 0.001 ether;
        console.log("Depositing:", depositAmount / 1e18, "ETH");
        
        uint256 balanceBefore = deployer.balance;
        kipuBank.deposit{value: depositAmount}();
        uint256 balanceAfter = deployer.balance;
        uint256 depositCountAfter = kipuBank.depositCount();
        
        console.log("ETH spent:", (balanceBefore - balanceAfter) / 1e18, "ETH");
        console.log("Deposit Count After:", depositCountAfter);
        console.log("Success! Deposit count increased by:", depositCountAfter - depositCountBefore);
        
        console.log("\n=== Test 3: Withdraw ETH ===");
        uint256 withdrawAmount = 0.0005 ether;
        console.log("Withdrawing:", withdrawAmount / 1e18, "ETH");
        
        balanceBefore = deployer.balance;
        kipuBank.withdraw(withdrawAmount);
        balanceAfter = deployer.balance;
        uint256 withdrawCountAfter = kipuBank.withdrawCount();
        
        console.log("ETH received:", (balanceAfter - balanceBefore) / 1e18, "ETH");
        console.log("Withdraw Count After:", withdrawCountAfter);
        console.log("Success! Withdraw count increased by:", withdrawCountAfter - withdrawCountBefore);
        
        vm.stopBroadcast();
        
        console.log("\n=== All Tests Completed Successfully! ===");
    }
}
