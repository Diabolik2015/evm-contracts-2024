import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {LotteryMaster, LotteryReader, LotteryRoundCreator} from "../typechain-types";
import {LotteryRound} from "../typechain-types/contracts/LotteryMaster.sol/LotteryRound";

const deployLotteryRoundCreator: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    await deploy("LotteryRoundCreator", {
        from: deployer,
        log: true,
        args: [],
        nonce: "pending",
    });
};

export default deployLotteryRoundCreator;
deployLotteryRoundCreator.tags = ["all", "lottery"];