# 🏦 KipuBankV2

A secure, multi-token DeFi vault with USD-based limits powered by Chainlink oracles.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue.svg)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Latest-green.svg)](https://book.getfoundry.sh/)

> 📚 **[Complete Documentation]([./wiki/README.md](https://github.com/rochaevertondev/KipuBankV2/wiki))** | 📖 **[Contract Guide]([./wiki/Contrato-KipuBank.md](https://github.com/rochaevertondev/KipuBankV2/wiki/Contrato%E2%80%90KipuBank))** | 🧪 **[Testing Guide]([./wiki/Testes-KipuBank.md](https://github.com/rochaevertondev/KipuBankV2/wiki/Testes%E2%80%90KipuBank))**

## ✨ Features

- 💰 **Multi-token vault** - Support for ETH and ERC-20 tokens
- 📊 **USD-based limits** - Bank cap ($10k) and withdrawal limit ($1k per tx)
- 🔮 **Chainlink oracles** - Real-time price feeds with staleness validation
- 🛡️ **Security first** - ReentrancyGuard, CEI pattern, SafeERC20
- 🎭 **Role-based access** - Owner and Admin with specific permissions
- ⚡ **Gas optimized** - O(1) total USD tracking with cache
- 📜 **EIP-7528 compliant** - Canonical ETH address standard
- 🔢 **Fee-on-transfer support** - Handles tokens with transfer fees

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.20

### Installation

```bash
# Clone repository
git clone https://github.com/rochaevertondev/KipuBankV2.git
cd KipuBankV2

# Install dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test
```

## 🧪 Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test
forge test --match-test testDeposit

# Generate gas report
forge test --gas-report

# Coverage report
forge coverage
```

**Current test coverage:** 4/4 tests passing ✅

## 📋 Contract Overview

### Key Limits

| Parameter | Value | Description |
|-----------|-------|-------------|
| Bank Cap | $10,000 USD | Maximum total value in vault |
| Withdrawal Limit | $1,000 USD | Maximum per transaction |
| Native Cap | Configurable | Optional wei limit per tx |
| Oracle Age | 1 hour | Maximum data staleness |

### Main Functions

- `deposit()` - Deposit ETH
- `withdraw(uint256)` - Withdraw ETH
- `depositToken(address, uint256)` - Deposit ERC-20
- `withdrawToken(address, uint256)` - Withdraw ERC-20
- `getBalance(address)` - View ETH balance
- `getBalanceInUsd(address, address)` - View balance in USD

**📖 [Read the full contract documentation](https://github.com/rochaevertondev/KipuBankV2/wiki)**

## 🌐 Deployment

### Sepolia Testnet

**Chainlink Price Feeds:**
- ETH/USD: `0x694AA1769357215DE4FAC081bf1f309aDC325306`
- LINK/USD: `0xc59E3633BAAC79493d908e63626716e204A45EdF`

```bash
# Configure environment
cp .env.example .env
# Add PRIVATE_KEY, SEPOLIA_RPC_URL, ETHERSCAN_API_KEY

# Deploy and verify
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

## 📚 Documentation

### For Beginners

Start here if you're new to Solidity or Foundry:

1. 📖 **[Contract Guide](https://github.com/rochaevertondev/KipuBankV2/wiki/Contrato%E2%80%90KipuBank)** - Complete contract explanation
   - Architecture and design patterns
   - Function-by-function breakdown
   - Security features explained
   - Code examples with calculations

2. 🧪 **[Testing Guide](https://github.com/rochaevertondev/KipuBankV2/wiki/Testes%E2%80%90KipuBank)** - Learn testing with Foundry
   - How to write tests in Solidity
   - Understanding mocks and fixtures
   - Foundry cheatcodes reference
   - AAA pattern and best practices

3. 📚 **[Wiki Home](./wiki/README.md)** - Complete index and quick reference

### Advanced Topics

- Security patterns (CEI, ReentrancyGuard)
- Gas optimization techniques
- Oracle integration best practices
- Role-based access control

## �� Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) - Secure smart contract library
- [Chainlink](https://chain.link/) - Decentralized oracle network
- [Foundry](https://getfoundry.sh/) - Blazing fast Ethereum toolkit

## 👨‍💻 Author

**Rocha Everton**

- 📧 GitHub: [@rochaevertondev](https://github.com/rochaevertondev/)
- 💼 LinkedIn: [rochaevertondev](https://linkedin.com/in/rochaevertondev/)

---

⭐ **Star this repo** if you find it helpful!
