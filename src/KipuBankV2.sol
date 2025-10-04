// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";


/// @dev Minimal Chainlink Aggregator interface exposing latestAnswer().
interface AggregatorV3Interface {
    /// @notice returns the latest price answer.
    function latestAnswer() external view returns (int256);
}


contract KipuBank is AccessControl {
    /// @dev Chainlink price feed (latestAnswer returns price with 8 decimals)
    AggregatorV3Interface public priceFeed;

    /// @dev The maximum USD amount of funds the bank can hold.
    uint256 public immutable maxUsdBankCap = 10000 * 10 ** 8;
    /// @dev The maximum amount of USD that can be withdrawn in a single transaction.
    uint256 public immutable usdWithdrawalLimit = 1000 * 10 ** 8;
    /// @dev The address of the contract's owner, set upon deployment.
    address public immutable ownerBank;
    /// @dev The total amount of wei held by the contract (internal bank balance in wei).
    uint256 private _kipuBankBalance;

    /// @dev A mapping of addresses to their individual balances.
    mapping(address => uint256) private _balances;


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


    event SuccessfulDeposit(address indexed account, uint256 amount);
    event SuccessfulWithdrawal(address indexed account, uint256 amount);
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

    /// @notice Allows a user to deposit Ether into the bank.
    /// @dev The deposit is added to the user's balance and the bank's total balance.
    function deposit() external payable {
        if (msg.value <= 0) {
            revert InvalidValue(msg.value);
        }
        // Convert current total and incoming deposit to USD (8 decimals) for cap check
        uint256 currentUsd = weiToUsd(_kipuBankBalance);
        uint256 depositUsd = weiToUsd(msg.value);
        if (currentUsd + depositUsd > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - currentUsd);
        }

        _balances[msg.sender] += msg.value;
        _kipuBankBalance += msg.value;


        emit SuccessfulDeposit(msg.sender, msg.value);
    }

 
    function withdraw(uint256 amount) external payable{
        // amount is expected in wei
        if (amount == 0) {
            revert InvalidValue(amount);
        }
        if (amount > _balances[msg.sender]) {
            revert InsufficientBalance(_balances[msg.sender]);
        }

        // Check USD equivalent using Chainlink price feed (price has 8 decimals)
        int256 price = priceFeed.latestAnswer();
        if (price <= 0) {
            revert InvalidPrice(price);
        }
        // amount is in wei (1 ETH = 1e18 wei). To compute USD with 8 decimals:
        // usd = (amount_in_wei * price) / 1e18
        // where price has 8 decimals, so usd has 8 decimals.
        uint256 usdValue = (uint256(price) * amount) / 1e18;
        if (usdValue > usdWithdrawalLimit) {
            revert ExceedsUsdLimit(usdValue, usdWithdrawalLimit);
        }
        _balances[msg.sender] -= amount;
        _kipuBankBalance -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }

        emit SuccessfulWithdrawal(msg.sender, amount);
    }

    /// @dev A modifier that restricts a function's execution to accounts with OWNER_ROLE.
    modifier onlyOwner() {
        if (!hasRole(OWNER_ROLE, msg.sender)) {
            revert NotOwnerBank(msg.sender);
        }
        _;
    }

    function currentBalance() external view onlyOwner returns (uint256 current) {
        // return the bank total balance expressed in USD with 8 decimals
        return weiToUsd(_kipuBankBalance);
    }

    /// @dev A modifier that restricts a function's execution to the account owner or any account with ADMIN_ROLE.
    modifier onlyAccountOwnerOrAdmin(address account) {
        if (msg.sender != account && !hasRole(ADMIN_ROLE, msg.sender)) {
            revert NotAccountOwner(msg.sender);
        }
        _;
    }

    function getBalance(address account) external view onlyAccountOwnerOrAdmin(account) returns (uint256) {
        return _balances[account];
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

    /// @notice Admins can adjust a user's internal wei balance to help recover funds.
    /// @dev Adjusts the total bank balance accordingly. Only callable by ADMIN_ROLE.
    function recoverUserBalance(address account, uint256 newBalanceWei) external onlyRole(ADMIN_ROLE) {
        uint256 old = _balances[account];
        if (newBalanceWei > old) {
            uint256 delta = newBalanceWei - old;
            _balances[account] = newBalanceWei;
            _kipuBankBalance += delta;
        } else if (newBalanceWei < old) {
            uint256 delta = old - newBalanceWei;
            _balances[account] = newBalanceWei;
            _kipuBankBalance -= delta;
        } else {
            // no change
            return;
        }

        // Ensure bank cap is not violated after recovery (converted to USD)
        uint256 bankUsd = weiToUsd(_kipuBankBalance);
        if (bankUsd > maxUsdBankCap) {
            revert MaxBankCapReached(maxUsdBankCap - bankUsd);
        }

        emit AdminRecovery(account, old, newBalanceWei);
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

    /// @notice Returns the USD value (8 decimals) of an account's internal balance. Restricted to account or owner.
    function getBalanceInUsd(address account) external view onlyAccountOwnerOrAdmin(account) returns (uint256) {
        return weiToUsd(_balances[account]);
    }
}