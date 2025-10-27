# 🚀 Deploy Guide - KipuBankV2 na Sepolia

Este guia explica como fazer o deploy e testar o contrato KipuBankV2 na rede Sepolia.

## 📋 Pré-requisitos

1. **Foundry instalado** ✅ (já instalado)
2. **Conta com ETH na Sepolia** (obter em faucets)
3. **Chaves de API configuradas**

## 🔧 Configuração

### 1. Criar arquivo .env

Copie o arquivo de exemplo e preencha com suas credenciais:

```bash
cp .env.example .env
```

### 2. Preencher variáveis no .env

```env
# RPC URL - Obter em: https://www.alchemy.com/ ou https://infura.io/
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/SUA_CHAVE_AQUI

# Private Key - NUNCA compartilhe ou commite!
# Exportar do MetaMask: Conta > Detalhes da Conta > Exportar Chave Privada
PRIVATE_KEY=0xSUA_PRIVATE_KEY_AQUI

# Etherscan API Key - Para verificação do contrato
# Obter em: https://etherscan.io/myapikey
ETHERSCAN_API_KEY=SUA_CHAVE_ETHERSCAN_AQUI

# Parâmetros do Contrato
BANK_CAP_USD=1000000      # Cap total do banco em USD
MAX_TRANSACTION_USD=10000  # Limite máximo por transação em USD
```

### 3. Obter ETH de teste na Sepolia

Faucets disponíveis:
- [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
- [Infura Sepolia Faucet](https://www.infura.io/faucet/sepolia)
- [Chainlink Faucet](https://faucets.chain.link/sepolia)

## 🎯 Deploy

### 1. Compilar o contrato

```bash
forge build
```

### 2. Deploy na Sepolia

```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

**O que acontece:**
- ✅ Compila o contrato
- ✅ Faz deploy na Sepolia
- ✅ Verifica o código no Etherscan
- ✅ Salva o endereço em `deployments/sepolia.txt`

### 3. Verificar o deploy

Após o deploy, você verá uma mensagem como:

```
KipuBank deployed at: 0x1234567890123456789012345678901234567890
```

Copie este endereço e visualize no Etherscan:
```
https://sepolia.etherscan.io/address/SEU_ENDERECO_AQUI
```

## 🧪 Testes na Sepolia

### 1. Atualizar endereço do contrato

Edite `script/TestOnSepolia.s.sol` e atualize:

```solidity
address constant KIPUBANK_ADDRESS = 0xSEU_ENDERECO_DO_DEPLOY;
```

### 2. Executar testes

```bash
forge script script/TestOnSepolia.s.sol --rpc-url sepolia --broadcast
```

**Testes executados:**
1. ✅ Verificar informações do contrato
2. ✅ Depositar 0.001 ETH
3. ✅ Sacar 0.0005 ETH
4. ✅ Verificar saldos e contadores

### 3. Verificar transações

Todas as transações aparecerão no Etherscan. Você verá:
- Endereço do contrato
- Histórico de transações
- Eventos emitidos
- Código fonte verificado

## 📊 Monitoramento

### Ver informações do contrato

```bash
# Total Value USD depositado
cast call SEU_ENDERECO "totalValueUSD()" --rpc-url sepolia

# Seu saldo de ETH no banco
cast call SEU_ENDERECO "balances(address,address)" SUA_CARTEIRA 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE --rpc-url sepolia

# Número de depósitos
cast call SEU_ENDERECO "depositCount(address)" SUA_CARTEIRA --rpc-url sepolia
```

### Fazer depósito manual

```bash
cast send SEU_ENDERECO "deposit()" --value 0.001ether --private-key $PRIVATE_KEY --rpc-url sepolia
```

### Fazer saque manual

```bash
cast send SEU_ENDERECO "withdraw(uint256)" 500000000000000 --private-key $PRIVATE_KEY --rpc-url sepolia
# 500000000000000 = 0.0005 ETH em wei
```

## 🔍 Comandos Úteis

### Ver logs detalhados do deploy

```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast -vvvv
```

### Simular deploy sem executar (dry-run)

```bash
forge script script/Deploy.s.sol --rpc-url sepolia
```

### Verificar contrato manualmente

```bash
forge verify-contract SEU_ENDERECO src/KipuBankV2.sol:KipuBank \
  --constructor-args $(cast abi-encode "constructor(uint256,uint256,address)" 1000000 10000 0x694AA1769357215DE4FAC081bf1f309aDC325306) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia
```

## ⚠️ Segurança

- ✅ **NUNCA** commite o arquivo `.env` (já está no .gitignore)
- ✅ Use uma carteira separada para testes
- ✅ Não use private key de contas com fundos reais
- ✅ Revogue permissões após testes se necessário

## 🎉 Próximos Passos

Após deploy e testes bem-sucedidos:

1. ✅ Adicionar tokens ERC20 para teste
2. ✅ Testar limites de transação
3. ✅ Testar diferentes condições de mercado
4. ✅ Documentar interações no Etherscan

## 📚 Recursos

- [Foundry Book](https://book.getfoundry.sh/)
- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses)
- [Alchemy](https://www.alchemy.com/)

---

