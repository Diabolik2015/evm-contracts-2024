import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {LotteryReader} from "../typechain-types";
import hre from "hardhat";
import { LotteryRound } from "../typechain-types/contracts/LotteryMaster.sol/LotteryRound";

const deployLotteryRound: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    await deploy("LotteryRound", {
        from: deployer,
        log: true,
        args: [hre.ethers.ZeroAddress, 86400 * 5],
        nonce: "pending",
    });
};

export default deployLotteryRound;
deployLotteryRound.tags = ["all", "lottery"];