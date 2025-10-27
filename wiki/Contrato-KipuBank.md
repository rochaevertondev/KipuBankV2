# 📘 Entendendo o Contrato KipuBank

> Guia completo para iniciantes em Solidity

---

## 🎯 O que é o KipuBank?

O **KipuBank** é um contrato inteligente que funciona como um **banco descentralizado** na blockchain Ethereum. Ele permite que usuários:

- 💰 Depositem ETH e tokens ERC-20
- 💸 Saquem seus fundos com limites de segurança
- 📊 Vejam seus saldos em dólares (USD)
- 🛡️ Tenham proteção contra ataques e fraudes

---

## 🏗️ Arquitetura do Contrato

### **Dependências**

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
```

**OpenZeppelin** é uma biblioteca de contratos auditados e seguros que fornece:
- `AccessControl`: Sistema de permissões (roles)
- `IERC20`: Interface padrão para tokens
- `SafeERC20`: Transferências seguras de tokens
- `ReentrancyGuard`: Proteção contra ataques de reentrância

---

## 🔌 Interface do Oracle (Chainlink)

```solidity
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
```

### **O que é um Oracle?**

Um **oracle** é uma ponte entre a blockchain e o mundo real. O Chainlink fornece dados de preços (ex: ETH/USD) de forma descentralizada.

**Exemplo:**
```
Chainlink Oracle → ETH/USD = $2,000
```

### **Por que `latestRoundData()`?**

Retorna **5 valores**:
1. `roundId`: ID da rodada de preços
2. `answer`: O preço (ex: 2000_00000000 = $2000 com 8 decimals)
3. `startedAt`: Quando começou
4. `updatedAt`: Última atualização
5. `answeredInRound`: Round que foi respondido

**Validações de segurança:**
```solidity
if (answer <= 0) revert InvalidPrice(answer);           // Preço não pode ser negativo
if (answeredInRound < roundId) revert StalePrice();     // Dados não podem estar antigos
if (block.timestamp - updatedAt > 1 hour) revert;      // Máximo 1 hora de atraso
```

---

## 📦 Variáveis de Estado

### **Constantes**

```solidity
// Endereço placeholder para ETH (EIP-7528)
address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// Idade máxima do oracle: 1 hora
uint256 public constant MAX_ORACLE_AGE = 1 hours;
```

**Por que `0xEeee...EEeE`?**
- É um endereço especial para representar ETH nativo
- Padrão EIP-7528 para compatibilidade

### **Imutáveis (Immutable)**

```solidity
// Limite máximo do banco em USD (8 decimais)
uint256 public immutable maxUsdBankCap = 10000 * 10**8;  // $10,000

// Limite por saque em USD (8 decimais)
uint256 public immutable usdWithdrawalLimit = 1000 * 10**8;  // $1,000

// Dono do banco
address public immutable ownerBank;
```

**Imutável significa:**
- Definido no `constructor`
- Não pode ser alterado depois
- Mais eficiente em gás que variáveis normais

### **Variáveis de Estado**

```solidity
// Oracle principal (ETH/USD)
AggregatorV3Interface public priceFeed;

// Limite de wei por transação (0 = sem limite)
uint256 public nativePerTxCapWei;

// Contadores
uint256 public depositCount;
uint256 public withdrawCount;

// Cache do total em USD (O(1) lookup)
uint256 private _totalBankUsdCache;
```

---

## 🗂️ Mapeamentos (Mappings)

### **Saldos por Token e Usuário**

```solidity
mapping(address => mapping(address => uint256)) private _balances;
```

**Como funciona:**
```solidity
// _balances[token][usuario] = quantidade

