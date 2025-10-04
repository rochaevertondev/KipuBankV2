# 🏦 KipuBankV2

A Solidity smart contract that simulates a simple decentralized bank with **deposit and withdrawal controls**, enforcing **USD-based limits** using a **Chainlink price feed**.

## Feature 1️⃣ WITHDRAWAL LIMITS IN USD ✅

The contract enforces a **maximum withdrawal per transaction** expressed in **USD** (8 decimals, compatible with Chainlink).

- **`usdWithdrawalLimit`** (`public immutable`) — withdrawal limit: `1000 USD` (stored as `1000 * 10^8`).
- When a user calls `withdraw(amount)` (where `amount` is in wei), the contract:
  1. Gets the ETH/USD price from Chainlink (`latestAnswer()`).
  2. Converts the `amount` to USD:
     ```solidity
     usdValue = (price * amount) / 1e18;
     ```
  3. Reverts with `ExceedsUsdLimit` if `usdValue > usdWithdrawalLimit`.

 This ensures users cannot withdraw more than **$1000 USD** per transaction, regardless of ETH price fluctuations.

---

## Other Features

- `maxUsdBankCap` (public immutable) — total bank capacity limit in USD with 8 decimals (10000 USD). O `deposit()` converte o depósito e o saldo atual para USD antes de aceitar o depósito.
- Saldos internos são armazenados em wei (`_balances[address]` e `_kipuBankBalance`), para evitar perda de precisão em ETH.
- `getEthPrice()` retorna o preço do ETH em USD com 8 decimais (via Chainlink feed).
- `weiToUsd(uint256)` converte um valor em wei para USD (8 decimais).
- `getBalanceInUsd(address)` retorna o saldo de uma conta em USD (8 decimais) — protegido para o dono da conta ou o owner do banco.

- `maxUsdBankCap` (public immutable) — total bank capacity limit in USD with 8 decimals (10,000 USD).
The deposit() function converts both the incoming deposit and the total balance to USD before accepting new funds.
- Internal balances are stored in wei (`_balances[address]` and `_kipuBankBalance`) to preserve ETH precision.
- `getEthPrice()` — returns the current ETH price in USD (8 decimals) using Chainlink.
- `weiToUsd(uint256)` — converts an amount in wei to its equivalent USD value (8 decimals).
- `getBalanceInUsd(address)` — returns an account’s balance in USD (8 decimals), restricted to the account owner or the bank owner.

## How to Test in Remix

1. Open https://remix.ethereum.org
2. Create a new file and paste the contents of `src/KipuBankV2.sol`.
3. Compile with Solidity compiler `v0.8.20`.
4. Deploy:
    - Constructor: `constructor(address _priceFeed)`
    - To use the Sepolia feed already referenced in the contract, pass `0x0000000000000000000000000000000000000000`.
5. Tests:
    - `deposit()` — send ETH using the “Value” field in Remix.
    - `withdraw(amount)` — input amount in wei. The contract will validate the equivalent USD value.
    - Use `getEthPrice()` and `getBalanceInUsd(yourAddress)` for debugging.

## Notes and Limitations
- All USD values are stored and returned using 8 decimal places, consistent with Chainlink price formatting.
- The contract depends on the Chainlink price feed. If the feed is unavailable on the selected network, calls to latestAnswer() will revert.

---

## 🧑‍💻 Author
**Rocha Everton (DEV)**  
📧 [GitHub](https://https://github.com/rochaevertondev/) | 💬 [LinkedIn](https://linkedin.com/in/rochaevertondev/) 