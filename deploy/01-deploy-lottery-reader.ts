import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {network} from "hardhat";

const deployLotteryReader: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();
    console.log("Deploying on  network:", network.name, " - id: ", network.config.chainId, )
    await deploy("LotteryReader", {
        from: deployer,
        log: true,
        args: [],
        nonce: "pending",
    });
    await new Promise(f => setTimeout(f, 2000));
};

export default deployLotteryReader;
deployLotteryReader.tags = ["all", "lottery"];