// Exemplo:
_balances[ETH_ADDRESS][0xABC...] = 5 ether;  // Alice tem 5 ETH
_balances[USDC_ADDRESS][0xABC...] = 1000;    // Alice tem 1000 USDC
```

**Analogia:** É como uma planilha Excel com duas dimensões:
- **Linha**: Token (ETH, USDC, LINK, etc.)
- **Coluna**: Usuário (endereço)
- **Célula**: Quantidade

### **Total de Cada Token**

```solidity
mapping(address => uint256) private _tokenTotals;
```

**Exemplo:**
```solidity
_tokenTotals[ETH_ADDRESS] = 100 ether;  // Banco tem 100 ETH no total
_tokenTotals[USDC] = 50000;             // Banco tem 50,000 USDC no total
```

### **Price Feeds por Token**

```solidity
mapping(address => AggregatorV3Interface) public tokenPriceFeed;
```

Cada token pode ter seu próprio oracle:
- ETH → 0x694AA... (ETH/USD Sepolia)
- LINK → 0xc59E3... (LINK/USD Sepolia)

---

## 🎭 Sistema de Roles (Papéis)

```solidity
bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
```

### **OWNER_ROLE**

**Quem:** O deployer (quem criou o contrato)

**Permissões:**
- Adicionar/remover admins
- Configurar price feeds de tokens
- Alterar limite de wei por transação
- Ver saldo total do banco

### **ADMIN_ROLE**

**Quem:** Endereços autorizados pelo OWNER

**Permissões:**
- Recuperar saldos de usuários (emergência)
- Ver saldos de qualquer usuário

**Exemplo de uso:**
```solidity
// Owner adiciona um admin
bank.addAdmin(0x123...);

// Admin recupera saldo de usuário
bank.recoverUserBalance(token, usuario, novoSaldo);
```

---

## 💰 Funções Principais

### **1. Depositar ETH**

```solidity
function deposit() external payable nonReentrant
```

**Fluxo:**

```
1. Usuário → Envia ETH junto com a transação
2. Contrato → Valida que msg.value > 0
3. Contrato → Converte ETH para USD via Chainlink
4. Contrato → Verifica se não excede maxUsdBankCap
5. Contrato → Atualiza _balances[ETH_ADDRESS][usuario]
6. Contrato → Incrementa depositCount
7. Contrato → Emite evento SuccessfulDeposit
```

**Exemplo de uso:**
```javascript
// JavaScript/ethers.js
await bank.deposit({ value: ethers.parseEther("1.0") });
```

**Exemplo em Solidity:**
```solidity
// Chamando de outro contrato
bank.deposit{value: 1 ether}();
```

**Cálculo USD:**
```solidity
// Se ETH = $2000 e usuário deposita 1 ETH:
uint256 ethPrice = 2000 * 10**8;  // $2000 com 8 decimals
uint256 weiAmount = 1 ether;       // 1e18 wei

uint256 usdValue = (ethPrice * weiAmount) / 1e18;
// usdValue = (2000 * 10**8 * 1e18) / 1e18
// usdValue = 2000 * 10**8 = $2000 em USD (8 decimals)
```

---

### **2. Sacar ETH**

```solidity
function withdraw(uint256 amount) external nonReentrant
```

**Fluxo (CEI Pattern):**

```
CHECKS (Verificações):
1. ✅ amount > 0
2. ✅ Usuário tem saldo suficiente
3. ✅ Valor em USD não excede $1000
4. ✅ Se nativePerTxCapWei > 0, amount não excede

EFFECTS (Efeitos):
5. 📝 Atualiza _balances[ETH_ADDRESS][usuario] -= amount
6. 📝 Atualiza _tokenTotals[ETH_ADDRESS] -= amount
7. 📝 Atualiza _totalBankUsdCache -= usdValue
8. 📝 Incrementa withdrawCount

INTERACTIONS (Interações):
9. 💸 Envia ETH para msg.sender
10. 📢 Emite evento SuccessfulWithdrawal
```

**Por que CEI Pattern?**

Previne **ataques de reentrância**:

```solidity
// ❌ ERRADO (vulnerável):
(bool success, ) = msg.sender.call{value: amount}("");  // Envia ETH primeiro
_balances[ETH_ADDRESS][msg.sender] -= amount;           // Atualiza depois

