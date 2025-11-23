import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-ignition";
import "@nomicfoundation/hardhat-ignition-ethers";
import "@nomicfoundation/hardhat-verify";
import dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: false,
      evmVersion: "cancun",
    },
  },
  remappings: {
    "@openzeppelin/": "lib/openzeppelin-contracts/",
    "@layerzero/": "lib/layerzero-contracts/",
    "@hyperlane/": "lib/hyperlane-monorepo/",
  },
  paths: {
    sources: "./contracts",
    tests: "./test/hardhat",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  networks: {
    hardhat: {
      type: "edr-simulated",
      ...(process.env.MAINNET_RPC_URL && {
        forking: {
          url: process.env.MAINNET_RPC_URL,
          enabled: true,
        },
      }),
      chainId: 31337,
    },
    ...(process.env.MAINNET_RPC_URL && {
      mainnet: {
        type: "http",
        url: process.env.MAINNET_RPC_URL,
        accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        chainId: 1,
      },
    }),
    ...(process.env.SEPOLIA_RPC_URL && {
      sepolia: {
        type: "http",
        url: process.env.SEPOLIA_RPC_URL,
        accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        chainId: 11155111,
      },
    }),
    ...(process.env.POLYGON_RPC_URL && {
      polygon: {
        type: "http",
        url: process.env.POLYGON_RPC_URL,
        accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        chainId: 137,
      },
    }),
    ...(process.env.ARBITRUM_RPC_URL && {
      arbitrum: {
        type: "http",
        url: process.env.ARBITRUM_RPC_URL,
        accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        chainId: 42161,
      },
    }),
    ...(process.env.OPTIMISM_RPC_URL && {
      optimism: {
        type: "http",
        url: process.env.OPTIMISM_RPC_URL,
        accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        chainId: 10,
      },
    }),
    ...(process.env.BASE_RPC_URL && {
      base: {
        type: "http",
        url: process.env.BASE_RPC_URL,
        accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        chainId: 8453,
      },
    }),
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      arbitrum: process.env.ARBISCAN_API_KEY || "",
      optimism: process.env.OPTIMISTIC_ETHERSCAN_API_KEY || "",
      base: process.env.BASESCAN_API_KEY || "",
    },
  },
  ignition: {
    strategyConfig: {
      create2: {
        salt: process.env.DEPLOYMENT_SALT || "usdx-deployment-salt",
      },
    },
  },
};

export default config;
