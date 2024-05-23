import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {LotteryRoundCreator} from "../typechain-types";

const deployLotteryRoundCreator: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    await deploy("LotteryRoundCreator", {
        from: deployer,
        log: true,
        args: [true],
        nonce: "pending",
    });
    await new Promise(f => setTimeout(f, 2000));
};

export default deployLotteryRoundCreator;
deployLotteryRoundCreator.tags = ["all", "lottery"];