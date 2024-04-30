import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {LotteryReader} from "../typechain-types";
import hre from "hardhat";
import { LotteryRound } from "../typechain-types/contracts/LotteryMaster.sol/LotteryRound";

const deployLotteryRound: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    let lotteryMasterDeployment = await hre.deployments.get("LotteryMaster");

    let lotteryRoundDeployment = await deploy("LotteryRound", {
        from: deployer,
        log: true,
        args: [hre.ethers.ZeroAddress, 86400 * 5],
        nonce: "pending",
    });

    const lotteryRoundFactory = await hre.ethers.getContractFactory("LotteryRound");
    const lotteryRound = lotteryRoundFactory.attach(lotteryRoundDeployment.address) as LotteryRound;
    await lotteryRound.transferOwnership(lotteryMasterDeployment.address);
};

export default deployLotteryRound;
deployLotteryRound.tags = ["all", "lottery"];