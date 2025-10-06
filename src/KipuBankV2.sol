// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/// @dev Minimal Chainlink Aggregator interface exposing latestAnswer().
interface AggregatorV3Interface {
    /// @notice returns the latest price answer.
    function latestAnswer() external view returns (int256);
}


contract KipuBank is AccessControl {
    using SafeERC20 for IERC20;
    /// @dev Chainlink price feed (latestAnswer returns price with 8 decimals)
    AggregatorV3Interface public priceFeed;

    /// @dev EIP-7528 canonical placeholder address used to represent ETH when an address is required.
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The maximum USD amount of funds the bank can hold.
    uint256 public immutable maxUsdBankCap = 10000 * 10 ** 8;
    /// @dev The maximum amount of USD that can be withdrawn in a single transaction.
    uint256 public immutable usdWithdrawalLimit = 1000 * 10 ** 8;
    /// @dev The address of the contract's owner, set upon deployment.
    address public immutable ownerBank;
    /// @dev Per-token total balances held by the contract (token address -> amount).
    mapping(address => uint256) private _tokenTotals;

    /// @dev Per-token per-account balances (token => account => amount).
    mapping(address => mapping(address => uint256)) private _balances;

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
    /// @notice Error returned when the maximum fund limit of the bank is reached.
    /// @param value The amount of funds that exceeds the cap.
    error MaxBankCapReached(uint256 value);
    /// @notice Error returned when a user's balance is insufficient for a withdrawal.
    /// @param value The available balance in the account.
    error InsufficientBalance(uint256 value);
    /// @notice Error returned when an Ether or token transfer fails.
    error TransferFailed();


    /// @dev token is the token address or ETH_ADDRESS for native ETH
    event SuccessfulDeposit(address indexed account, address indexed token, uint256 amount);
    event SuccessfulWithdrawal(address indexed account, address indexed token, uint256 amount);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event AdminRecovery(address indexed account, uint256 oldBalance, uint256 newBalance);

    /// @dev Role identifier for the owner role used as admin for ADMIN_ROLE.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    /// @dev Role identifier for admins.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    /// @param _priceFeed address of the Chainlink price feed (Sepolia ETH/USD)
    constructor(address _priceFeed) {
        // Initialize price feed first (may be needed to compute defaults)
        if (_priceFeed == address(0)) {
            priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        } else {
            priceFeed = AggregatorV3Interface(_priceFeed);
        }

        // If constructor args are zero, compute defaults using current price
        // Price has 8 decimals: price = USD * 1e8 per 1 ETH
        int256 price = priceFeed.latestAnswer();
        if (price <= 0) {
            revert InvalidPrice(price);
        }

    ownerBank = msg.sender;

    _grantRole(OWNER_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
    // grant a dedicated OWNER_ROLE to the deployer and make OWNER_ROLE the admin of ADMIN_ROLE
    _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
    }

    /// @notice Deposit native ETH (use EIP-7528 ETH placeholder address in getters/events).
    function deposit() external payable {
        if (msg.value == 0) revert InvalidValue(msg.value);

        uint256 depositUsd = weiToUsd(msg.value);
        if (totalBankUsd() + depositUsd > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - totalBankUsd());
        }

        _balances[ETH_ADDRESS][msg.sender] += msg.value;
        _tokenTotals[ETH_ADDRESS] += msg.value;
        _trackTokenIfNeeded(ETH_ADDRESS);

        emit SuccessfulDeposit(msg.sender, ETH_ADDRESS, msg.value);
    }

 
    /// @notice Withdraw native ETH. `amount` is in wei.
    function withdraw(uint256 amount) external {
        if (amount == 0) revert InvalidValue(amount);
        uint256 bal = _balances[ETH_ADDRESS][msg.sender];
        if (amount > bal) revert InsufficientBalance(bal);

        uint256 usdValue = weiToUsd(amount);
        if (usdValue > usdWithdrawalLimit) revert ExceedsUsdLimit(usdValue, usdWithdrawalLimit);

        _balances[ETH_ADDRESS][msg.sender] = bal - amount;
        _tokenTotals[ETH_ADDRESS] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit SuccessfulWithdrawal(msg.sender, ETH_ADDRESS, amount);
    }

    /// @notice Deposit ERC20 token. Caller must `approve` this contract beforehand.
    function depositToken(address token, uint256 amount) external {
        if (amount == 0) revert InvalidValue(amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 depositUsd = tokenAmountToUsd(token, amount);
        if (totalBankUsd() + depositUsd > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - totalBankUsd());
        }

        _balances[token][msg.sender] += amount;
        _tokenTotals[token] += amount;
        _trackTokenIfNeeded(token);

        emit SuccessfulDeposit(msg.sender, token, amount);
    }

    /// @notice Withdraw ERC20 token previously deposited.
    function withdrawToken(address token, uint256 amount) external {
        if (amount == 0) revert InvalidValue(amount);
        uint256 bal = _balances[token][msg.sender];
        if (amount > bal) revert InsufficientBalance(bal);

        uint256 usdValue = tokenAmountToUsd(token, amount);
        if (usdValue > usdWithdrawalLimit) revert ExceedsUsdLimit(usdValue, usdWithdrawalLimit);

        _balances[token][msg.sender] = bal - amount;
        _tokenTotals[token] -= amount;

    IERC20(token).safeTransfer(msg.sender, amount);

        emit SuccessfulWithdrawal(msg.sender, token, amount);
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
        return totalBankUsd();
    }

    /// @dev A modifier that restricts a function's execution to the account owner or any account with ADMIN_ROLE.
    modifier onlyAccountOwnerOrAdmin(address token, address account) {
        if (msg.sender != account && !hasRole(ADMIN_ROLE, msg.sender)) {
            revert NotAccountOwner(msg.sender);
        }
        _;
    }

    /// @notice Returns the ETH balance (wei) for `account`.
    function getBalance(address account) external view onlyAccountOwnerOrAdmin(ETH_ADDRESS, account) returns (uint256) {
        return _balances[ETH_ADDRESS][account];
    }

    /// @notice Returns the token balance for `account` and `token`.
    function getBalanceOf(address token, address account) external view onlyAccountOwnerOrAdmin(token, account) returns (uint256) {
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
    function recoverUserBalance(address token, address account, uint256 newBalance) external onlyRole(ADMIN_ROLE) {
        uint256 old = _balances[token][account];
        if (newBalance > old) {
            uint256 delta = newBalance - old;
            _balances[token][account] = newBalance;
            _tokenTotals[token] += delta;
        } else if (newBalance < old) {
            uint256 delta = old - newBalance;
            _balances[token][account] = newBalance;
            _tokenTotals[token] -= delta;
        } else {
            return;
        }

        // Ensure bank cap is not violated after recovery
        if (totalBankUsd() > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - totalBankUsd());
        }

        emit AdminRecovery(account, old, newBalance);
    }

    /// @notice Returns the latest ETH price in USD with 8 decimals (reverts if price <= 0).
    function getEthPrice() public view returns (uint256) {
        int256 price = priceFeed.latestAnswer();
        if (price <= 0) {
            revert InvalidPrice(price);
        }
        return uint256(price);
    }

    /// @notice Convert an amount in wei to USD with 8 decimals using the Chainlink feed.
    /// @param amountWei amount in wei
    /// @return usdValue USD value with 8 decimals
    function weiToUsd(uint256 amountWei) public view returns (uint256 usdValue) {
        uint256 price = getEthPrice();
        // usd = price(8dec) * wei / 1e18 -> result has 8 decimals
        usdValue = (price * amountWei) / 1e18;
    }

    /// @notice Convert token amount to USD (8 decimals). For ETH use `ETH_ADDRESS` and pass wei amount.
    function tokenAmountToUsd(address token, uint256 amount) public view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return weiToUsd(amount);
        }
        AggregatorV3Interface feed = tokenPriceFeed[token];
        if (address(feed) == address(0)) revert InvalidPrice(0);
        int256 price = feed.latestAnswer();
        if (price <= 0) revert InvalidPrice(price);

        uint8 decimals = 18;
        // try to read token decimals if available
        try IERC20Metadata(token).decimals() returns (uint8 d) {
            decimals = d;
        } catch {
            decimals = 18; // fallback
        }

        // price has 8 decimals and amount has `decimals` decimals -> usd = price * amount / (10**decimals)
        return (uint256(price) * amount) / (10 ** decimals);
    }

    /// @notice Returns total bank USD exposure summing all tracked tokens (8 decimals)
    function totalBankUsd() public view returns (uint256 totalUsd) {
        for (uint256 i = 0; i < trackedTokens.length; i++) {
            address t = trackedTokens[i];
            uint256 tot = _tokenTotals[t];
            if (tot == 0) continue;
            totalUsd += tokenAmountToUsd(t, tot);
        }
    }

    /// @notice Owner can set a price feed for arbitrary tokens (token address -> aggregator).
    function setTokenPriceFeed(address token, address aggregator) external onlyOwner {
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
    function getBalanceInUsd(address token, address account) external view onlyAccountOwnerOrAdmin(token, account) returns (uint256) {
        return tokenAmountToUsd(token, _balances[token][account]);
    }
}