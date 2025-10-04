# KipuBankV2

Contrato que simula um banco em Solidity com controle de depósitos/saques e limites em USD usando Chainlink price feed.

## Feature 1️⃣ WITHDRAWAL LIMITS IN USD ✅
O contrato impõe um limite de saque por transação expresso em USD (com 8 decimais, compatível com Chainlink), independentemente da flutuação do preço do ETH.

- `usdWithdrawalLimit` (public immutable) — limite por saque: 1000 USD (armazenado como `1000 * 10^8`).
- Ao executar `withdraw(amount)` o `amount` é esperado em wei (1 ETH = 1e18 wei). O contrato consulta o Chainlink feed (função `latestAnswer()`), que retorna o preço do ETH em USD com 8 decimais, e converte `amount` para USD:

  usdValue = (price * amount) / 1e18

  Se `usdValue > usdWithdrawalLimit`, a transação reverte com `ExceedsUsdLimit`.

Isso garante que o usuário não consiga sacar mais do que 1000 USD por transação, mesmo que o preço do ETH suba ou desça.

---

## Outras características
- `maxUsdBankCap` (public immutable) — cap total do banco em USD com 8 decimais (10000 USD). O `deposit()` converte o depósito e o saldo atual para USD antes de aceitar o depósito.
- Saldos internos são armazenados em wei (`_balances[address]` e `_kipuBankBalance`), para evitar perda de precisão em ETH.
- `getEthPrice()` retorna o preço do ETH em USD com 8 decimais (via Chainlink feed).
- `weiToUsd(uint256)` converte um valor em wei para USD (8 decimais).
- `getBalanceInUsd(address)` retorna o saldo de uma conta em USD (8 decimais) — protegido para o dono da conta ou o owner do banco.

## Como testar no Remix
1. Abra https://remix.ethereum.org
2. Crie um arquivo e cole `src/KipuBankV2.sol`.
3. Compile com o compilador Solidity `0.8.20`.
4. Deploy:
   - Construtor: `constructor(address _priceFeed)`
   - Para usar o feed Sepolia já apontado no contrato, passe `0x0000000000000000000000000000000000000000`.
5. Testes:
   - `deposit()` — enviar ETH via campo "Value" no Remix.
   - `withdraw(amount)` — passe `amount` em wei. O contrato validará o equivalente em USD.
   - Consulte `getEthPrice()` e `getBalanceInUsd(yourAddress)` para depuração.

## Observações e limitações
- O contrato depende do feed Chainlink; se o feed não estiver disponível na rede escolhida, calls que lêem `latestAnswer()` reverterão.
- Valores em USD retornados/armazenados usam 8 casas decimais (mesma unidade do `latestAnswer()`).


---

Feito por: Rocha Everton DEV