# 🏦 KipuBankV2

A secure, multi-token DeFi vault with USD-based limits powered by Chainlink oracles.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue.svg)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Latest-green.svg)](https://book.getfoundry.sh/)

> 📚 **[Complete Documentation](https://github.com/rochaevertondev/KipuBankV2/wiki)** 

## ✨ Features

- 💰 **Multi-token vault** - Support for ETH and ERC-20 tokens
- 📊 **USD-based limits** - Bank cap ($10k) and withdrawal limit ($1k per tx)
- 🔮 **Chainlink oracles** - Real-time price feeds with staleness validation
- 🛡️ **Security first** - ReentrancyGuard, CEI pattern, SafeERC20
- 🎭 **Role-based access** - Owner and Admin with specific permissions
- ⚡ **Gas optimized** - O(1) total USD tracking with cache
- 📜 **EIP-7528 compliant** - Canonical ETH address standard
- 🔢 **Fee-on-transfer support** - Handles tokens with transfer fees


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
