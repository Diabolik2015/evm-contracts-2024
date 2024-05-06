import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { network } from "hardhat";
import {VRFCoordinatorV2Interface} from "../typechain-types";

const deployCyclixRandomizer: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();
    const chainId = network.config.chainId;

    // @ts-ignore
    let args = []
    if (chainId != 31337) {
        console.log("This deployment script is only for some networks")
        args = [0, "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61", hre.ethers.ZeroAddress];
    } else { // @ts-ignore
        if (chainId == 43113) {
            args = [2366, "0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887", "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE"];
        }
    }

    const contractDeployed = await deploy("CyclixRandomizer", {
        from: deployer,
        log: true,
        // @ts-ignore
        args: args,
        nonce: "pending",
    });
};

export default deployCyclixRandomizer;
deployCyclixRandomizer.tags = ["all", "lottery"];