// ✅ CORRETO (seguro):
_balances[ETH_ADDRESS][msg.sender] -= amount;           // Atualiza primeiro
(bool success, ) = msg.sender.call{value: amount}("");  // Envia depois
```

**Exemplo de ataque prevenido:**
1. Atacante chama `withdraw(1 ETH)`
2. Contrato envia 1 ETH (mas não atualizou saldo ainda)
3. Atacante recebe ETH → fallback function → chama `withdraw` novamente
4. Contrato ainda vê saldo antigo → envia mais 1 ETH
5. **Dinheiro drenado!**

Com CEI + `nonReentrant`, isso é impossível ✅

---

### **3. Depositar Token ERC-20**

```solidity
function depositToken(address token, uint256 amount) external nonReentrant
```

**Pré-requisito:**
```solidity
// Usuário DEVE aprovar primeiro (em outro contrato do token)
token.approve(addressDoBanco, amount);
```

**Fluxo:**

```
1. ✅ Verifica amount > 0
2. ✅ Calcula USD do token (via tokenPriceFeed[token])
3. ✅ Verifica cap do banco
4. 📊 Mede saldo ANTES: balanceBefore = token.balanceOf(address(this))
5. 💸 Transfere: token.safeTransferFrom(msg.sender, address(this), amount)
6. 📊 Mede saldo DEPOIS: balanceAfter = token.balanceOf(address(this))
7. 📝 Calcula received = balanceAfter - balanceBefore
8. 📝 Atualiza _balances[token][msg.sender] += received
9. 📢 Emite evento
```

**Por que medir before/after?**

Alguns tokens cobram **taxa na transferência** (fee-on-transfer):

```solidity
// Usuário envia 100 tokens
token.transferFrom(user, bank, 100);

// Mas o banco só recebe 98 (2% de taxa)
// Se não medir, o banco creditaria 100 (errado!)
```

Com balance delta, sempre credita o valor correto ✅

---

### **4. Sacar Token ERC-20**

```solidity
function withdrawToken(address token, uint256 amount) external nonReentrant
```

Similar ao `withdraw()`, mas para tokens:

```solidity
CHECKS:
- Saldo suficiente
- Valor em USD ≤ $1000

EFFECTS:
- Atualiza _balances[token][usuario]
- Atualiza _tokenTotals[token]
- Atualiza _totalBankUsdCache

INTERACTIONS:
- token.safeTransfer(msg.sender, amount)
```

---

## 🔍 Funções de Visualização

### **Ver Preço do ETH**

```solidity
function getEthPrice() public view returns (uint256)
```

**Retorna:** Preço ETH/USD com 8 decimais

**Exemplo:** `200000000000` = $2000.00

**Validações:**
- Preço > 0
- Dados não antigos (< 1 hora)
- Round válido

---

### **Converter Wei para USD**

```solidity
function weiToUsd(uint256 amountWei) public view returns (uint256 usdValue)
```

**Fórmula:**
```solidity
uint256 price = getEthPrice();  // Ex: 2000 * 10**8
usdValue = (price * amountWei) / 1e18;

// Exemplo com 0.5 ETH:
// price = 2000 * 10**8 = 200000000000
// amountWei = 0.5 ether = 5 * 10**17
// usdValue = (200000000000 * 5 * 10**17) / 10**18
// usdValue = 100000000000 = $1000 (8 decimals)
```

---

### **Ver Saldo**

```solidity
function getBalance(address account) external view returns (uint256)
```

**Restrição:** Só o dono da conta ou admins podem ver

**Uso:**
```solidity
// Usuário vê seu próprio saldo
uint256 meuSaldo = bank.getBalance(msg.sender);

