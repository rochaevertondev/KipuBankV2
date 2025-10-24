// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @dev Chainlink Aggregator interface with full roundData support.
interface AggregatorV3Interface {
    /// @notice returns the number of decimals for the price feed.
    function decimals() external view returns (uint8);

    /// @notice returns the latest complete round data.
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

contract KipuBank is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /// @dev Chainlink price feed (uses latestRoundData for price with validation)
    AggregatorV3Interface public priceFeed;

    /// @dev EIP-7528 canonical placeholder address used to represent ETH when an address is required.
    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The maximum USD amount of funds the bank can hold.
    uint256 public immutable maxUsdBankCap = 10000 * 10 ** 8;
    /// @dev The maximum amount of USD that can be withdrawn in a single transaction.
    uint256 public immutable usdWithdrawalLimit = 1000 * 10 ** 8;
    /// @dev The maximum amount of wei that can be withdrawn in a single native ETH transaction.
    uint256 public nativePerTxCapWei;
    /// @dev Maximum age for oracle price data (1 hour).
    uint256 public constant MAX_ORACLE_AGE = 1 hours;
    /// @dev The address of the contract's owner, set upon deployment.
    address public immutable ownerBank;
    /// @dev Per-token total balances held by the contract (token address -> amount).
    mapping(address => uint256) private _tokenTotals;

    /// @dev Per-token per-account balances (token => account => amount).
    mapping(address => mapping(address => uint256)) private _balances;

    /// @dev Cached total bank USD value (8 decimals) for O(1) lookups.
    uint256 private _totalBankUsdCache;

    /// @dev Total number of deposits made to the bank.
    uint256 public depositCount;

    /// @dev Total number of withdrawals made from the bank.
    uint256 public withdrawCount;

    /// @dev Tracks which tokens are known to the bank (used to compute total USD exposure).
    address[] public trackedTokens;
    mapping(address => bool) private _isTracked;

    /// @dev Per-token Chainlink price feed (token address -> Aggregator). For ETH use the `priceFeed` field.
    mapping(address => AggregatorV3Interface) public tokenPriceFeed;

    /// @notice Error returned when a function is called by an address that is not the bank owner.
    /// @param caller The address that attempted the call.
    error NotOwnerBank(address caller);
    /// @notice Error returned when a function accessing an account is called by an unauthorized address.
    /// @param caller The address that attempted the call.
    error NotAccountOwner(address caller);
    /// @notice Error returned for invalid transaction values.
    /// @param value The invalid value passed in the transaction.
    error InvalidValue(uint256 value);
    /// @notice Error returned when price feed fails or returns non-positive price.
    /// @param price The price returned by the feed.
    error InvalidPrice(int256 price);
    /// @notice Error returned when the USD equivalent of a withdrawal exceeds the allowed limit.
    /// @param usdValue The USD value (with 8 decimals) of the attempted withdrawal.
    /// @param limit The configured USD limit (with 8 decimals).
    error ExceedsUsdLimit(uint256 usdValue, uint256 limit);
    /// @notice Error returned when a withdrawal exceeds the wei limit for native ETH.
    /// @param weiValue The wei amount of the attempted withdrawal.
    /// @param limit The configured wei limit.
    error ExceedsWeiLimit(uint256 weiValue, uint256 limit);
    /// @notice Error returned when the maximum fund limit of the bank is reached.
    /// @param value The amount of funds that exceeds the cap.
    error MaxBankCapReached(uint256 value);
    /// @notice Error returned when oracle data is stale or invalid.
    error StalePrice();
    /// @notice Error returned when a user's balance is insufficient for a withdrawal.
    /// @param value The available balance in the account.
    error InsufficientBalance(uint256 value);
    /// @notice Error returned when an Ether or token transfer fails.
    error TransferFailed();

    /// @dev token is the token address or ETH_ADDRESS for native ETH
    event SuccessfulDeposit(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 newBalance,
        uint256 usdValue
    );
    event SuccessfulWithdrawal(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 newBalance,
        uint256 usdValue
    );
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event AdminRecovery(
        address indexed account,
        address indexed token,
        uint256 oldBalance,
        uint256 newBalance
    );
    event NativeCapUpdated(uint256 oldCap, uint256 newCap);

