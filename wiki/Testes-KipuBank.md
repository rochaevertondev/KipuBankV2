# 🧪 Guia de Testes do KipuBank com Foundry

> Como escrever e entender testes em Solidity

---

## 🎯 O que é Foundry?

**Foundry** é um framework de desenvolvimento para Ethereum que permite:

- ✍️ Escrever testes em **Solidity** (não precisa JavaScript!)
- ⚡ Execução ultra-rápida (nativo em Rust)
- 🔍 Debugging avançado com traces
- 📊 Gas reports detalhados
- 🎭 Simular qualquer cenário (time travel, impersonation, etc.)

---

## 📁 Estrutura de Testes

```
test/
└── KipuBank.t.sol          # Arquivo de testes
    ├── MockV3Aggregator    # Mock do Chainlink Oracle
    └── KipuBankTest        # Contrato de testes
        ├── setUp()         # Preparação antes de cada teste
        ├── testDeposit()   # Teste 1
        ├── testWithdraw()  # Teste 2
        └── ...             # Mais testes
```

**Convenção:**
- Arquivos terminam com `.t.sol`
- Contratos de teste herdam de `Test`
- Funções de teste começam com `test`

---

## 🎭 Mock do Oracle (Chainlink)

### **O que é um Mock?**

Um **mock** é uma versão simplificada de um contrato real, usada apenas para testes.

**Por que precisamos?**

Em testes locais (Anvil/Foundry), não temos acesso ao Chainlink real da Sepolia. O mock simula o comportamento do oracle.

### **Implementação**

```solidity
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
```

**Características:**
- Retorna preço fixo (controlável)
- Sempre retorna dados válidos
- Função `setAnswer()` permite mudar o preço durante testes

**Exemplo de uso:**
```solidity
// Criar mock com ETH = $2000
MockV3Aggregator priceFeed = new MockV3Aggregator(8, 2000 * 10**8);

// Mudar preço para $3000 no meio do teste
priceFeed.setAnswer(3000 * 10**8);
```

---

## 🧩 Estrutura do Contrato de Teste

```solidity
import "forge-std/Test.sol";
import "../src/KipuBankV2.sol";

contract KipuBankTest is Test {
    // Contratos que serão testados
    KipuBank public bank;
    MockV3Aggregator public priceFeed;
    
    // Endereços de teste
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    // setUp() roda antes de cada teste
    function setUp() public {
        // Preparação aqui
    }
    
    // Cada função test* é um teste independente
    function testDeposit() public {
        // Teste aqui
    }
}
```

### **Por que herdar de `Test`?**

`Test` (de `forge-std`) fornece:
- **Assertions**: `assertEq`, `assertTrue`, `assertGt`, etc.
- **VM Cheats**: `vm.prank`, `vm.deal`, `vm.expectRevert`, etc.
- **Console logs**: `console.log` para debugging

---

## 🔧 Função setUp()

```solidity
function setUp() public {
    // 1. Deploy mock price feed com ETH = $2000 (8 decimals)
    priceFeed = new MockV3Aggregator(8, 2000 * 10**8);
    
    // 2. Deploy KipuBank
    bank = new KipuBank(address(priceFeed));
    
    // 3. Dar ETH para os usuários de teste
    vm.deal(user1, 100 ether);
    vm.deal(user2, 100 ether);
}
```

**O que acontece:**

1. **Cria o mock** com preço fixo de $2000
2. **Deploy do KipuBank** apontando para o mock
3. **Distribui ETH** para endereços de teste

**`vm.deal()`**: Cheatcode que "magicamente" dá ETH para qualquer endereço (só funciona em testes!)

**Importante:** `setUp()` roda **antes de cada teste**. Cada teste começa com estado limpo!

```
Test 1: setUp() → testDeposit() → ✅
Test 2: setUp() → testWithdraw() → ✅  (estado resetado!)
Test 3: setUp() → testFail() → ✅
```

