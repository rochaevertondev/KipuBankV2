# 🏦 KipuBankV2

A Solidity smart contract that simulates a simple decentralized bank with **deposit and withdrawal controls**, enforcing **USD-based limits** using a **Chainlink price feed**. It supports multiple tokens (native ETH + ERC‑20) and includes an ADMIN recovery function to recover excess tokens/ETH.

## 1️⃣ WITHDRAWAL LIMITS IN USD ✅

The contract enforces a **maximum withdrawal per transaction** expressed in **USD** (8 decimals, compatible with Chainlink).

- **`usdWithdrawalLimit`** (`public immutable`) — withdrawal limit: `1000 USD` (stored as `1000 * 10^8`).
- **`nativePerTxCapWei`** (`public`) — optional per-transaction wei cap for ETH withdrawals (0 = no limit).
- When a user calls `withdraw(amount)` (where `amount` is in wei), the contract:
  1. Gets the ETH/USD price from Chainlink using `latestRoundData()` with full oracle validation (staleness check, roundId verification).
  2. Converts the `amount` to USD with normalized decimals (supports any feed decimals):
    usdValue = (price * amount) / 1e18;
  3. Reverts with `ExceedsUsdLimit` if `usdValue > usdWithdrawalLimit`.
  4. Reverts with `ExceedsWeiLimit` if wei cap is set and `amount > nativePerTxCapWei`.

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
    - `recoverUserBalance(address token, address account, uint256 newBalance)` — admins can adjust an account's internal balance for any token (use `ETH_ADDRESS` for native ETH) to help recover funds. This action emits `AdminRecovery` and adjusts the total internal bank balance and USD cache accordingly.

---

## 3️⃣ MULTI-TOKEN SUPPORT 🪙

- Support for native ETH and ERC‑20 tokens in the same contract.
- EIP‑7528 placeholder for ETH: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (used as `token` identifier when referring to ETH in events/getters).
- Per-token balances: `_balances[token][account]` and `_tokenTotals[token]`.
- Chainlink price feed per token: owner can call `setTokenPriceFeed(token, aggregator)` to allow USD conversions for each token.
- SafeERC20 used for ERC‑20 interactions to support older non‑standard tokens.

---

## Other Features

- **`maxUsdBankCap`** (public immutable) — total bank capacity limit in USD with 8 decimals (10,000 USD).
The deposit functions convert both the incoming deposit and the total balance to USD before accepting new funds.
- **Deposit/Withdraw counters** — `depositCount` and `withdrawCount` track total number of operations.
- **O(1) total USD tracking** — `_totalBankUsdCache` maintains running total for instant `totalBankUsd()` queries; `recalculateTotalBankUsd()` available for verification.
- **Oracle hygiene** — all price feeds validated with `latestRoundData()`: checks `answer > 0`, `answeredInRound >= roundId`, and `updatedAt` within 1 hour (MAX_ORACLE_AGE).
- **Feed decimals normalization** — supports Chainlink feeds with any decimals (8, 18, etc.) via `_normalizePriceTo8Decimals()` helper.
- **Fee-on-transfer token support** — `depositToken()` uses balance delta to handle tokens with transfer fees correctly.
- Internal balances are stored in native token units (`_balances[token][account]` and `_tokenTotals[token]`) to preserve precision.
- `getEthPrice()` — returns the current ETH price in USD (8 decimals) using Chainlink with full validation.
- `weiToUsd(uint256)` — converts an amount in wei to its equivalent USD value (8 decimals).
- `tokenAmountToUsd(address, uint256)` — converts any token amount to USD (supports ETH via `ETH_ADDRESS`).
- `getBalanceInUsd(address token, address account)` — returns an account's token balance in USD (8 decimals), restricted to the account owner or admins.
- `setNativePerTxCapWei(uint256)` — owner can set/update the per-transaction wei cap for ETH withdrawals.

---

## How to Test in Remix

1. Open https://remix.ethereum.org
2. Create a new file and paste the contents of `src/KipuBankV2.sol`.
3. Compile with Solidity compiler `v0.8.20`.
4. Deploy:
    - Constructor: `constructor(address _priceFeed)`
    - To use the Sepolia feed already referenced in the contract, pass `0x0000000000000000000000000000000000000000` or `0x694AA1769357215DE4FAC081bf1f309aDC325306`.
5. Tests:

    ## Deposits and Withdrawals in Remix.
    
    - `deposit()` — send ETH using the “Value” field.
    - `withdraw(amount)` — input amount in wei. The contract will validate the equivalent USD value.
    - Use `getEthPrice()` and `getBalanceInUsd(yourAddress)` for debugging.

    ## Testing roles (OWNER_ROLE and ADMIN_ROLE) in Remix:
    
    - Granting an admin (only OWNER_ROLE can do this):
        1. Ensure the currently selected account in Remix is the deployer (the account that has `OWNER_ROLE`).
        2. Call `addAdmin(address)` with the target address to give it `ADMIN_ROLE`.
        3. Verify: call `hasRole(ADMIN_ROLE(), targetAddress)` and expect `true`.
    - Revoking an admin (only OWNER_ROLE can do this):
        1. With the deployer account selected, call `removeAdmin(address)`.
        2. Verify: call `hasRole(ADMIN_ROLE(), targetAddress)` and expect `false`.
    - Testing admin-only recovery:
        1. After granting `ADMIN_ROLE` to an address, switch the active Remix account to that admin address in the top-right account selector.
        2. Call `recoverUserBalance(address token, address account, uint256 newBalance)` to change a user's internal balance for a specific token (use `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` for ETH).
        3. Verify the change by calling `getBalanceOf(token, targetAccount)` or `getBalanceInUsd(token, targetAccount)`.
        4. Try calling `recoverUserBalance` from a non-admin account — it should revert (access denied).
    - Testing owner-only protection:
        1. From a non-owner account, try to call `addAdmin(address)` or `removeAdmin(address)` and confirm the transaction reverts.

    ## Example: deposit TOKEN LINK

    - TOKEN LINK address (example): `0x779877A7B0D9E8603169DdbD7836e478b4624789`
    - LINK/USD Chainlink feed: `0xc59E3633BAAC79493d908e63626716e204A45EdF`
    - As OWNER (deployer): call `setTokenPriceFeed(tokenAddress, feedAddress)` with the two addresses above so the contract can convert LINK to USD.
    - As user: on the LINK token contract call `approve(<KipuBankAddress>, amount)` (e.g. `1 LINK = 1000000000000000000` for 18 decimals), then call `depositToken(tokenAddress, amount)` on the deployed `KipuBank` contract.
    - Verify with `getBalanceOf(tokenAddress, yourAddress)` and `getBalanceInUsd(tokenAddress, yourAddress)`.

---

## 🧑‍💻 Author
**Rocha Everton (DEV)**  
📧 [GitHub](https://github.com/rochaevertondev/) | 💬 [LinkedIn](https://linkedin.com/in/rochaevertondev/) 