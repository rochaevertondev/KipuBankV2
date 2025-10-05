# 🏦 KipuBankV2

A Solidity smart contract that simulates a simple decentralized bank with **deposit and withdrawal controls**, enforcing **USD-based limits** using a **Chainlink price feed**.

## 1️⃣ WITHDRAWAL LIMITS IN USD ✅

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

## 2️⃣ ADMIN RECOVERY 🔑

This contract uses OpenZeppelin AccessControl and defines two primary roles:

- `OWNER_ROLE` — role that has the authority to add or remove administrators. 
    Functions controlled by `OWNER_ROLE`:
    - `addAdmin(address)` — grant an address the `ADMIN_ROLE`.
    - `removeAdmin(address)` — revoke an address's `ADMIN_ROLE`.

- `ADMIN_ROLE` — role with a narrow, specific power: recover or adjust a user's internal balance when needed. 
    Functions controlled by `ADMIN_ROLE`:
    - `recoverUserBalance(address account, uint256 newBalanceWei)` — admins can update an account's internal wei balance to help recover funds. This action emits `AdminRecovery` and adjusts the total internal bank balance accordingly.

Security notes:
- Only accounts with `OWNER_ROLE` can add or remove admins.
- `ADMIN_ROLE` does not grant the power to manage roles — it only allows balance recovery.
- It's recommended to assign `OWNER_ROLE` to a multisig (e.g., Gnosis Safe) to avoid single-point-of-failure key risks.

---

## Other Features

- `maxUsdBankCap` (public immutable) — total bank capacity limit in USD with 8 decimals (10,000 USD).
The deposit() function converts both the incoming deposit and the total balance to USD before accepting new funds.
- Internal balances are stored in wei (`_balances[address]` and `_kipuBankBalance`) to preserve ETH precision.
- `getEthPrice()` — returns the current ETH price in USD (8 decimals) using Chainlink.
- `weiToUsd(uint256)` — converts an amount in wei to its equivalent USD value (8 decimals).
- `getBalanceInUsd(address)` — returns an account’s balance in USD (8 decimals), restricted to the account owner or the bank owner.

---

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

---

## 🧑‍💻 Author
**Rocha Everton (DEV)**  
📧 [GitHub](https://github.com/rochaevertondev/) | 💬 [LinkedIn](https://linkedin.com/in/rochaevertondev/) 