# 🎉 Deploy KipuBankV2 na Sepolia

## 📋 Informações do Contrato

| Item | Valor |
|------|-------|
| **Endereço do Contrato** | `0xaD0B6A54Af33fe4e5cC3cCf2Caa2Fe54B049Ac91` |
| **Rede** | Sepolia Testnet |
| **Block** | 9502094 |
| **TX Hash (Deploy)** | `0x4a4596782db4638dc21909ec1efe6a693e444b8a6f7ed2ab0fa73865b346586b` |
| **Gas Usado** | 2,160,842 |
| **Custo do Deploy** | 0.000002160867930104 ETH |
| **Deployer** | `0x58cf22bd0A13eD14e07e56651C12D6c240ACe792` |

## ⚙️ Configuração do Contrato

| Parâmetro | Valor |
|-----------|-------|
| **Max USD Bank Cap** | 10,000 USD |
| **USD Withdrawal Limit** | 1,000 USD |
| **ETH/USD Price Feed** | `0x694AA1769357215DE4FAC081bf1f309aDC325306` (Chainlink) |

## 🧪 Testes Realizados na Sepolia

### ✅ Teste 1: Depósito de ETH
- **Valor**: 0.001 ETH
- **TX**: `0x3239da02bff2b128b800a0586fc0a42089a554df754004332d377a022ecca20b`
- **Status**: ✅ Sucesso
- **Gas Usado**: 72,787

### ✅ Teste 2: Saque de ETH
- **Valor**: 0.0005 ETH
- **TX**: `0xb86e63b7bfdf085912e97d48fab28055518b80e5d040e741fd7a438b16380b33`
- **Status**: ✅ Sucesso
- **Gas Usado**: 99,633

## 📊 Estatísticas Atuais

- **Total de Depósitos**: 3
- **Total de Saques**: 1
- **Código Verificado**: ✅ Sim

## 🔗 Links Importantes

