import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {LotteryMaster, LotteryReader, LotteryRoundCreator} from "../typechain-types";

const deployLotteryMaster: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    let cyclixRandomizer = await hre.deployments.get("CyclixRandomizer");
    let lotteryReader = await hre.deployments.get("LotteryReader");
    let testUsdt = await hre.deployments.get("TestUsdt");
    let lotteryRoundCreator = await hre.deployments.get("LotteryRoundCreator");

    const lotteryMaster = await deploy("LotteryMaster", {
        from: deployer,
        log: true,
        args: [cyclixRandomizer.address, lotteryReader.address, lotteryRoundCreator.address, testUsdt.address, 10, true],
        nonce: "pending",
    });
    const lotteryMasterFactory = await hre.ethers.getContractFactory("LotteryMaster");
    const lotteryMasterContract = lotteryMasterFactory.attach(lotteryMaster.address) as LotteryMaster;

    const lotteryReaderFactory = await hre.ethers.getContractFactory("LotteryReader");
    const lotteryReaderContract = lotteryReaderFactory.attach(lotteryReader.address) as LotteryReader;
    if (await lotteryReaderContract.lotteryMaster() != lotteryMaster.address) {
        await lotteryReaderContract.connect(await hre.ethers.getSigner(deployer)).setLotteryMaster(lotteryMaster.address);
        console.log("Lottery Reader rightly attached to Lottery Master:", lotteryReader.address, lotteryMaster.address, await lotteryReaderContract.lotteryMaster());
    }
    const lotteryRoundCreatorFactory = await hre.ethers.getContractFactory("LotteryRoundCreator");
    const lotteryRoundCreatorContract = lotteryRoundCreatorFactory.attach(lotteryRoundCreator.address) as LotteryRoundCreator;

    const [owner] = await hre.ethers.getSigners();
    if ((await lotteryRoundCreatorContract.owner()) != lotteryMaster.address) {
        console.log("Attempting to transfer ownership of Lottery Round Creator to Lottery Master:", lotteryRoundCreator.address, lotteryMaster.address, await lotteryRoundCreatorContract.owner());
        await lotteryRoundCreatorContract.connect(owner).transferOwnership(lotteryMaster.address);
        console.log("Lottery Round Creator rightly transferred to Lottery Master:", lotteryRoundCreator.address, lotteryMaster.address, await lotteryRoundCreatorContract.owner());
    }
    await new Promise(f => setTimeout(f, 2000));
};

export default deployLotteryMaster;
deployLotteryMaster.tags = ["all", "lottery"];