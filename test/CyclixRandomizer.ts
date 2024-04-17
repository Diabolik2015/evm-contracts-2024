import {expect} from "chai";
import hre from "hardhat";
import {BigNumberish} from "ethers";
import {deployAndSetupCyclixRandomizer, deployVrfAndCreateSubscription, deployVrfCoordinatorMock } from "./common";

describe("Cyclix Randomizer", function () {

  describe("Behaviour", function () {
    it("Deploy VRF Mock", async function () {
      const vrfMock = await deployVrfCoordinatorMock();
      expect(vrfMock.getAddress()).to.not.equal(0);
    });

    it("Should be able to setup VRF subscription", async function () {
      const vrfMock = await deployVrfCoordinatorMock();
      await vrfMock.createSubscription();
      expect(await vrfMock.getLatestSubscriptionIdCreated()).equal(BigInt(1));
    });

    it("Should be able to fund VRF subscription", async function () {
      const vrfMock = await deployVrfAndCreateSubscription()
      expect(await vrfMock.getLatestSubscriptionIdCreated()).equal(BigInt(1));
      await vrfMock.fundSubscription(await vrfMock.getLatestSubscriptionIdCreated(), BigInt(10 ** 18));
    });

    it("Deploy CyclixRandomizer", async function () {
      const { cyclixRandomizer} = await deployAndSetupCyclixRandomizer();
      expect(cyclixRandomizer.getAddress()).to.not.equal(0);
    });

    it ("Should be able to fulfill random words", async function () {
      const { cyclixRandomizer , vrfMock } = await deployAndSetupCyclixRandomizer();
      await cyclixRandomizer.requestRandomWords(1);

      const requestId = await cyclixRandomizer.getLastRequestIdForCaller();
      expect(requestId).is.not.equal(0);

      let requestStatus = await cyclixRandomizer.getRequestStatus(requestId)
      expect(requestStatus.fulfilled).is.equal(false);

      const randomWords = 1001;
      // await vrfMock.fulfillRandomWords(requestId, await cyclixRandomizer.getAddress());
      await vrfMock.fulfillRandomWordsWithOverride(await cyclixRandomizer.getLastRequestIdForCaller(), await cyclixRandomizer.getAddress(), [randomWords]);
      requestStatus = await cyclixRandomizer.getRequestStatus(requestId)
      expect(requestStatus.fulfilled).is.equal(true);
      expect(requestStatus.randomWords[0]).is.equal(BigInt(randomWords));
    });
  })
});