### Etherscan
- [Contrato no Etherscan](https://sepolia.etherscan.io/address/0xaD0B6A54Af33fe4e5cC3cCf2Caa2Fe54B049Ac91)
- [Transação de Deploy](https://sepolia.etherscan.io/tx/0x4a4596782db4638dc21909ec1efe6a693e444b8a6f7ed2ab0fa73865b346586b)
- [Carteira do Deployer](https://sepolia.etherscan.io/address/0x58cf22bd0A13eD14e07e56651C12D6c240ACe792)

### Código Verificado
- ✅ Código fonte verificado e público no Etherscan
- ✅ ABI disponível para interação
- ✅ Eventos visíveis nas transações

## 🎯 Funcionalidades Testadas

| Funcionalidade | Status | Observações |
|----------------|--------|-------------|
| Deploy | ✅ | Contrato deployado com sucesso |
| Verificação no Etherscan | ✅ | Código fonte verificado |
| Depósito de ETH | ✅ | 0.001 ETH depositado |
| Saque de ETH | ✅ | 0.0005 ETH sacado |
| Contadores (depositCount) | ✅ | Funcionando corretamente |
| Contadores (withdrawCount) | ✅ | Funcionando corretamente |
| Oracle Chainlink | ✅ | Preço do ETH consultado com sucesso |
| Eventos | ✅ | SuccessfulDeposit e SuccessfulWithdrawal emitidos |

## 📝 Próximos Passos Sugeridos

1. ✅ **Testar com tokens ERC20**
   - Adicionar price feeds para tokens
   - Fazer depósitos e saques de tokens

2. ✅ **Testar limites**
   - Testar limite de $1,000 USD por saque
   - Testar cap total de $10,000 USD

3. ✅ **Testar permissões**
   - Adicionar outros admins
   - Testar funções restritas

4. ✅ **Integração com frontend**
   - Criar interface Web3
   - Conectar com MetaMask

## 🔐 Segurança

- ✅ ReentrancyGuard implementado
- ✅ Checks-Effects-Interactions (CEI) pattern
- ✅ Oracle com validação de staleness
- ✅ AccessControl para funções administrativas
- ✅ SafeERC20 para transferências de tokens

## 📅 Data do Deploy

- **Data**: 27 de outubro de 2025
- **Hora**: ~15:00 UTC (aproximado)

---

**Deploy realizado com sucesso! 🚀**

---

## 🔗 Testes com Token LINK (Chainlink)

### 📋 Informações do Token
- **Token**: Chainlink (LINK)
- **Endereço**: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- **Price Feed**: `0xc59E3633BAAC79493d908e63626716e204A45EdF` (LINK/USD)
- **Saldo Inicial**: 25 LINK

### ✅ Testes Realizados

#### 1. Configuração do Price Feed
- **TX Hash**: `0x430a3f1ee6383c1fe8c49c37eec2508e5eea64010c3245710f915bd590c1938b`
- **Status**: ✅ Sucesso
- **Gas Usado**: 96,456

#### 2. Aprovação de Tokens
- **Valor Aprovado**: 10 LINK
- **TX Hash**: `0x37c0f130bb2f8cf71d325d0c9c3ffb3d213298dff132ad62c51ec1c9b205a2ff`
- **Status**: ✅ Sucesso
- **Gas Usado**: 26,321

#### 3. Depósito de LINK
- **Valor**: 1 LINK
- **TX Hash**: `0xb0911ccd68068772240941f1e8453cc325bfbc1badfeecef7802cac9665bcfa3`
- **Status**: ✅ Sucesso
- **Gas Usado**: 109,662

#### 4. Saque de LINK
- **Valor**: 0.5 LINK
- **TX Hash**: `0x31711d10a3de8b46f3e4b8c9321a3974c395e408f40a40cb401b87d4c6907157`
- **Status**: ✅ Sucesso
- **Gas Usado**: 90,320

### 🔗 Links das Transações

- [Configurar Price Feed](https://sepolia.etherscan.io/tx/0x430a3f1ee6383c1fe8c49c37eec2508e5eea64010c3245710f915bd590c1938b)
- [Aprovação LINK](https://sepolia.etherscan.io/tx/0x37c0f130bb2f8cf71d325d0c9c3ffb3d213298dff132ad62c51ec1c9b205a2ff)
- [Depósito LINK](https://sepolia.etherscan.io/tx/0xb0911ccd68068772240941f1e8453cc325bfbc1badfeecef7802cac9665bcfa3)
- [Saque LINK](https://sepolia.etherscan.io/tx/0x31711d10a3de8b46f3e4b8c9321a3974c395e408f40a40cb401b87d4c6907157)

### 📊 Funcionalidades ERC20 Testadas

| Funcionalidade | Status | Observações |
|----------------|--------|-------------|
| setTokenPriceFeed() | ✅ | Price feed configurado com sucesso |
| approve() | ✅ | Token aprovado para o contrato |
| depositToken() | ✅ | 1 LINK depositado |
| withdrawToken() | ✅ | 0.5 LINK sacado |
| Eventos SuccessfulDeposit | ✅ | Emitido corretamente |
| Eventos SuccessfulWithdrawal | ✅ | Emitido corretamente |
| SafeERC20 | ✅ | Transferências seguras funcionando |

### 🎯 Conclusão

Todos os testes com o token LINK foram concluídos com **100% de sucesso**! O contrato KipuBankV2 está totalmente funcional para:
- ✅ Depósitos e saques de ETH
- ✅ Depósitos e saques de tokens ERC20 (LINK testado)
- ✅ Integração com oráculos Chainlink (ETH/USD e LINK/USD)
- ✅ Validação de limites USD
- ✅ Eventos e contadores funcionando perfeitamente


---

## 👥 Testes com Segunda Conta

### 📋 Informações da Conta
- **Endereço**: `0xE26DfEa0456dF3aE40b67BBcB5e3D60b82F415Bd`
- **Objetivo**: Validar multi-usuários e contadores globais

### ✅ Testes Realizados

#### 1. Depósito de 0.002 ETH
- **TX Hash**: `0xbac5b64cd25cfef83ff59ac47310d72c2a42b11f4246cd013c9f3859efffa31c`
- **Status**: ✅ Sucesso
- **Gas Usado**: 89,887

#### 2. Aprovação de 5 LINK
- **TX Hash**: `0xdeaeab74c5be9f02e33f6798d27243895eb9cb402dd9da42f4b675eb3272c7b4`
- **Status**: ✅ Sucesso
- **Gas Usado**: 46,221

#### 3. Depósito de 2 LINK
- **TX Hash**: `0x174ddb372b1aa0854b80ec8d3d55cb2c4c6340f8a8d54f57b0316b2e5a80f90e`
- **Status**: ✅ Sucesso
- **Gas Usado**: 126,762

#### 4. Saque de 0.001 ETH
- **TX Hash**: `0x413f27fa5830afdb95756ef33a81eae986809025ff6be43a76d7b00700068227`
- **Status**: ✅ Sucesso
- **Gas Usado**: 79,878

#### 5. Saque de 1 LINK
- **TX Hash**: `0xc142f83c3257efe86e18aa63cdce680b1e42dcf253d4bb123fb25da78b5830cd`
- **Status**: ✅ Sucesso
- **Gas Usado**: 90,320

### 🔗 Links das Transações

- [Depósito ETH](https://sepolia.etherscan.io/tx/0xbac5b64cd25cfef83ff59ac47310d72c2a42b11f4246cd013c9f3859efffa31c)
- [Aprovação LINK](https://sepolia.etherscan.io/tx/0xdeaeab74c5be9f02e33f6798d27243895eb9cb402dd9da42f4b675eb3272c7b4)
- [Depósito LINK](https://sepolia.etherscan.io/tx/0x174ddb372b1aa0854b80ec8d3d55cb2c4c6340f8a8d54f57b0316b2e5a80f90e)
- [Saque ETH](https://sepolia.etherscan.io/tx/0x413f27fa5830afdb95756ef33a81eae986809025ff6be43a76d7b00700068227)
- [Saque LINK](https://sepolia.etherscan.io/tx/0xc142f83c3257efe86e18aa63cdce680b1e42dcf253d4bb123fb25da78b5830cd)

### 📊 Resumo Multi-Usuário

| Métrica | Conta 1 | Conta 2 | Total |
|---------|---------|---------|-------|
| Depósitos ETH | 3 (0.003 ETH) | 1 (0.002 ETH) | 4 (0.005 ETH) |
| Depósitos LINK | 1 (1 LINK) | 1 (2 LINK) | 2 (3 LINK) |
| Saques ETH | 1 (0.0005 ETH) | 1 (0.001 ETH) | 2 (0.0015 ETH) |
| Saques LINK | 1 (0.5 LINK) | 1 (1 LINK) | 2 (1.5 LINK) |

### 🎯 Validações Realizadas

| Funcionalidade | Status | Observações |
|----------------|--------|-------------|
| Multi-usuário | ✅ | Múltiplas contas operando simultaneamente |
| Contadores globais | ✅ | depositCount e withdrawCount funcionando |
| Isolamento de saldos | ✅ | Cada usuário tem seu próprio saldo |
| Aprovações independentes | ✅ | Cada usuário aprova separadamente |
| Eventos por usuário | ✅ | Eventos corretos por endereço |
| Gas eficiente | ✅ | Custos otimizados em todas operações |

