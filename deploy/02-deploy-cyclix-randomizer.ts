import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { network } from "hardhat";

const deployCyclixRandomizer: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();
    const chainId = network.config.chainId;

    let args = []
    if (chainId != 31337) {
        console.log("This deployment script is only for some networks")
        args = [0, "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61", hre.ethers.ZeroAddress];
    } else if (chainId == 43113) {
        args = [2366, "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61", "0x2eD832Ba664535e5886b75D64C46EB9a228C2610"];
    }

    await deploy("CyclixRandomizer", {
        from: deployer,
        log: true,
        args: args,
        nonce: "pending",
    });
};

export default deployCyclixRandomizer;
deployCyclixRandomizer.tags = ["all", "lottery"];