---

## 🎨 Padrão AAA (Arrange-Act-Assert)

Todos os testes seguem este padrão:

```solidity
function testExemplo() public {
    // ARRANGE (Preparar)
    // - Configurar dados
    // - Definir variáveis
    // - Preparar estado inicial
    
    // ACT (Agir)
    // - Executar a função que está sendo testada
    
    // ASSERT (Verificar)
    // - Verificar se o resultado está correto
}
```

---

## 🧪 Teste 1: Depósito Básico

```solidity
function testDeposit() public {
    // ========== ARRANGE ==========
    uint256 depositAmount = 1 ether;
    
    // ========== ACT ==========
    vm.prank(user1);  // Próxima tx vem de user1
    bank.deposit{value: depositAmount}();
    
    // ========== ASSERT ==========
    vm.prank(user1);  // user1 consulta seu saldo
    uint256 balance = bank.getBalance(user1);
    assertEq(balance, depositAmount, "Saldo incorreto apos deposito");
}
```

### **Explicação linha por linha:**

```solidity
uint256 depositAmount = 1 ether;
```
Define quantidade a depositar (1 ETH = 10^18 wei)

```solidity
vm.prank(user1);
```
**Cheatcode mágico!** Faz a próxima transação parecer que veio de `user1`.

**Analogia:** É como "se passar por" outro usuário (só funciona em testes)

```solidity
bank.deposit{value: depositAmount}();
```
Chama função `deposit()` enviando 1 ETH junto.

```solidity
vm.prank(user1);
uint256 balance = bank.getBalance(user1);
```
user1 consulta seu próprio saldo (precisa de prank porque função é restrita)

```solidity
assertEq(balance, depositAmount, "Saldo incorreto");
```
**Assertion:** Verifica se `balance == depositAmount`

Se falhar, teste falha com mensagem "Saldo incorreto"

### **Fluxo do teste:**

```
1. setUp() → priceFeed criado com $2000
2. setUp() → bank criado
3. setUp() → user1 recebe 100 ETH
4. testDeposit() → user1 deposita 1 ETH
5. testDeposit() → verifica saldo = 1 ETH
6. ✅ PASS
```

---

## 🧪 Teste 2: Saque Válido

```solidity
function testWithdraw() public {
    // ========== ARRANGE ==========
    // user1 deposita 2 ETH primeiro
    vm.prank(user1);
    bank.deposit{value: 2 ether}();
    
    // ========== ACT ==========
    // user1 retira 0.5 ETH ($1000 USD com preço de $2000/ETH)
    uint256 withdrawAmount = 0.5 ether;
    vm.prank(user1);
    bank.withdraw(withdrawAmount);
    
    // ========== ASSERT ==========
    // Verifica saldo atualizado: 2 - 0.5 = 1.5 ETH
    vm.prank(user1);
    uint256 balance = bank.getBalance(user1);
    assertEq(balance, 1.5 ether, "Saldo incorreto apos saque");
}
```

### **Cálculo USD:**

```
ETH Price: $2000
Withdraw: 0.5 ETH
USD Value: 0.5 × $2000 = $1000 ✅ (dentro do limite de $1000)
```

### **Fluxo:**

```
1. setUp() → estado limpo
2. user1 deposita 2 ETH → saldo = 2 ETH
3. user1 saca 0.5 ETH → saldo = 1.5 ETH
4. Verifica saldo = 1.5 ETH
5. ✅ PASS
```

---

## 🧪 Teste 3: Saque Excede Limite

```solidity
function testWithdrawExceedsLimit() public {
    // ========== ARRANGE ==========
    // user1 deposita 3 ETH (dentro do cap de $10k)
    vm.prank(user1);
    bank.deposit{value: 3 ether}();
    
    // ========== ACT & ASSERT ==========
    // Tentar sacar mais que o limite USD (>$1000)
    // Com ETH a $2000, 0.6 ETH = $1200, deve reverter
    vm.prank(user1);
    vm.expectRevert();  // Espera que a próxima tx falhe!
    bank.withdraw(0.6 ether);
}
```