    /// @dev Role identifier for the owner role used as admin for ADMIN_ROLE.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    /// @dev Role identifier for admins.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @param _priceFeed address of the Chainlink price feed (Sepolia ETH/USD)
    constructor(address _priceFeed) {
        // Initialize price feed first (may be needed to compute defaults)
        if (_priceFeed == address(0)) {
            priceFeed = AggregatorV3Interface(
                0x694AA1769357215DE4FAC081bf1f309aDC325306
            );
        } else {
            priceFeed = AggregatorV3Interface(_priceFeed);
        }

        // If constructor args are zero, compute defaults using current price
        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (price <= 0) {
            revert InvalidPrice(price);
        }

        ownerBank = msg.sender;

        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);

        nativePerTxCapWei = 0; // 0 means no limit
    }

    /// @notice Deposit native ETH (use EIP-7528 ETH placeholder address in getters/events).
    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert InvalidValue(msg.value);

        // Checks
        uint256 depositUsd = weiToUsd(msg.value);
        if (_totalBankUsdCache + depositUsd > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - _totalBankUsdCache);
        }

        // Effects
        _balances[ETH_ADDRESS][msg.sender] += msg.value;
        _tokenTotals[ETH_ADDRESS] += msg.value;
        _totalBankUsdCache += depositUsd;
        _trackTokenIfNeeded(ETH_ADDRESS);

        unchecked {
            depositCount++;
        }

        emit SuccessfulDeposit(
            msg.sender,
            ETH_ADDRESS,
            msg.value,
            _balances[ETH_ADDRESS][msg.sender],
            depositUsd
        );
    }

    /// @notice Withdraw native ETH. `amount` is in wei.
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidValue(amount);

        // Checks
        uint256 bal = _balances[ETH_ADDRESS][msg.sender];
        if (amount > bal) revert InsufficientBalance(bal);

        uint256 usdValue = weiToUsd(amount);
        if (usdValue > usdWithdrawalLimit)
            revert ExceedsUsdLimit(usdValue, usdWithdrawalLimit);

        // Check native wei cap if set
        if (nativePerTxCapWei != 0 && amount > nativePerTxCapWei) {
            revert ExceedsWeiLimit(amount, nativePerTxCapWei);
        }

        // Effects
        _balances[ETH_ADDRESS][msg.sender] = bal - amount;
        _tokenTotals[ETH_ADDRESS] -= amount;
        _totalBankUsdCache -= usdValue;

        unchecked {
            withdrawCount++;
        }

        // Interactions
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit SuccessfulWithdrawal(
            msg.sender,
            ETH_ADDRESS,
            amount,
            _balances[ETH_ADDRESS][msg.sender],
            usdValue
        );
    }

    /// @notice Deposit ERC20 token. Caller must `approve` this contract beforehand.
    function depositToken(address token, uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidValue(amount);

        // Checks - verify cap BEFORE transferring tokens (CEI pattern)
        uint256 depositUsd = tokenAmountToUsd(token, amount);
        if (_totalBankUsdCache + depositUsd > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - _totalBankUsdCache);
        }

        // Effects - measure actual received amount (handles fee-on-transfer tokens)
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        // Interactions - transfer tokens LAST
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 received = IERC20(token).balanceOf(address(this)) -
            balanceBefore;

        // Recalculate USD based on actual received amount
        uint256 actualDepositUsd = tokenAmountToUsd(token, received);

        _balances[token][msg.sender] += received;
        _tokenTotals[token] += received;
        _totalBankUsdCache += actualDepositUsd;
        _trackTokenIfNeeded(token);

        unchecked {
            depositCount++;
        }

        emit SuccessfulDeposit(
            msg.sender,
            token,
            received,
            _balances[token][msg.sender],
            actualDepositUsd
        );
    }

    /// @notice Withdraw ERC20 token previously deposited.
    function withdrawToken(
        address token,
        uint256 amount
    ) external nonReentrant {
        if (amount == 0) revert InvalidValue(amount);

        // Checks
        uint256 bal = _balances[token][msg.sender];
        if (amount > bal) revert InsufficientBalance(bal);

        uint256 usdValue = tokenAmountToUsd(token, amount);
        if (usdValue > usdWithdrawalLimit)
            revert ExceedsUsdLimit(usdValue, usdWithdrawalLimit);

        // Effects
        _balances[token][msg.sender] = bal - amount;
        _tokenTotals[token] -= amount;
        _totalBankUsdCache -= usdValue;

        unchecked {
            withdrawCount++;
        }

        // Interactions
        IERC20(token).safeTransfer(msg.sender, amount);

        emit SuccessfulWithdrawal(
            msg.sender,
            token,
            amount,
            _balances[token][msg.sender],
            usdValue
        );
    }

    /// @dev A modifier that restricts a function's execution to accounts with OWNER_ROLE.
    modifier onlyOwner() {
        if (!hasRole(OWNER_ROLE, msg.sender)) {
            revert NotOwnerBank(msg.sender);
        }
        _;
    }

    function currentBalance() external view onlyOwner returns (uint256) {
        // return the bank total balance expressed in USD with 8 decimals
        return _totalBankUsdCache;
    }

    /// @notice Owner-only: set the native per-transaction wei cap for ETH withdrawals.
    /// @param cap The new cap in wei (0 means no limit).
    function setNativePerTxCapWei(uint256 cap) external onlyOwner {
        uint256 oldCap = nativePerTxCapWei;
        nativePerTxCapWei = cap;
        emit NativeCapUpdated(oldCap, cap);
    }

    /// @dev A modifier that restricts a function's execution to the account owner or any account with ADMIN_ROLE.
    modifier onlyAccountOwnerOrAdmin(address token, address account) {
        if (msg.sender != account && !hasRole(ADMIN_ROLE, msg.sender)) {
            revert NotAccountOwner(msg.sender);
        }
        _;
    }

    /// @notice Returns the ETH balance (wei) for `account`.
    function getBalance(
        address account
    )
        external
        view
        onlyAccountOwnerOrAdmin(ETH_ADDRESS, account)
        returns (uint256)
    {
        return _balances[ETH_ADDRESS][account];
    }

    /// @notice Returns the token balance for `account` and `token`.
    function getBalanceOf(
        address token,
        address account
    ) external view onlyAccountOwnerOrAdmin(token, account) returns (uint256) {
        return _balances[token][account];
    }

    /// @notice Owner-only: grant ADMIN_ROLE to an account.
    function addAdmin(address account) external onlyOwner {
        _grantRole(ADMIN_ROLE, account);
        emit AdminAdded(account);
    }

    /// @notice Owner-only: revoke ADMIN_ROLE from an account.
    function removeAdmin(address account) external onlyOwner {
        _revokeRole(ADMIN_ROLE, account);
        emit AdminRemoved(account);
    }

    /// @notice Admins can adjust a user's token balance to help recover funds. Token may be ETH_ADDRESS for native ETH.
    function recoverUserBalance(
        address token,
        address account,
        uint256 newBalance
    ) external onlyRole(ADMIN_ROLE) {
        uint256 old = _balances[token][account];
        if (newBalance > old) {
            uint256 delta = newBalance - old;
            uint256 deltaUsd = tokenAmountToUsd(token, delta);
            _balances[token][account] = newBalance;
            _tokenTotals[token] += delta;
            _totalBankUsdCache += deltaUsd;
        } else if (newBalance < old) {
            uint256 delta = old - newBalance;
            uint256 deltaUsd = tokenAmountToUsd(token, delta);
            _balances[token][account] = newBalance;
            _tokenTotals[token] -= delta;
            _totalBankUsdCache -= deltaUsd;
        } else {
            return;
        }

        // Ensure bank cap is not violated after recovery
        if (_totalBankUsdCache > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - _totalBankUsdCache);
        }

        emit AdminRecovery(account, token, old, newBalance);
    }

    /// @notice Returns the latest ETH price in USD with 8 decimals (reverts if price <= 0 or stale).
    function getEthPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        if (answer <= 0) revert InvalidPrice(answer);
        if (answeredInRound < roundId) revert StalePrice();
        if (block.timestamp - updatedAt > MAX_ORACLE_AGE) revert StalePrice();

        // Normalize to 8 decimals
        uint8 feedDecimals = _getFeedDecimals(priceFeed);
        return _normalizePriceTo8Decimals(uint256(answer), feedDecimals);
    }

    /// @notice Convert an amount in wei to USD with 8 decimals using the Chainlink feed.
    /// @param amountWei amount in wei
    /// @return usdValue USD value with 8 decimals
    function weiToUsd(
        uint256 amountWei
    ) public view returns (uint256 usdValue) {
        uint256 price = getEthPrice();
        // usd = price(8dec) * wei / 1e18 -> result has 8 decimals
        usdValue = (price * amountWei) / 1e18;
    }

    /// @notice Convert token amount to USD (8 decimals). For ETH use `ETH_ADDRESS` and pass wei amount.
    function tokenAmountToUsd(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return weiToUsd(amount);
        }
        AggregatorV3Interface feed = tokenPriceFeed[token];
        if (address(feed) == address(0)) revert InvalidPrice(0);

        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = feed.latestRoundData();

        if (answer <= 0) revert InvalidPrice(answer);
        if (answeredInRound < roundId) revert StalePrice();
        if (block.timestamp - updatedAt > MAX_ORACLE_AGE) revert StalePrice();

        uint8 tokenDecimals = 18;
        // try to read token decimals if available
        try IERC20Metadata(token).decimals() returns (uint8 d) {
            tokenDecimals = d;
        } catch {
            tokenDecimals = 18; // fallback
        }

        // Normalize price to 8 decimals
        uint8 feedDecimals = _getFeedDecimals(feed);
        uint256 priceUsd8 = _normalizePriceTo8Decimals(
            uint256(answer),
            feedDecimals
        );

        // usd (8 decimals) = price (8 decimals) * amount (token decimals) / (10**token decimals)
        return (priceUsd8 * amount) / (10 ** tokenDecimals);
    }

    /// @notice Returns total bank USD exposure (8 decimals) - now O(1) using cache.
    function totalBankUsd() public view returns (uint256) {
        return _totalBankUsdCache;
    }

    /// @notice Recalculates total bank USD from scratch (for verification/emergency).
    /// @dev This is the O(n) version, kept for admin verification purposes.
    function recalculateTotalBankUsd()
        external
        onlyOwner
        returns (uint256 totalUsd)
    {
        for (uint256 i = 0; i < trackedTokens.length; i++) {
            address t = trackedTokens[i];
            uint256 tot = _tokenTotals[t];
            if (tot == 0) continue;
            totalUsd += tokenAmountToUsd(t, tot);
        }
        _totalBankUsdCache = totalUsd;
        return totalUsd;
    }

    /// @notice Owner can set a price feed for arbitrary tokens (token address -> aggregator).
    function setTokenPriceFeed(
        address token,
        address aggregator
    ) external onlyOwner {
        tokenPriceFeed[token] = AggregatorV3Interface(aggregator);
        _trackTokenIfNeeded(token);
    }

    function _trackTokenIfNeeded(address token) internal {
        if (!_isTracked[token]) {
            _isTracked[token] = true;
            trackedTokens.push(token);
        }
    }

    /// @notice Returns the USD value (8 decimals) of an account's internal balance for a given token. Restricted to account or admin.
    function getBalanceInUsd(
        address token,
        address account
    ) external view onlyAccountOwnerOrAdmin(token, account) returns (uint256) {
        return tokenAmountToUsd(token, _balances[token][account]);
    }

    /// @dev Internal helper to get feed decimals safely.
    /// @param feed The Chainlink price feed.
    /// @return The number of decimals (defaults to 8 if call fails).
    function _getFeedDecimals(
        AggregatorV3Interface feed
    ) internal view returns (uint8) {
        try feed.decimals() returns (uint8 d) {
            return d;
        } catch {
            return 8; // Default to 8 decimals (Chainlink standard)
        }
    }

    /// @dev Internal helper to normalize price feed decimals to 8 decimals.
    /// @param price The raw price from the feed.
    /// @param feedDecimals The number of decimals the feed uses.
    /// @return The price normalized to 8 decimals.
    function _normalizePriceTo8Decimals(
        uint256 price,
        uint8 feedDecimals
    ) internal pure returns (uint256) {
        if (feedDecimals == 8) {
            return price;
        } else if (feedDecimals < 8) {
            return price * (10 ** (8 - feedDecimals));
        } else {
            return price / (10 ** (feedDecimals - 8));
        }
    }
}
