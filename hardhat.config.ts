import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  // @ts-ignore
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000,
    },
  },
};

export default config;
