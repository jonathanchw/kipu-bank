# KipuBank

## Description

**KipuBank** is an educational Ethereum smart contract simulating a personal ETH vault. Users can deposit and withdraw ETH while respecting **global deposit caps** and **per-transaction withdrawal limits**.  

### Key Features

The contract includes:

- **`deposit()`** – Allows users to deposit ETH into their personal vault, respecting the global bank cap.  
- **`withdraw(uint256 _amount)`** – Lets users withdraw ETH up to their balance and the per-transaction withdrawal limit, with a reentrancy guard for security.  
- **`validateCap` modifier** – Ensures deposits do not exceed the contract’s global deposit cap (`i_bankCap`).  
- **`receive()` and `fallback()` functions** – Support direct ETH transfers to the contract.  
- **Event logging** – Emits `KipuBankDeposit` and `KipuBankWithdraw` events for all successful operations.  
- **Per-user balances** – Stores user balances on-chain for transparency and verification.

**⚠️ Note:** This contract is **for educational purposes only** and should **not be used in production**.

---

## Deployment Instructions

1. Open [Remix IDE](https://remix.ethereum.org/).
2. Create a new file named `KipuBank.sol` and paste the contract code.
3. In the **Solidity Compiler** tab:
   - Select compiler version `0.8.26` or higher.
   - Compile the contract.
4. In the **Deploy & Run Transactions** tab:
   - Select the environment: **Remix VM** for testing, or **Injected Web3** to deploy on a testnet/mainnet.
   - Set constructor parameters:
   - `_bankCap` → Maximum global deposit. **Input in wei**, e.g., for 100 ETH, enter `100e18`.  
   - `_withdrawLimit` → Maximum ETH per withdrawal. **Input in wei**, e.g., for 5 ETH, enter `5e18`.
   - Deploy the contract.
5. Once deployed, the contract address will appear under **Deployed Contracts**.

---

## Interacting with the Contract

### 1. Depositing ETH

#### Using `deposit()` function
- Enter the amount of ETH in the **Value** field.
- Click the `deposit()` button.
- Emits `KipuBankDeposit` event and updates your personal balance.

#### Using `receive()` or `fallback()`
- Send ETH **directly to the contract address**:
  - Without data → triggers `receive()`.
  - With data or to a non-existent function → triggers `fallback()`.
- Deposits are automatically credited to your balance and events are emitted.

### 2. Withdrawing ETH

- Use the `withdraw(uint256 _amount)` function.
- Enter the amount of ETH to withdraw. **Input in wei**, and it must not exceed your balance or `_withdrawLimit`.  
- Example: To withdraw 3 ETH, enter `3e18`.
- A `KipuBankWithdraw` event is emitted upon success.
- Withdrawals are protected by a **reentrancy guard**.

### 3. Checking Balances

- Call `getBalance(address _user)` to see the current balance of any user.

### 4. Event Logs

- All deposits trigger `KipuBankDeposit(address user, uint256 amount)`.
- All withdrawals trigger `KipuBankWithdraw(address user, uint256 amount)`.

---

## Notes

- The **global deposit cap** (`i_bankCap`) ensures the bank never holds more ETH than allowed.
- The **withdrawal limit** (`i_withdrawLimit`) prevents excessively large withdrawals per transaction.
- The contract is **safe against reentrancy attacks** using the `reentrancyGuard` modifier.

---
## Example on Sepolia

**Deployed contract:**  
Address: `0x1DCac42439c0B722508883F04E0E81f985892A5A`  
[View on Etherscan](https://sepolia.etherscan.io/address/0x1DCac42439c0B722508883F04E0E81f985892A5A#code)

1. Deployed contract with constructor parameters (input in wei):  
   - `_bankCap = 100e18` (100 ETH)  
   - `_withdrawLimit = 10e18` (10 ETH)

2. Interacting from a test account:  
   - Deposit `10e18` (10 ETH) using `deposit()`.  
   - Deposit `2e18` (2 ETH) by sending ETH directly to the contract (triggers `receive()`).

3. Withdraw `3e18` (3 ETH) using `withdraw()`.

4. Check your balance using `getBalance(accountAddress)` → should reflect `9e18` (9 ETH) remaining.

---

## License

MIT License
