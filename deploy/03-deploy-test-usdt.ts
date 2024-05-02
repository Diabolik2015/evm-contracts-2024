import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {LotteryMaster, TestUsdt} from "../typechain-types";

const deployTestUsdt: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    const usdtDeployed = await deploy("TestUsdt", {
        from: deployer,
        log: true,
        args: [],
        nonce: "pending",
    });

    const bankDeployed = await deploy("UsdtTestBank", {
        from: deployer,
        log: true,
        args: [usdtDeployed.address],
        nonce: "pending",
    });
    const usdtMasterFactory = await hre.ethers.getContractFactory("TestUsdt");
    const usdtContract = usdtMasterFactory.attach(usdtDeployed.address) as TestUsdt;
    if (await usdtContract.balanceOf(bankDeployed.address) == BigInt(0)) {
        await usdtContract.transfer(bankDeployed.address, BigInt(10 ** 6 * 10 ** 18));
    }
};

export default deployTestUsdt;
deployTestUsdt.tags = ["all", "lottery"];