### **`vm.expectRevert()`**

**O que faz:**
- Diz ao Foundry: "a próxima transação DEVE falhar"
- Se não falhar, o teste falha!

**Uso:**
```solidity
vm.expectRevert();  // Espera qualquer revert
bank.withdraw(0.6 ether);  // Esta chamada deve falhar

// Ou especificar o erro esperado:
vm.expectRevert(abi.encodeWithSignature("ExceedsUsdLimit(uint256,uint256)", 120000000000, 100000000000));
bank.withdraw(0.6 ether);
```

### **Cálculo:**

```
ETH Price: $2000
Withdraw: 0.6 ETH
USD Value: 0.6 × $2000 = $1200
Limit: $1000
Result: $1200 > $1000 → ❌ REVERT
```

### **Por que este teste é importante?**

Garante que o limite de segurança funciona corretamente!

---

## 🧪 Teste 4: Contador de Depósitos

```solidity
function testDepositCount() public {
    // ========== ACT ==========
    // Fazer 3 depósitos de usuários diferentes
    
    vm.prank(user1);
    bank.deposit{value: 1 ether}();    // depositCount = 1
    
    vm.prank(user2);
    bank.deposit{value: 2 ether}();    // depositCount = 2
    
    vm.prank(user1);
    bank.deposit{value: 0.5 ether}();  // depositCount = 3
    
    // ========== ASSERT ==========
    // Verifica contador
    assertEq(bank.depositCount(), 3, "Contador de depositos incorreto");
}
```

### **O que testa:**

Verifica se `depositCount++` está funcionando corretamente.

### **Variações possíveis:**

```solidity
// Testar depositCount e withdrawCount juntos
vm.prank(user1);
bank.deposit{value: 1 ether}();  // depositCount = 1

vm.prank(user1);
bank.withdraw(0.5 ether);         // withdrawCount = 1

assertEq(bank.depositCount(), 1);
assertEq(bank.withdrawCount(), 1);
```

---

## 🛠️ Cheatcodes do Foundry

### **vm.prank(address)**

Faz a próxima transação vir de `address`.

```solidity
vm.prank(alice);
bank.deposit{value: 1 ether}();  // msg.sender = alice

bank.deposit{value: 1 ether}();  // msg.sender = address(this)
```

### **vm.startPrank(address)**

Todas as transações vêm de `address` até `vm.stopPrank()`.

```solidity
vm.startPrank(alice);
bank.deposit{value: 1 ether}();   // msg.sender = alice
bank.withdraw(0.5 ether);          // msg.sender = alice
vm.stopPrank();

bank.deposit{value: 1 ether}();   // msg.sender = address(this)
```

### **vm.deal(address, uint256)**

Dá ETH para um endereço.

```solidity
vm.deal(alice, 100 ether);  // Alice agora tem 100 ETH
```

### **vm.expectRevert()**

Espera que a próxima transação reverta.

```solidity
vm.expectRevert();
bank.withdraw(1000 ether);  // Deve falhar
```

### **vm.expectEmit()**

Verifica se um evento foi emitido.

```solidity
vm.expectEmit(true, true, false, true);
emit SuccessfulDeposit(alice, ETH_ADDRESS, 1 ether, 1 ether, 200000000000);

vm.prank(alice);
bank.deposit{value: 1 ether}();
```

**Parâmetros:**
- `true, true, false, true`: quais campos indexed verificar + data

### **vm.warp(uint256)**

Avança o tempo da blockchain.

```solidity
vm.warp(block.timestamp + 1 hours);  // Avança 1 hora
```

**Uso:** Testar limites de tempo (ex: oracle stale após 1 hora)

