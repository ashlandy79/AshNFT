import "@nomicfoundation/hardhat-ethers";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";

async function main() {
  // 获取部署者账户
  const [deployer] = await ethers.getSigners();

  console.log("部署账户地址:", deployer.address);
  console.log("账户余额:", (await deployer.provider.getBalance(deployer.address)).toString());

  // 部署 AshNFT 合约
  console.log("\n正在部署 AshNFT 合约...");
  const AshNFT = await ethers.getContractFactory("AshNFT");
  const maxSupply = 10000n; // 设置最大供应量为10000
  const ashNFT = await AshNFT.deploy(deployer.address, maxSupply);
  await ashNFT.waitForDeployment();
  
  const ashNFTAddress = await ashNFT.getAddress();
  console.log("AshNFT 合约部署地址:", ashNFTAddress);
  
  // 获取 AshNFT 合约实例用于查询
  const ashNFTContract = await ethers.getContractAt("AshNFT", ashNFTAddress);
  console.log("合约名称:", await ashNFTContract.NAME());
  console.log("合约符号:", await ashNFTContract.SYMBOL());
  console.log("最大供应量:", (await ashNFTContract.maxSupply()).toString());
  console.log("合约所有者:", await ashNFTContract.owner());

  // 输出环境变量格式的地址
  console.log("\n--- 合约地址 (请更新您的 .env.local 文件) ---");
  console.log(`NEXT_PUBLIC_ASHNFT_ADDRESS_LOCAL=${ashNFTAddress}`);

  // 尝试更新前端的 .env.local 文件
  updateFrontendEnvFile(ashNFTAddress);

  console.log("\n部署完成!");
}

function updateFrontendEnvFile(ashNFTAddress: string) {
  const envFilePath = path.join(__dirname, "..", "..", "frontend", ".env.local");
  
  try {
    let envContent = "";
    
    // 检查文件是否存在
    if (fs.existsSync(envFilePath)) {
      // 读取现有内容
      envContent = fs.readFileSync(envFilePath, "utf8");
      console.log("找到现有的 .env.local 文件");
    } else {
      console.log("未找到现有的 .env.local 文件，将创建新文件");
    }
    
    // 更新或添加 AshNFT 地址
    if (envContent.includes("NEXT_PUBLIC_ASHNFT_ADDRESS_LOCAL=")) {
      envContent = envContent.replace(
        /NEXT_PUBLIC_ASHNFT_ADDRESS_LOCAL=.*$/m,
        `NEXT_PUBLIC_ASHNFT_ADDRESS_LOCAL=${ashNFTAddress}`
      );
    } else {
      if (envContent && !envContent.endsWith('\n')) {
        envContent += '\n';
      }
      envContent += `NEXT_PUBLIC_ASHNFT_ADDRESS_LOCAL=${ashNFTAddress}\n`;
    }
    
    // 写入更新后的内容
    fs.writeFileSync(envFilePath, envContent);
    console.log("已成功更新 frontend/.env.local 文件");
  } catch (error) {
    console.error("更新 frontend/.env.local 文件时出错:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });