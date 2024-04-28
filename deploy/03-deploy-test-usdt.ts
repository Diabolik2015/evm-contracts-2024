import {DeployFunction} from "hardhat-deploy/dist/types";
import {HardhatRuntimeEnvironment} from "hardhat/types";

const deployTestUsdt: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();

    await deploy("TestUsdt", {
        from: deployer,
        log: true,
        args: [],
        nonce: "pending",
    });
};

export default deployTestUsdt;
deployTestUsdt.tags = ["all", "lottery"];