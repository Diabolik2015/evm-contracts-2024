import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import hre, { network } from "hardhat";
import {VRFCoordinatorV2Interface} from "../typechain-types";
import {deployCircularityRandomizer, deployVrfCoordinatorMock} from "../test/common";

const deployCyclixRandomizer: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();
    const chainId = network.config.chainId;
    const testing = true
    // @ts-ignore
    let args = []
    if (chainId == 1337) {
        args = [0, "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61", hre.ethers.ZeroAddress];
        await deploy("CyclixRandomizer", {
            from: deployer,
            log: true,
            // @ts-ignore
            args: args,
            nonce: "pending",
        });
    }

    if (chainId == 43114) {
        args = [2366, "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61", "0x2eD832Ba664535e5886b75D64C46EB9a228C2610"];
        let contractDeployed = await deploy("CyclixRandomizer", {
            from: deployer,
            log: true,
            // @ts-ignore
            args: args,
            nonce: "pending",
        });
        await new Promise(f => setTimeout(f, 2000));
        const vrfCoordinator: VRFCoordinatorV2Interface = await hre.ethers.getContractAt("VRFCoordinatorV2Interface", "0x2eD832Ba664535e5886b75D64C46EB9a228C2610")
        console.log("Subscription For Vrf on Avalanche Fuji")
        const subscribedConsumers = (await vrfCoordinator.getSubscription(2366))[3];
        if (!subscribedConsumers.includes(contractDeployed.address)) {
            console.log("Adding Consumer to VRF")
            await vrfCoordinator.addConsumer(2366, contractDeployed.address)
        }
    } else {
        const VRFMockDeployed = await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: [0, 0],
            nonce: "pending",
        });
        await new Promise(f => setTimeout(f, 2000));
        const vrfMock = await hre.ethers.getContractAt("VRFCoordinatorV2Mock", VRFMockDeployed.address)
        if (Number(await vrfMock.getLatestSubscriptionIdCreated()) == 0) {
            console.log("Creating New Subscription to VRF Mock")
            await vrfMock.createSubscription();
        }
        await new Promise(f => setTimeout(f, 2000));
        let contractDeployed = await deploy("CyclixRandomizer", {
            from: deployer,
            log: true,
            // @ts-ignore
            args: [
                1,
                "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
                VRFMockDeployed.address
            ],
            nonce: "pending",
        });
        await new Promise(f => setTimeout(f, 2000));
        if (!(await vrfMock.consumerIsAdded(await vrfMock.getLatestSubscriptionIdCreated(), contractDeployed.address))) {
            console.log("Adding Consumer to VRF Mock")
            await vrfMock.addConsumer(await vrfMock.getLatestSubscriptionIdCreated(), contractDeployed.address);
        }
    }
    await new Promise(f => setTimeout(f, 2000));
};

export default deployCyclixRandomizer;
deployCyclixRandomizer.tags = ["all", "lottery"];