```solidity
// Deploy com preço $2000
priceFeed = new MockV3Aggregator(8, 2000 * 10**8);
bank = new KipuBank(address(priceFeed));

// Avançar 2 horas
vm.warp(block.timestamp + 2 hours);

// Agora getEthPrice() deve reverter (StalePrice)
vm.expectRevert();
bank.getEthPrice();
```

### **vm.roll(uint256)**

Avança o número do bloco.

```solidity
vm.roll(block.number + 100);  // Avança 100 blocos
```

---

## 📊 Assertions Comuns

### **assertEq**

Verifica igualdade.

```solidity
assertEq(a, b);                    // uint, int
assertEq(a, b, "mensagem");        // com mensagem
assertEq(addr1, addr2);            // address
```

### **assertTrue / assertFalse**

```solidity
assertTrue(bank.hasRole(ADMIN_ROLE, alice));
assertFalse(bank.hasRole(ADMIN_ROLE, bob));
```

### **assertGt / assertGe**

Greater than / Greater or equal.

```solidity
assertGt(balance, 0);        // balance > 0
assertGe(balance, 1 ether);  // balance >= 1 ether
```

### **assertLt / assertLe**

Less than / Less or equal.

```solidity
assertLt(usdValue, 1000 * 10**8);  // usdValue < $1000
```

---

## 🎯 Exemplo Completo: Teste de Limite de Cap

```solidity
function testBankCap() public {
    // ========== ARRANGE ==========
    // Bank cap = $10,000
    // ETH price = $2000
    // Max ETH depositável = $10,000 / $2000 = 5 ETH
    
    // ========== ACT ==========
    // Depositar 5 ETH (exatamente no limite)
    vm.prank(user1);
    bank.deposit{value: 5 ether}();  // $10,000 USD ✅
    
    // ========== ASSERT ==========
    // Tentar depositar mais 0.1 ETH deve falhar
    vm.prank(user2);
    vm.expectRevert();  // Espera MaxBankCapReached
    bank.deposit{value: 0.1 ether}();  // $200 excede cap
    
    // Verificar que total USD = $10,000
    uint256 totalUsd = bank.totalBankUsd();
    assertEq(totalUsd, 10000 * 10**8, "Total USD incorreto");
}
```

### **Lógica:**

```
Cap do banco: $10,000
ETH price: $2000

user1 deposita 5 ETH:
5 ETH × $2000 = $10,000 ✅ (exatamente no limite)

user2 tenta depositar 0.1 ETH:
0.1 ETH × $2000 = $200
Total seria: $10,000 + $200 = $10,200
$10,200 > $10,000 → ❌ REVERT (MaxBankCapReached)
```

---

## 🎯 Exemplo Completo: Teste de Price Feed Stale

```solidity
function testStalePriceFeed() public {
    // ========== ARRANGE ==========
    // Criar banco com preço válido
    priceFeed = new MockV3Aggregator(8, 2000 * 10**8);
    bank = new KipuBank(address(priceFeed));
    
    // ========== ACT ==========
    // Avançar tempo além de MAX_ORACLE_AGE (1 hora)
    vm.warp(block.timestamp + 2 hours);
    
    // ========== ASSERT ==========
    // getEthPrice() deve reverter com StalePrice
    vm.expectRevert();
    bank.getEthPrice();
}
```

**Testa:** Validação de staleness do oracle

---

## 🎯 Exemplo Completo: Teste de Admin Recovery

```solidity
function testAdminRecovery() public {
    // ========== ARRANGE ==========
    // user1 deposita 5 ETH
    vm.prank(user1);
    bank.deposit{value: 5 ether}();
    
    // Owner adiciona admin
    address admin = address(0x999);
    bank.addAdmin(admin);
    
    // ========== ACT ==========
    // Admin ajusta saldo de user1 para 3 ETH
    vm.prank(admin);
    bank.recoverUserBalance(bank.ETH_ADDRESS(), user1, 3 ether);
    
    // ========== ASSERT ==========
    // Verificar novo saldo
    vm.prank(user1);
    uint256 newBalance = bank.getBalance(user1);
    assertEq(newBalance, 3 ether, "Saldo nao foi ajustado");
    
    // Verificar que total USD foi atualizado
    // 5 ETH - 3 ETH = 2 ETH removidos
    // 2 ETH × $2000 = $4000 removidos
    uint256 totalUsd = bank.totalBankUsd();
    assertEq(totalUsd, 6000 * 10**8, "Total USD incorreto");
}
```

