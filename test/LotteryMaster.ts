import {expect} from "chai";
import hre from "hardhat";
import {BigNumberish} from "ethers";
import {deployAndSetupCyclixRandomizer, toEtherBigInt} from "./common";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/src/signers";
import {TestUsdt} from "../typechain-types";

let owner: HardhatEthersSigner
let player1: HardhatEthersSigner
let player2: HardhatEthersSigner
let player3: HardhatEthersSigner
let referral1: HardhatEthersSigner
let referral2: HardhatEthersSigner
let referral3: HardhatEthersSigner
let usdtContract: TestUsdt



describe("Lottery Master", function () {
  // We covered that scenario with stats model that it will not go over 70% or have a very small probability that it does
  // Follow the % given
  // So for referral pool if A have 30 entry,  B have 10 entry
  //
  // Then we will only pick 10% which is 4 entries
  //
  // So pick one from the 40 entries
  // Pick one from 39 entries
  // Pick one from 38 entries
  // Pick one from 37 entries
  async function deployLotteryMaster() {
    const { cyclixRandomizer, vrfMock } = await deployAndSetupCyclixRandomizer();
    const usdt = await hre.ethers.getContractFactory("TestUsdt");
    usdtContract = await usdt.deploy(10 ** 6);
    // @ts-ignore
    [owner, player1, player2, player3, referral1, referral2, referral3 ] = await hre.ethers.getSigners()

    const usdtDecimals = await usdtContract.decimals();
    await usdtContract.transfer(player1.address, toEtherBigInt(1000))
    await usdtContract.transfer(player2.address, toEtherBigInt(1000))
    await usdtContract.transfer(player3.address, toEtherBigInt(1000))
    await usdtContract.transfer(referral1.address, toEtherBigInt(1000))
    await usdtContract.transfer(referral2.address, toEtherBigInt(1000))
    await usdtContract.transfer(referral3.address, toEtherBigInt(1000))

    const contract = await hre.ethers.getContractFactory("LotteryMaster");

    const lotteryMaster = await contract.deploy(cyclixRandomizer.getAddress(), usdtContract, 10, 50)

    await usdtContract.connect(player1).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(player2).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(player3).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(referral1).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(referral2).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(referral3).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    
    return { lotteryMaster, cyclixRandomizer, vrfMock };
  }

  async function deployLotteryMasterAndStartRound() {
    const deployed = await deployLotteryMaster();
    await deployed.lotteryMaster.startNewRound()
    return deployed
  }

  describe("Behaviour", function () {
    it("Deploy", async function () {
      const { lotteryMaster } = await deployLotteryMaster();
      expect(lotteryMaster.getAddress()).to.not.equal(0);
    });

    it("Should be able to Start Lottery Round", async function () {
      const { lotteryMaster } = await deployLotteryMasterAndStartRound();
      let currentRound = await lotteryMaster.getCurrentRound();
      expect(currentRound.id).equal(1);
    });

    it("Should be able to Make wallets Join Lottery Round", async function () {
      const { lotteryMaster } = await deployLotteryMasterAndStartRound();

      await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 37, hre.ethers.ZeroAddress);
      let round = await lotteryMaster.rounds(0);
      expect(round.ticketsCount).equal(1);

      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 37, player1.address);
      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 37, player1.address);
      round = await lotteryMaster.rounds(0);
      expect(round.ticketsCount).equal(3);
      expect(round.referralMaxNumbers).equal(2);
      expect(round.pricePool).equal(toEtherBigInt(30));
      expect(await usdtContract.balanceOf(lotteryMaster)).equal(toEtherBigInt(30))
    });

    it("Should be able to change Round Participation Price", async function () {
      const { lotteryMaster } = await deployLotteryMasterAndStartRound();

    });

    it("Should be able to give free rounds to a list of wallets", async function () {

    });

    it("Should retain the retain correct amounts of the lottery pools", async function () {

    })

    it("Should be able to retain referrals", async function () {

    })

    it("Should be able to draw winners", async function () {

    })
  })
});
