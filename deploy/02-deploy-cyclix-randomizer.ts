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
    if (chainId == 31337) {
        args = [0, "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61", hre.ethers.ZeroAddress];
    } else if (chainId == 43113) {
        args = [2366, "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61", "0x2eD832Ba664535e5886b75D64C46EB9a228C2610"];
    }

    const contractDeployed = await deploy("CyclixRandomizer", {
        from: deployer,
        log: true,
        // @ts-ignore
        args: args,
        nonce: "pending",
    });

    if (chainId == 43113) {
        const vrfCoordinator: VRFCoordinatorV2Interface = await hre.ethers.getContractAt("VRFCoordinatorV2Interface", "0x2eD832Ba664535e5886b75D64C46EB9a228C2610")
        console.log("Subscription For Vrf on Avalanche Fuji")
        const subscribedConsumers = (await vrfCoordinator.getSubscription(2366))[3];
        if (!subscribedConsumers.includes(contractDeployed.address)) {
            console.log("Adding Consumer to VRF")
            await vrfCoordinator.addConsumer(2366, contractDeployed.address)
        }
    }
};

export default deployCyclixRandomizer;
deployCyclixRandomizer.tags = ["all", "lottery"];