---

## 🔍 Comandos do Foundry

### **Compilar**

```bash
forge build
```

Compila todos os contratos em `src/` e `test/`.

---

### **Rodar Testes**

```bash
# Todos os testes
forge test

# Com verbosidade (mostra mais detalhes)
forge test -vv      # Level 2
forge test -vvv     # Level 3
forge test -vvvv    # Level 4 (traces completos)

# Teste específico
forge test --match-test testDeposit

# Contrato específico
forge test --match-contract KipuBankTest
```

---

### **Gas Report**

```bash
forge test --gas-report
```

Mostra quanto gás cada função usa:

```
| Function        | Gas     |
|-----------------|---------|
| deposit         | 195977  |
| withdraw        | 238412  |
| depositToken    | 312456  |
```

---

### **Coverage**

```bash
forge coverage
```

Mostra qual % do código foi testado:

```
| File              | % Lines  | % Statements | % Branches |
|-------------------|----------|--------------|------------|
| KipuBankV2.sol    | 95.24%   | 94.87%       | 85.71%     |
```

---

### **Snapshot**

```bash
forge snapshot
```

Salva gas usado em `.gas-snapshot` para comparações futuras.

---

### **Formatar Código**

```bash
forge fmt
```

Formata automaticamente todos os arquivos `.sol`.

---

## 🎨 Exemplo de Output (forge test -vv)

```
[⠊] Compiling...
No files changed, compilation skipped

Running 4 tests for test/KipuBank.t.sol:KipuBankTest
[PASS] testDeposit() (gas: 195977)
[PASS] testDepositCount() (gas: 249717)
[PASS] testWithdraw() (gas: 238412)
[PASS] testWithdrawExceedsLimit() (gas: 201155)
Test result: ok. 4 passed; 0 failed; finished in 795.37µs
```

**Interpretação:**
- ✅ Todos os 4 testes passaram
- Gas usado por cada teste
- Tempo total: 795 microsegundos

---

## 🎨 Exemplo de Trace (forge test -vvvv)

```
[PASS] testDeposit() (gas: 195977)
Traces:
  [195977] KipuBankTest::testDeposit()
    ├─ [0] VM::prank(0x0000000000000000000000000000000000000001)
    │   └─ ← ()
    ├─ [168024] KipuBank::deposit{value: 1000000000000000000}()
    │   ├─ [6605] MockV3Aggregator::latestRoundData() [staticcall]
    │   │   └─ ← 1, 200000000000, 1, 1, 1
    │   ├─ [2278] MockV3Aggregator::decimals() [staticcall]
    │   │   └─ ← 8
    │   ├─ emit SuccessfulDeposit(...)
    │   └─ ← ()
    ├─ [0] VM::prank(0x0000000000000000000000000000000000000001)
    │   └─ ← ()
    ├─ [2451] KipuBank::getBalance(0x0000000000000000000000000000000000000001)
    │   └─ ← 1000000000000000000
    └─ ← ()
```

**Interpretação:**
- Cada `├─` é uma chamada de função
- `[168024]` é o gás usado
- `staticcall` = view function
- `←` = return value

---

## 📚 Boas Práticas

### **1. Um teste por conceito**

```solidity
// ❌ Ruim: testa múltiplas coisas
function testEverything() public {
    bank.deposit{value: 1 ether}();
    bank.withdraw(0.5 ether);
    bank.addAdmin(alice);
    // ...
}

// ✅ Bom: um conceito por teste
function testDeposit() public { ... }
function testWithdraw() public { ... }
function testAddAdmin() public { ... }
```

