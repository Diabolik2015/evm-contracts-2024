import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";

const deployLotteryMaster: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    let cyclixRandomizer = await hre.deployments.get("CyclixRandomizer");
    let lotteryReader = await hre.deployments.get("LotteryReader");
    let testUsdt = await hre.deployments.get("TestUsdt");

    const lotteryMaster = await deploy("LotteryMaster", {
        from: deployer,
        log: true,
        args: [cyclixRandomizer.address, lotteryReader.address, testUsdt.address, 10],
        nonce: "pending",
    });


    const lotteryReaderFactory = await hre.ethers.getContractFactory("LotteryReader");
    const lotteryContract = await lotteryReaderFactory.attach(lotteryReader.address);
    await lotteryContract.setLotteryMaster(lotteryMaster.address);
    console.log("Lottery Reader rightly attached to Lottery Master:", lotteryReader.address, lotteryMaster.address, await lotteryContract.lotteryMaster());
};

export default deployLotteryMaster;
deployLotteryMaster.tags = ["all", "lottery"];