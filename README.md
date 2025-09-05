# AshNFT - NFT交易平台

AshNFT 是一个基于区块链的 NFT 交易平台，允许用户创建、购买、出售和展示非同质化代币(NFT)。该项目结合了以太坊智能合约和现代化的前端技术，为用户提供完整的 NFT 交易体验。

## 项目概述

AshNFT 项目包括两个主要部分：
1. **智能合约层** - 基于 Solidity 编写的 ERC721 NFT 合约，部署在以太坊区块链上
2. **前端应用层** - 基于 Next.js 构建的现代化 Web 应用，提供用户友好的界面

## 核心功能

- NFT 创建和铸造
- NFT 上下架管理
- NFT 购买和销售
- NFT 展示和浏览
- 交易记录追踪
- 创作者识别和展示
- 钱包集成 (MetaMask 等)

## 技术栈

### 智能合约
- Solidity ^0.8.20
- OpenZeppelin Contracts ^5.4.0
- Hardhat 开发环境
- Ethers.js ^6.15.0

### 前端应用
- Next.js 15.5.2
- React 19.1.0
- TypeScript
- Tailwind CSS
- Ethers.js ^6.15.0
- Framer Motion 动画库

### 其他工具
- IPFS (通过 Pinata) 用于存储 NFT 元数据和媒体文件
- MetaMask 钱包集成

## 项目结构

```
ashnft/
├── contracts/          # 智能合约代码
│   ├── contracts/      # Solidity 合约源文件
│   └── ...
├── frontend/           # 前端应用代码
│   ├── public/         # 静态资源
│   ├── src/
│   │   ├── app/        # 页面和组件
│   │   ├── components/ # 可复用组件
│   │   └── lib/        # 工具库
│   └── ...
└── README.md
```

## 环境要求

- Node.js >= 18.0.0
- npm 或 yarn
- MetaMask 钱包（用于测试和交互）

## 快速开始

### 1. 克隆项目

```bash
git clone <项目地址>
cd ashnft
```

### 2. 启动智能合约（本地测试网络）

首先确保你在 `contracts` 目录中：

```bash
cd contracts
npm install
npx hardhat node
```

这将启动一个本地以太坊测试网络。

### 3. 部署智能合约

在另一个终端窗口中，部署合约到本地网络：

```bash
cd contracts
npx hardhat run scripts/deploy.ts --network localhost
```

记下部署后的合约地址，需要在前端配置中使用。

### 4. 启动前端应用

在另一个终端窗口中，启动前端开发服务器：

```bash
cd frontend
npm install
npm run dev
```

前端应用将在 `http://localhost:3000` 上运行。

### 5. 配置前端环境变量

确保在 `frontend/.env.local` 文件中配置了正确的合约地址：

```
NEXT_PUBLIC_ASHNFT_ADDRESS_LOCAL=你的合约地址
```

## 使用说明

1. 使用 MetaMask 连接到本地测试网络
2. 获取测试 ETH（通常 Hardhat 会提供测试账户）
3. 连接钱包到应用
4. 创建新 NFT（上传图片和元数据到 IPFS）
5. 上架 NFT 进行销售
6. 浏览和购买其他用户的 NFT

## 开发指南

### 智能合约开发

- 合约源文件位于 `contracts/contracts/AshNFT.sol`
- 使用 Hardhat 进行编译、测试和部署
- 可以通过 `npx hardhat test` 运行测试

### 前端开发

- 使用 Next.js App Router 结构
- 主要页面位于 `frontend/src/app/` 目录下
- 服务层位于 `frontend/src/app/services/` 目录下
- 组件位于 `frontend/src/components/` 目录下

## 注意事项

- 该项目当前配置为本地开发环境
- 如需部署到测试网或主网，需要相应地修改配置
- IPFS 功能需要有效的 Pinata API 密钥

---

**该项目仅供参考学习，切勿用于商业化**