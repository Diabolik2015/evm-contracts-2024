import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";

const deployLotteryReader: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    await deploy("LotteryReader", {
        from: deployer,
        log: true,
        args: [],
        nonce: "pending",
    });
};

export default deployLotteryReader;
deployLotteryReader.tags = ["all", "lottery"];