// Admin vê saldo de qualquer um
uint256 saldoUser = bank.getBalance(0x123...);
```

---

### **Ver Saldo em USD**

```solidity
function getBalanceInUsd(address token, address account) external view returns (uint256)
```

Converte o saldo do token para USD:

```solidity
// Alice tem 2 ETH
// ETH = $2000
// Retorna: 400000000000 = $4000 (8 decimals)
```

---

### **Total do Banco em USD (O(1))**

```solidity
function totalBankUsd() public view returns (uint256)
```

**Retorna:** `_totalBankUsdCache`

**Por que cache?**

Sem cache (O(n)):
```solidity
// Teria que iterar todos os tokens
for (token in trackedTokens) {
    totalUsd += tokenAmountToUsd(token, _tokenTotals[token]);
}
```

Com cache (O(1)):
```solidity
// Retorna instantaneamente!
return _totalBankUsdCache;
```

O cache é atualizado em cada deposit/withdraw ✅

---

## 🔐 Funções Administrativas

### **Adicionar Admin**

```solidity
function addAdmin(address account) external onlyOwner
```

Apenas o OWNER pode adicionar admins.

---

### **Remover Admin**

```solidity
function removeAdmin(address account) external onlyOwner
```

Apenas o OWNER pode remover admins.

---

### **Recuperar Saldo de Usuário**

```solidity
function recoverUserBalance(
    address token,
    address account,
    uint256 newBalance
) external onlyRole(ADMIN_ROLE)
```

**Uso:** Emergências (usuário perdeu acesso, erro, etc.)

**Exemplo:**
```solidity
// Usuário tinha 5 ETH mas perdeu acesso à wallet
// Admin cria nova wallet e transfere saldo
bank.recoverUserBalance(ETH_ADDRESS, novaWallet, 5 ether);
```

**Segurança:** 
- Verifica que não excede maxUsdBankCap após recovery
- Emite evento AdminRecovery (auditável)

---

### **Configurar Price Feed de Token**

```solidity
function setTokenPriceFeed(address token, address aggregator) external onlyOwner
```

**Exemplo:**
```solidity
// Adicionar LINK/USD feed
address linkToken = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
address linkUsdFeed = 0xc59E3633BAAC79493d908e63626716e204A45EdF;

bank.setTokenPriceFeed(linkToken, linkUsdFeed);
```

Agora o banco pode aceitar depósitos de LINK!

---

### **Configurar Limite de Wei por Transação**

```solidity
function setNativePerTxCapWei(uint256 cap) external onlyOwner
```

**Exemplo:**
```solidity
// Limitar saques a máximo 1 ETH por transação
bank.setNativePerTxCapWei(1 ether);

// Remover limite
bank.setNativePerTxCapWei(0);
```

Adiciona uma camada extra de proteção além do limite USD.

---

## 🎨 Eventos

### **SuccessfulDeposit**

```solidity
event SuccessfulDeposit(
    address indexed account,
    address indexed token,
    uint256 amount,
    uint256 newBalance,
    uint256 usdValue
);
```

**Exemplo:**
```
SuccessfulDeposit(
    account: 0xABC...,
    token: 0xEeee...EEeE,
    amount: 1000000000000000000,  // 1 ETH
    newBalance: 2000000000000000000,  // 2 ETH total
    usdValue: 200000000000  // $2000
)
```

---

### **SuccessfulWithdrawal**

```solidity
event SuccessfulWithdrawal(
    address indexed account,
    address indexed token,
    uint256 amount,
    uint256 newBalance,
    uint256 usdValue
);
```

Similar ao Deposit, mas para saques.

---

### **AdminRecovery**

```solidity
event AdminRecovery(
    address indexed account,
    address indexed token,
    uint256 oldBalance,
    uint256 newBalance
);
```

Registra quando admin ajusta saldo de usuário.

---

## 🛡️ Segurança

### **1. ReentrancyGuard**

```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract KipuBank is ReentrancyGuard {
    function withdraw(uint256 amount) external nonReentrant {
        // Protegido contra reentrância
    }
}
```

**Como funciona:**
```solidity
bool private _locked = false;

modifier nonReentrant() {
    require(!_locked, "Reentrant call");
    _locked = true;
    _;
    _locked = false;
}
```

---

### **2. CEI Pattern (Checks-Effects-Interactions)**

Sempre nesta ordem:
1. **Checks**: Validações
2. **Effects**: Atualizar estado
3. **Interactions**: Chamadas externas

---

### **3. SafeERC20**

```solidity
using SafeERC20 for IERC20;

// ❌ PERIGOSO:
token.transfer(recipient, amount);  // Pode não reverter em erro

