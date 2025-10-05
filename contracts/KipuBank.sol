// SPDX-License-Identifier: MIT
pragma solidity >0.8.26;

/**
 * @title KipuBank
 * @author Jonathan Chacon
 * @notice Educational contract simulating a personal ETH vault with global deposit and withdrawal limits.
 * @dev Part of TP2 Module 2 - Ethereum Developer Pack.
 * @custom:security Do NOT use in production.
 */
contract KipuBank {
    /*///////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////*/

    /// @notice Maximum global deposit allowed in the bank, set during deployment.
    uint256 public immutable i_bankCap;

    /// @notice Maximum withdrawal allowed per transaction.
    uint256 public immutable i_withdrawLimit;

    /// @notice Total ETH deposited in the contract.
    uint256 private s_totalDeposited;

    /// @notice Mapping storing individual user balances.
    mapping(address => uint256) private s_balances;

    /// @notice Counter of deposits made.
    uint256 public s_totalDepositsCount;

    /// @notice Counter of withdrawals made.
    uint256 public s_totalWithdrawalsCount;

    /// @notice Flag for reentrancy guard
    bool private s_locked;

    /*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a user makes a successful deposit.
    /// @param user Address of the user who made the deposit.
    /// @param amount Amount of ETH deposited (in wei).
    event KipuBankDeposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user makes a successful withdrawal.
    /// @param user Address of the user who made the withdrawal.
    /// @param amount Amount of ETH withdrawn (in wei).
    event KipuBankWithdraw(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                             ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Occurs when a deposit exceeds the bank's global deposit limit.
    /// @param amount Amount attempted to deposit.
    /// @param remainingLimit Remaining deposit capacity of the bank.
    error KipuBankDepositLimitExceeded(uint256 amount, uint256 remainingLimit);

    /// @notice Occurs when a user attempts to withdraw more than their balance.
    /// @param balance Current available balance of the user.
    /// @param requested Amount the user attempted to withdraw.
    error KipuBankInsufficientBalance(uint256 balance, uint256 requested);

    /// @notice Occurs when a withdrawal exceeds the per-transaction withdrawal limit.
    /// @param requested Amount attempted to withdraw.
    /// @param limit Maximum allowed per transaction.
    error KipuBankWithdrawalLimitExceeded(uint256 requested, uint256 limit);

    /// @notice Occurs when an ETH transfer fails during withdrawal.
    /// @param user Address attempting the withdrawal.
    /// @param amount Amount attempted to withdraw.
    /// @param data Revert data returned from the failed call.
    error KipuBankWithdrawalFailed(address user, uint256 amount, bytes data);

    /// @notice Occurs when an ETH transfer fails in a private transfer function.
    /// @param errorData Revert data from the failed call.
    error KipuBankTransferFailed(bytes errorData);

    /// @notice Occurs when a zero ETH deposit is attempted.
    error InvalidZeroDeposit();

    /*//////////////////////////////////////////////////////////////
                             MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates that the contract does not exceed the global deposit limit.
    /// @param _amount Amount of ETH being deposited.
    modifier validateCap(uint256 _amount) {
        if (s_totalDeposited + _amount > i_bankCap)
            revert KipuBankDepositLimitExceeded(_amount, i_bankCap - s_totalDeposited);
        _;
    }

    /// @notice Prevents reentrancy attacks on sensitive functions.
    modifier reentrancyGuard() {
        if (s_locked) revert("Reentrancy detected");
        s_locked = true;
        _;
        s_locked = false;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with a global deposit cap and withdrawal limit.
     * @param _bankCap Maximum total deposits allowed in the bank.
     * @param _withdrawLimit Maximum ETH withdrawal per transaction.
     */
    constructor(uint256 _bankCap, uint256 _withdrawLimit) {
        i_bankCap = _bankCap;
        i_withdrawLimit = _withdrawLimit;
    }

    /*//////////////////////////////////////////////////////////////
                             MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows users to deposit ETH into their personal vault.
     * @dev Uses validateCap modifier to ensure global limit is not exceeded.
     */
    function deposit() external payable validateCap(msg.value) {
        if (msg.value == 0) revert InvalidZeroDeposit();
        s_balances[msg.sender] += msg.value;
        s_totalDeposited += msg.value;
        unchecked { ++s_totalDepositsCount; }
        emit KipuBankDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to withdraw ETH from their vault respecting limits.
     * @param _amount Amount of ETH to withdraw.
     */
    function withdraw(uint256 _amount) external reentrancyGuard {
        uint256 userBalance = s_balances[msg.sender];
        if (_amount > userBalance)
            revert KipuBankInsufficientBalance(userBalance, _amount);
        if (_amount > i_withdrawLimit)
            revert KipuBankWithdrawalLimitExceeded(_amount, i_withdrawLimit);

        s_balances[msg.sender] = userBalance - _amount;
        unchecked { ++s_totalWithdrawalsCount; }

        (bool success, bytes memory data) = msg.sender.call{value: _amount}("");
        if (!success) revert KipuBankWithdrawalFailed(msg.sender, _amount, data);

        emit KipuBankWithdraw(msg.sender, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                             PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Handles secure ETH transfers to a recipient.
     * @param _recipient Address to receive ETH.
     * @param _amount Amount of ETH to transfer.
     */
    function _transferEth(address payable _recipient, uint256 _amount) private {
        (bool success, bytes memory data) = _recipient.call{value: _amount}("");
        if (!success) revert KipuBankTransferFailed(data);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current balance of a user.
     * @param _user Address of the user.
     * @return balance Current balance of the user in wei.
     */
    function getBalance(address _user) external view returns (uint256 balance) {
        return s_balances[_user];
    }

    /*//////////////////////////////////////////////////////////////
                             RECEIVE & FALLBACK
    //////////////////////////////////////////////////////////////*/

    /// @notice Called when ETH is sent without data.
    receive() external payable validateCap(msg.value) {
        if (msg.value == 0) revert InvalidZeroDeposit();
        s_balances[msg.sender] += msg.value;
        s_totalDeposited += msg.value;
        unchecked { ++s_totalDepositsCount; }
        emit KipuBankDeposit(msg.sender, msg.value);
    }

    /// @notice Called when ETH is sent with data or a function that does not exist is called.
    fallback() external payable validateCap(msg.value) {
        if (msg.value == 0) return;
        s_balances[msg.sender] += msg.value;
        s_totalDeposited += msg.value;
        unchecked { ++s_totalDepositsCount; }
        emit KipuBankDeposit(msg.sender, msg.value);
    }
}
