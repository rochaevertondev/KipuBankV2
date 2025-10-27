# 📚 Wiki do KipuBankV2

Bem-vindo à documentação completa do projeto KipuBankV2!

---

## 📖 Índice

### 1. [Entendendo o Contrato KipuBank](./Contrato-KipuBank.md)

Guia completo sobre o contrato inteligente:

- 🎯 O que é o KipuBank?
- 🏗️ Arquitetura do contrato
- 🔌 Interface do Oracle (Chainlink)
- 📦 Variáveis de estado
- 🗂️ Mapeamentos (Mappings)
- 🎭 Sistema de Roles
- 💰 Funções principais (deposit, withdraw, etc.)
- 🔍 Funções de visualização
- 🔐 Funções administrativas
- 🎨 Eventos
- 🛡️ Segurança
- 📊 Fluxo completo de depósito
- 🎓 Conceitos importantes

---

### 2. [Guia de Testes com Foundry](./Testes-KipuBank.md)

Tutorial completo sobre testes em Solidity:

- 🎯 O que é Foundry?
- 📁 Estrutura de testes
- 🎭 Mock do Oracle
- 🧩 Estrutura do contrato de teste
- 🔧 Função setUp()
- 🎨 Padrão AAA (Arrange-Act-Assert)
- 🧪 Exemplos de testes
- 🛠️ Cheatcodes do Foundry
- 📊 Assertions comuns
- 🔍 Comandos do Foundry
- 📚 Boas práticas
- 🎓 Exercícios práticos

---

## 🚀 Quick Start

### Pré-requisitos

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.20
- Git

### Instalação

```bash
# Clone o repositório
git clone https://github.com/rochaevertondev/KipuBankV2.git
cd KipuBankV2

# Instale dependências
forge install

# Compile
forge build

# Rode os testes
forge test
```

---

## 📂 Estrutura do Projeto

```
KipuBankV2/
├── src/
│   └── KipuBankV2.sol          # Contrato principal
├── test/
│   └── KipuBank.t.sol          # Testes
├── lib/
│   ├── forge-std/              # Biblioteca de testes
│   └── openzeppelin-contracts/ # Contratos seguros
├── foundry.toml                # Configuração do Foundry
├── README.md                   # Documentação principal
└── wiki/                       # Documentação detalhada
    ├── README.md               # Este arquivo
    ├── Contrato-KipuBank.md    # Guia do contrato
    └── Testes-KipuBank.md      # Guia de testes
```

---

## 🎯 Recursos do KipuBank

### Características Principais

- ✅ **Multi-token support**: ETH nativo + ERC-20
- ✅ **Oracle integration**: Preços reais via Chainlink
- ✅ **USD-based limits**: Limites em dólares (cap e withdrawal)
- ✅ **Role-based access**: Owner e Admin com permissões específicas
- ✅ **Security features**: ReentrancyGuard, CEI pattern, SafeERC20
- ✅ **Gas optimized**: Cache O(1) para total USD
- ✅ **EIP-7528 compliant**: Usa endereço canônico para ETH
- ✅ **Oracle hygiene**: Validação completa de staleness

### Limites de Segurança

| Limite | Valor | Descrição |
|--------|-------|-----------|
| Bank Cap | $10,000 USD | Máximo total no banco |
| Withdrawal Limit | $1,000 USD | Máximo por saque |
| Native Cap | Configurável | Limite de wei por tx (opcional) |
| Oracle Age | 1 hora | Idade máxima dos dados do oracle |

---

## 🧪 Testes

### Executar Testes

```bash
# Todos os testes
forge test

# Com detalhes
forge test -vv

# Com traces completos
forge test -vvvv

# Teste específico
forge test --match-test testDeposit

# Com gas report
forge test --gas-report

# Coverage
forge coverage
```

### Testes Implementados

- ✅ `testDeposit()` - Depósito básico
- ✅ `testWithdraw()` - Saque válido
- ✅ `testWithdrawExceedsLimit()` - Limite USD
- ✅ `testDepositCount()` - Contador de operações

---

## 🌐 Deployment

### Sepolia Testnet

```bash
# Configurar .env
PRIVATE_KEY=sua_private_key
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=sua_api_key

# Deploy
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

### Chainlink Price Feeds (Sepolia)

- **ETH/USD**: `0x694AA1769357215DE4FAC081bf1f309aDC325306`
- **LINK/USD**: `0xc59E3633BAAC79493d908e63626716e204A45EdF`

---

## 📊 Casos de Uso

### Para Usuários

1. **Depositar ETH**: Guarde ETH com segurança
2. **Sacar ETH**: Retire com limites de proteção
3. **Depositar Tokens**: Suporte multi-asset
4. **Ver Saldo USD**: Acompanhe valor em dólares

### Para Admins

1. **Recuperar Fundos**: Ajustar saldos em emergências
2. **Gerenciar Usuários**: Auxiliar em casos de perda de acesso

### Para Owners

1. **Configurar Price Feeds**: Adicionar novos tokens
2. **Gerenciar Admins**: Adicionar/remover permissões
3. **Ajustar Limites**: Configurar cap de wei
4. **Monitorar**: Ver totais e estatísticas

---

## 🔗 Links Úteis

### Documentação

- [Solidity Docs](https://docs.soliditylang.org/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts)
- [Chainlink Price Feeds](https://docs.chain.link/data-feeds)
- [Foundry Book](https://book.getfoundry.sh/)

### Padrões (EIPs)

- [EIP-7528](https://eips.ethereum.org/EIPS/eip-7528) - ETH Address
- [EIP-20](https://eips.ethereum.org/EIPS/eip-20) - Token Standard
- [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535) - Diamond Standard

### Comunidade

- [GitHub Repository](https://github.com/rochaevertondev/KipuBankV2)
- [LinkedIn](https://linkedin.com/in/rochaevertondev/)

---

## 🎓 Aprendizado

### Iniciantes

Se você está começando com Solidity:

1. Leia o [Contrato-KipuBank.md](./Contrato-KipuBank.md) primeiro
2. Compile o projeto: `forge build`
3. Rode os testes: `forge test -vv`
4. Leia [Testes-KipuBank.md](./Testes-KipuBank.md)
5. Experimente modificar os testes

### Intermediários

Se você já sabe Solidity:

1. Analise a arquitetura do contrato
2. Estude os padrões de segurança (CEI, ReentrancyGuard)
3. Implemente novos testes
4. Faça fork e adicione funcionalidades

### Avançados

Se você é experiente:

1. Revise a segurança do contrato
2. Otimize consumo de gas
3. Adicione features avançadas (flash loans, yield farming)
4. Contribua com PRs

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-feature`
3. Commit suas mudanças: `git commit -m 'Add: nova feature'`
4. Push para a branch: `git push origin feature/nova-feature`
5. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](../LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**Rocha Everton (DEV)**

- 📧 GitHub: [@rochaevertondev](https://github.com/rochaevertondev/)
- 💼 LinkedIn: [rochaevertondev](https://linkedin.com/in/rochaevertondev/)

---

## ⭐ Suporte

Se este projeto te ajudou, considere dar uma ⭐ no [GitHub](https://github.com/rochaevertondev/KipuBankV2)!

---

**Última atualização:** 27 de Outubro de 2025
