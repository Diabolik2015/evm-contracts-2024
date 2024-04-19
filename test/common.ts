import hre from "hardhat";
import {BigNumberish} from "ethers/lib.esm";

export async function deployVrfCoordinatorMock() {
    const VRFMock = await hre.ethers.getContractFactory("VRFCoordinatorV2Mock");
    const _BASE_FEE= BigInt(10 ** 17)
    const _GAS_PRICE_LINK= BigInt(10 ** 9)
    return await VRFMock.deploy(_BASE_FEE, _GAS_PRICE_LINK);
}

export async function deployCircularityRandomizer(subscriptionId: BigNumberish, keyHash: string, vrfCoordinator: string ) {
    const cyclixRandomizer = await hre.ethers.getContractFactory("CyclixRandomizer");
    return await cyclixRandomizer.deploy(subscriptionId, keyHash, vrfCoordinator);
}

export async function deployVrfAndCreateSubscription() {
    const vrfMock = await deployVrfCoordinatorMock();
    await vrfMock.createSubscription();
    await vrfMock.fundSubscription(await vrfMock.getLatestSubscriptionIdCreated(), BigInt(10 ** 18));
    return vrfMock;
}

export async function deployAndSetupCyclixRandomizer() {
    const vrfMock = await deployVrfAndCreateSubscription();
    const cyclixRandomizer = await deployCircularityRandomizer(
        await vrfMock.getLatestSubscriptionIdCreated(),
        "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
        await vrfMock.getAddress()
    );
    await vrfMock.addConsumer(await vrfMock.getLatestSubscriptionIdCreated(), await cyclixRandomizer.getAddress());
    return { cyclixRandomizer, vrfMock };
}

export function toEtherBigInt(amount: string | number) {
    return BigInt(Number(amount) * 10 ** 9 * 10 ** 9);
}