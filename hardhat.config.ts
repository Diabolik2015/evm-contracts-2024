import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "hardhat-deploy";
import "@nomicfoundation/hardhat-toolbox";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
        chainId: 1337,
    },
    avalancheFuji: {
      chainId: 43113,
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY_DEVELOPER??""],
      saveDeployments: true,
    }
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  // @ts-ignore
  settings: {
    optimizer: {
      enabled: true,
      runs: 1,
    },
  },
};

export default config;