// ✅ SEGURO:
token.safeTransfer(recipient, amount);  // Sempre reverte em erro
```

---

### **4. Validações do Oracle**

```solidity
if (answer <= 0) revert InvalidPrice(answer);
if (answeredInRound < roundId) revert StalePrice();
if (block.timestamp - updatedAt > MAX_ORACLE_AGE) revert StalePrice();
```

Previne uso de dados manipulados ou antigos.

---

### **5. Limites USD**

- **Bank Cap**: Máximo $10,000 no banco
- **Withdrawal Limit**: Máximo $1,000 por saque

Previne drenagem rápida de fundos.

---

## 📊 Fluxo Completo de Depósito

```
Usuario                 KipuBank                Chainlink
   |                       |                         |
   |-- deposit(1 ETH) ---->|                         |
   |                       |                         |
   |                       |--- latestRoundData() -->|
   |                       |<-- $2000 (8 dec) -------|
   |                       |                         |
   |                       | ✅ Valida preço         |
   |                       | ✅ Calcula $2000 USD    |
   |                       | ✅ Verifica cap         |
   |                       | 📝 _balances += 1 ETH   |
   |                       | 📝 _cache += $2000      |
   |                       | 📝 depositCount++       |
   |                       |                         |
   |<-- evento emitido ----|                         |
   |                       |                         |
```

---

## 🎓 Conceitos Importantes

### **Wei vs Ether**

```solidity
1 ether = 1_000_000_000_000_000_000 wei
1 ether = 10**18 wei

// Em código:
uint256 valor = 1 ether;  // Compilador converte automaticamente
uint256 valor = 1e18;     // Mesma coisa
uint256 valor = 1000000000000000000;  // Mesma coisa
```

---

### **Decimals**

```solidity
// Chainlink: 8 decimals
$2000.00 = 2000 * 10**8 = 200000000000

// Tokens geralmente: 18 decimals
1 USDC = 1 * 10**6 (6 decimals)
1 DAI = 1 * 10**18 (18 decimals)
```

---

### **Indexed em Eventos**

```solidity
event SuccessfulDeposit(
    address indexed account,  // Pode filtrar por account
    address indexed token,    // Pode filtrar por token
    uint256 amount,           // Não pode filtrar
    uint256 newBalance,
    uint256 usdValue
);
```

`indexed` permite filtros eficientes:
```javascript
// Buscar todos os depósitos de Alice
const filter = bank.filters.SuccessfulDeposit(aliceAddress);
const events = await bank.queryFilter(filter);
```

---

## 🚀 Exemplo Prático Completo

```solidity
// 1. Deploy do contrato (Sepolia)
address sepoliaEthUsdFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
KipuBank bank = new KipuBank(sepoliaEthUsdFeed);

// 2. Alice deposita 2 ETH
vm.prank(alice);
bank.deposit{value: 2 ether}();

// 3. Alice verifica saldo
uint256 saldo = bank.getBalance(alice);  // 2 ether
uint256 saldoUsd = bank.getBalanceInUsd(ETH_ADDRESS, alice);  // $4000 (8 dec)

// 4. Alice saca 0.5 ETH ($1000 com preço $2000/ETH)
vm.prank(alice);
bank.withdraw(0.5 ether);

// 5. Saldo final de Alice
saldo = bank.getBalance(alice);  // 1.5 ether

// 6. Owner adiciona um admin
bank.addAdmin(bob);

// 7. Bob (admin) vê saldo de Alice
vm.prank(bob);
uint256 saldoAlice = bank.getBalance(alice);  // 1.5 ether

// 8. Total do banco
uint256 totalUsd = bank.totalBankUsd();  // $3000 (8 decimals)
```

---

## 📚 Recursos Adicionais

- **OpenZeppelin Docs**: https://docs.openzeppelin.com/contracts
- **Chainlink Price Feeds**: https://docs.chain.link/data-feeds
- **Solidity by Example**: https://solidity-by-example.org/
- **EIP-7528**: https://eips.ethereum.org/EIPS/eip-7528

---

## ✅ Checklist de Compreensão

Você entendeu quando conseguir responder:

- [ ] O que é um oracle e por que precisamos dele?
- [ ] Por que usamos 8 decimals para USD e 18 para ETH?
- [ ] O que é o CEI Pattern e por que é importante?
- [ ] Como funciona o `nonReentrant` modifier?
- [ ] Por que medimos balance before/after em `depositToken()`?
- [ ] Qual a diferença entre OWNER_ROLE e ADMIN_ROLE?
- [ ] Por que usamos cache para `totalBankUsd()`?
- [ ] O que acontece se tentarmos sacar mais que $1000?

---

**Próxima leitura:** [Testes do KipuBank](./Testes-KipuBank.md)
