// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


contract KipuBank {
    /// @dev The maximum amount of funds the bank can hold.
    uint256 public immutable MaxBankCap;
    /// @dev The maximum amount of Ether that can be withdrawn in a single transaction.
    uint256 public immutable LimitMaxPerWithdraw;
    /// @dev The address of the contract's owner, set upon deployment.
    address public immutable _ownerBank;
    /// @dev The total amount of Ether held by the contract.
    uint256 private _kipuBankBalance;
    /// @dev The total count of deposits made.
    uint256 public _countDeposits;
    /// @dev The total count of withdrawals made.
    uint256 public _countWithdrawals;

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


    constructor(uint256 _MaxBankCap, uint256 _LimitMaxPerWithdraw) {
        MaxBankCap = _MaxBankCap;
        LimitMaxPerWithdraw = _LimitMaxPerWithdraw;
        _ownerBank = msg.sender;
    }

    /// @notice Allows a user to deposit Ether into the bank.
    /// @dev The deposit is added to the user's balance and the bank's total balance.
    function deposit() external payable {
        if (msg.value <= 0) {
            revert InvalidValue(msg.value);
        }
        if (_kipuBankBalance + msg.value > MaxBankCap) {
            revert MaxBankCapReached(MaxBankCap - _kipuBankBalance);
        }

        _balances[msg.sender] += msg.value;
        _kipuBankBalance += msg.value;
        _countDeposits ++;

        emit SuccessfulDeposit(msg.sender, msg.value);
    }

 
    function withdraw(uint256 amount) external payable{
        if (amount <= 0 || amount > LimitMaxPerWithdraw) {
            revert InvalidValue(LimitMaxPerWithdraw); 
        }
        if (amount > _balances[msg.sender]) {
            revert InsufficientBalance(_balances[msg.sender]);
        }
        _balances[msg.sender] -= amount;
        _kipuBankBalance -= amount;
        _countWithdrawals ++;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }

        emit SuccessfulWithdrawal(msg.sender, amount);
    }

    /// @dev A modifier that restricts a function's execution to the contract owner.
    modifier onlyOwnerBank() {
        if (msg.sender != _ownerBank) {
            revert NotOwnerBank(msg.sender);
        }
        _;
    }

  
    function currentBalance() external view onlyOwnerBank returns (uint256 current) {
        return _kipuBankBalance;
    }

    function getDeposits() external view onlyOwnerBank returns (uint256 current) {
        return _countDeposits;
    }

    function getWithdrawals() external view onlyOwnerBank returns (uint256 current) {
        return _countWithdrawals;
    }

    modifier onlyAccountOwner(address account) {
        if (msg.sender != account && msg.sender != _ownerBank) {
            revert NotAccountOwner(msg.sender);
        }
        _;
    }

    function getBalance(address account) external view onlyAccountOwner(account) returns (uint256) {
        return _balances[account];
    }
}