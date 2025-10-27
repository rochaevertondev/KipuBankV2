// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KipuBankV2.sol";

// Mock do Chainlink Price Feed para testes
contract MockV3Aggregator {
    uint8 public decimals;
    int256 private _answer;
    uint256 private _updatedAt;
    uint80 private _roundId;

    constructor(uint8 _decimals, int256 initialAnswer) {
        decimals = _decimals;
        _answer = initialAnswer;
        _updatedAt = block.timestamp;
        _roundId = 1;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, _answer, block.timestamp, _updatedAt, _roundId);
    }

    function setAnswer(int256 newAnswer) external {
        _answer = newAnswer;
        _updatedAt = block.timestamp;
        _roundId++;
    }
}

contract KipuBankTest is Test {
    KipuBank public bank;
    MockV3Aggregator public priceFeed;
    
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    // Eventos para teste
    event SuccessfulDeposit(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 newBalance,
        uint256 usdValue
    );
    
    function setUp() public {
        // Setup: Deploy mock price feed com ETH = $2000 (8 decimals)
        priceFeed = new MockV3Aggregator(8, 2000 * 10**8);
        
        // Setup: Deploy KipuBank
        bank = new KipuBank(address(priceFeed));
        
        // Setup: Dar ETH para os usuários de teste
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }
    
    function testDeposit() public {
        // Arrange: user1 vai depositar 1 ETH
        uint256 depositAmount = 1 ether;
        
        // Act: user1 deposita
        vm.prank(user1);
        bank.deposit{value: depositAmount}();
        
        // Assert: verificar saldo
        vm.prank(user1);
        uint256 balance = bank.getBalance(user1);
        assertEq(balance, depositAmount, "Saldo incorreto apos deposito");
    }
    
    function testWithdraw() public {
        // Arrange: user1 deposita 2 ETH
        vm.prank(user1);
        bank.deposit{value: 2 ether}();
        
        // Act: user1 retira 0.5 ETH ($1000 USD com preco de $2000/ETH)
        uint256 withdrawAmount = 0.5 ether;
        vm.prank(user1);
        bank.withdraw(withdrawAmount);
        
        // Assert: verificar saldo atualizado
        vm.prank(user1);
        uint256 balance = bank.getBalance(user1);
        assertEq(balance, 1.5 ether, "Saldo incorreto apos saque");
    }
    
    function testWithdrawExceedsLimit() public {
        // Arrange: user1 deposita 3 ETH (dentro do cap de $10k)
        vm.prank(user1);
        bank.deposit{value: 3 ether}();
        
        // Act & Assert: tentar sacar mais que o limite USD (>$1000)
        // Com ETH a $2000, 0.6 ETH = $1200, deve reverter
        vm.prank(user1);
        vm.expectRevert(); // Espera que reverta
        bank.withdraw(0.6 ether);
    }
    
    function testDepositCount() public {
        // Act: fazer 3 depositos
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        // Assert: verificar contador
        assertEq(bank.depositCount(), 3, "Contador de depositos incorreto");
    }
}