---

### **2. Nomes descritivos**

```solidity
// ❌ Ruim
function test1() public { ... }
function testFail() public { ... }

// ✅ Bom
function testDepositIncreasesBalance() public { ... }
function testWithdrawRevertsIfExceedsLimit() public { ... }
```

---

### **3. Sempre use mensagens em assertions**

```solidity
// ❌ Ruim
assertEq(balance, 1 ether);

// ✅ Bom
assertEq(balance, 1 ether, "Balance should be 1 ETH after deposit");
```

---

### **4. Teste edge cases**

```solidity
function testDepositZeroReverts() public {
    vm.expectRevert();
    bank.deposit{value: 0}();
}

function testWithdrawMoreThanBalanceReverts() public {
    vm.prank(user1);
    bank.deposit{value: 1 ether}();
    
    vm.prank(user1);
    vm.expectRevert();
    bank.withdraw(2 ether);  // Mais que o saldo
}
```

---

### **5. Use setUp() para código repetido**

```solidity
// ❌ Ruim: repete em cada teste
function testA() public {
    priceFeed = new MockV3Aggregator(8, 2000 * 10**8);
    bank = new KipuBank(address(priceFeed));
    vm.deal(user1, 100 ether);
    // ...
}

function testB() public {
    priceFeed = new MockV3Aggregator(8, 2000 * 10**8);
    bank = new KipuBank(address(priceFeed));
    vm.deal(user1, 100 ether);
    // ...
}

// ✅ Bom: setup único
function setUp() public {
    priceFeed = new MockV3Aggregator(8, 2000 * 10**8);
    bank = new KipuBank(address(priceFeed));
    vm.deal(user1, 100 ether);
}

function testA() public { ... }
function testB() public { ... }
```

---

## 🎓 Exercícios Práticos

Tente implementar estes testes:

### **1. Teste de depósito de token ERC-20**

```solidity
function testDepositToken() public {
    // TODO: 
    // 1. Criar mock de token ERC-20
    // 2. Dar tokens para user1
    // 3. user1 aprova bank
    // 4. user1 deposita tokens
    // 5. Verificar saldo
}
```

### **2. Teste de múltiplos usuários**

```solidity
function testMultipleUsersDeposit() public {
    // TODO:
    // 1. user1 deposita 2 ETH
    // 2. user2 deposita 3 ETH
    // 3. Verificar saldo de cada um
    // 4. Verificar total USD = $10,000
}
```

### **3. Teste de evento**

```solidity
function testDepositEmitsEvent() public {
    // TODO:
    // 1. Usar vm.expectEmit()
    // 2. Definir evento esperado
    // 3. Executar deposit
    // 4. Verificar que evento foi emitido
}
```

---

## ✅ Checklist de Compreensão

Você entendeu quando conseguir:

- [ ] Criar um mock de contrato externo
- [ ] Usar `setUp()` corretamente
- [ ] Escrever testes com padrão AAA
- [ ] Usar `vm.prank()` e `vm.deal()`
- [ ] Testar reverts com `vm.expectRevert()`
- [ ] Escrever assertions com mensagens
- [ ] Interpretar output de `forge test -vv`
- [ ] Testar eventos com `vm.expectEmit()`
- [ ] Avançar tempo com `vm.warp()`
- [ ] Medir gas usage

---

## 📚 Recursos Adicionais

- **Foundry Book**: https://book.getfoundry.sh/
- **Forge Std Reference**: https://book.getfoundry.sh/reference/forge-std/
- **Cheatcodes Reference**: https://book.getfoundry.sh/cheatcodes/
- **Testing Best Practices**: https://book.getfoundry.sh/tutorials/best-practices

---

**Leitura anterior:** [Contrato KipuBank](./Contrato-KipuBank.md)
