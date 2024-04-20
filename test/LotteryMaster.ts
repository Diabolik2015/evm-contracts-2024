import {expect} from "chai";
import hre from "hardhat";
import {deployAndSetupCyclixRandomizer, toEtherBigInt} from "./common";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/src/signers";
import {LotteryMaster, TestUsdt} from "../typechain-types";

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

    await usdtContract.transfer(player1.address, toEtherBigInt(1000))
    await usdtContract.transfer(player2.address, toEtherBigInt(1000))
    await usdtContract.transfer(player3.address, toEtherBigInt(1000))
    await usdtContract.transfer(referral1.address, toEtherBigInt(1000))
    await usdtContract.transfer(referral2.address, toEtherBigInt(1000))
    await usdtContract.transfer(referral3.address, toEtherBigInt(1000))
    const signers = await hre.ethers.getSigners()
    for (let i = 7; i < signers.length; i++) {
      await usdtContract.transfer(signers[i].address, toEtherBigInt(1000))
    }


    const contract = await hre.ethers.getContractFactory("LotteryMaster");

    const lotteryMaster = await contract.deploy(cyclixRandomizer.getAddress(), usdtContract, 10, 50)
    await lotteryMaster.addBankWallet(await owner.getAddress())
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

  async function addPlayersToLotteryRound(lotteryMaster: LotteryMaster) {
    await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 69], 26, referral1);
    await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 69], 24, referral2);
    await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 14], 26, referral3);
    await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 14], 24, referral1);
    await lotteryMaster.connect(player3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [36, 2, 3, 13, 14], 26, referral1);
    await lotteryMaster.connect(player3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 13, 14], 24, referral1);
    await lotteryMaster.connect(referral1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 69], 26, hre.ethers.ZeroAddress);
    await lotteryMaster.connect(referral1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 13, 14], 24, hre.ethers.ZeroAddress);
    await lotteryMaster.connect(referral2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 13, 14], 24, hre.ethers.ZeroAddress);
    await lotteryMaster.connect(referral3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 14], 26, hre.ethers.ZeroAddress);
  }

  async function executeChainLinkVrf(roundId: number, winningNumbers: number[], winningPowerNumber: number, referralIndexes: number[],
                                     lotteryMaster: any, cyclixRandomizer: any, vrfMock: any) {
    const wordsFromVrf = []
    for (const winningNumber of winningNumbers) {
      wordsFromVrf.push(winningNumber - 1)
    }
    wordsFromVrf.push(winningPowerNumber - 1)
    for (const referralIndex of referralIndexes) {
      wordsFromVrf.push(referralIndex - 1)
    }
    // @ts-ignore
    await vrfMock.fulfillRandomWordsWithOverride(await lotteryMaster.publicRoundRandomNumbersRequestId(roundId),
        await cyclixRandomizer.getAddress(), wordsFromVrf)
  }

  function checkNumberExistInArray(array: number[], number: number) {
    return array.some(n => n === number)
  }

  function tierForResult(numberOfRightNumbers: number, powerNumberFound: number) {
    if (numberOfRightNumbers === 5 && powerNumberFound) {
      return 0
    } else if (numberOfRightNumbers === 5) {
      return 1
    } else if (numberOfRightNumbers === 4 && powerNumberFound) {
      return 2
    } else if (numberOfRightNumbers === 4) {
      return 3
    } else if (numberOfRightNumbers === 3 && powerNumberFound) {
      return 4
    } else if (numberOfRightNumbers === 3) {
      return 5
    } else {
      return -1
    }
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

    it("Should validate numbers to Join Lottery Round", async function () {
      const {lotteryMaster} = await deployLotteryMasterAndStartRound();

      await expect(lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 70], 24, hre.ethers.ZeroAddress)).to.be.revertedWith("Invalid numbers");
      await expect(lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [0, 4, 6, 10, 21], 24, hre.ethers.ZeroAddress)).to.be.revertedWith("Invalid numbers");
      await expect(lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 27, hre.ethers.ZeroAddress)).to.be.revertedWith("Invalid power number");
    })

    it("Should be able to Make wallets Join Lottery Round", async function () {
      const { lotteryMaster } = await deployLotteryMasterAndStartRound();
      const initialOwnerBalance = await usdtContract.balanceOf(owner.address)

      await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, hre.ethers.ZeroAddress);
      let round = await lotteryMaster.rounds(0);
      round = await lotteryMaster.rounds(0);
      expect(round.ticketsCount).equal(1);

      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      round = await lotteryMaster.rounds(0);
      expect(round.ticketsCount).equal(3);
      expect(round.referralCounts).equal(2);
      expect((await usdtContract.balanceOf(owner.address)) - initialOwnerBalance).equal(toEtherBigInt(30))
    });

    it("Should be able to give free rounds to a list of wallets", async function () {
      const { lotteryMaster } = await deployLotteryMasterAndStartRound();
      const initialOwnerBalance = await usdtContract.balanceOf(owner.address)

      await lotteryMaster.addFreeRound([player1.address, player3.address])
      await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player2.address);
      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      await lotteryMaster.connect(player3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      const round = await lotteryMaster.rounds(0);
      expect(round.ticketsCount).equal(3);
      expect(round.referralCounts).equal(3);
      expect((await usdtContract.balanceOf(owner.address)) - initialOwnerBalance).equal(toEtherBigInt(10))
    });

    it("Should rightly split winning pools", async function () {
      const { lotteryMaster } = await deployLotteryMasterAndStartRound();
      const initialOwnerBalance = await usdtContract.balanceOf(owner.address)

      await lotteryMaster.addFreeRound([player1.address, player3.address])
      const players = [player1, player2, player3]
      for (let i = 0; i < 10; i++) {
        let playerId = i % 3;
        await lotteryMaster.connect(players[playerId]).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, players[(i + 1) % 3]);
      }
      expect((await usdtContract.balanceOf(owner.address)) - initialOwnerBalance).equal(toEtherBigInt(80))
      const round = await lotteryMaster.rounds(0);
      expect(round.ticketsCount).to.equal(10)
      expect(await lotteryMaster.poolForHighVictoryTier(round.id, 0)).to.equal(toEtherBigInt((80 * 0.7 * 0.35).toPrecision(3)))
      expect(await lotteryMaster.poolForHighVictoryTier(round.id, 1)).to.equal(toEtherBigInt((80 * 0.7 * 0.15).toPrecision(3)))
      expect(await lotteryMaster.poolForHighVictoryTier(round.id, 2)).to.equal(toEtherBigInt((80 * 0.7 * 0.1).toPrecision(3)))
      expect(await lotteryMaster.priceForLowVictoryTier(round.id, 3)).to.equal(toEtherBigInt((80 * 0.7 * 0.05).toPrecision(3)))
      expect(await lotteryMaster.priceForLowVictoryTier(round.id, 4)).to.equal(toEtherBigInt((80 * 0.7 * 0.02).toPrecision(3)))
      expect(await lotteryMaster.priceForLowVictoryTier(round.id, 5)).to.equal(toEtherBigInt((80 * 0.7 * 0.002).toPrecision(3)))
      expect(await lotteryMaster.poolForReferral(round.id)).to.equal(toEtherBigInt((80 * 0.15).toPrecision(3)))
      expect(await lotteryMaster.tokenHoldersPoolAmount(round.id)).to.equal(toEtherBigInt((80 * 0.10).toPrecision(3)))
      expect(await lotteryMaster.treasuryPoolAmount(round.id)).to.equal(toEtherBigInt((80 * 0.5).toPrecision(3)))
    })

    it("Should have always different numbers for draw also if the randomizer return two times the same number", async function () {
      const winningPowerNumber = 26
      const winningNumbers = [1, 1, 3, 4, 69]
      const roundId = 1
      const { lotteryMaster, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      await hre.ethers.provider.send("evm_increaseTime", [50])

      await lotteryMaster.closeRound()

      await executeChainLinkVrf(roundId, winningNumbers, winningPowerNumber, [], lotteryMaster, cyclixRandomizer, vrfMock);

      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.fulfilled

      let publicRoundWinningNumbers = (await lotteryMaster.getCurrentRound()).roundNumbers;
      expect(publicRoundWinningNumbers[0]).to.equal(winningNumbers[0]);
      expect(publicRoundWinningNumbers[1]).to.not.equal(winningNumbers[1]);
    })

    it("Should be able to draw public round winners", async function () {
      const winningPowerNumber = 26
      const winningNumbers = [1, 2, 3, 4, 69]
      const referralIndexes = [1]
      const roundId = 1

      const { lotteryMaster, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      await addPlayersToLotteryRound(lotteryMaster);

      const referralCountTickets = await lotteryMaster.roundReferralTicketsByAddressCount(roundId, referral1.address)
      const referralTickets = []
      for (let i = 0; i < referralCountTickets; i++) {
        referralTickets.push(await lotteryMaster.referralTickets(await lotteryMaster.roundReferralTicketsByAddress(roundId, referral1, i)))
      }
      expect(referralTickets.map(r => r.referralTicketNumber)).to.deep.equal([1, 4, 5, 6]);

      await expect(lotteryMaster.closeRound()).to.be.revertedWith("Round is not over yet")

      await hre.ethers.provider.send("evm_increaseTime", [50])

      await lotteryMaster.closeRound()

      expect(await lotteryMaster.publicRoundRandomNumbersRequestId(roundId)).to.equal(1)
      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.revertedWith("Random numbers not ready")
      expect((await lotteryMaster.getCurrentRound()).powerNumber).to.equal(0);
      await executeChainLinkVrf(roundId, winningNumbers, winningPowerNumber, referralIndexes, lotteryMaster, cyclixRandomizer, vrfMock);

      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.fulfilled
      expect((await lotteryMaster.getCurrentRound()).roundNumbers[0]).to.equal(winningNumbers[0]);
      expect((await lotteryMaster.getCurrentRound()).roundNumbers[4]).to.equal(winningNumbers[4]);
      expect((await lotteryMaster.getCurrentRound()).powerNumber).to.equal(26);
      expect((await lotteryMaster.getCurrentRound()).referralWinnersNumber).to.deep.equal(referralIndexes);
    })

    it("Should retain the amounts of the lottery pools", async function () {
      const winningPowerNumber = 26
      const winningNumbers = [1, 2, 3, 4, 69]
      const referralIndexes = [1]
      const roundId: number = 1

      const { lotteryMaster, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      await addPlayersToLotteryRound(lotteryMaster);
      await hre.ethers.provider.send("evm_increaseTime", [50])
      await lotteryMaster.closeRound()
      await executeChainLinkVrf(roundId, winningNumbers, winningPowerNumber, referralIndexes, lotteryMaster, cyclixRandomizer, vrfMock);

      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.fulfilled

      const winningNumbersFromChain = (await lotteryMaster.getCurrentRound()).roundNumbers
      const winningPowerNumberFromChain = (await lotteryMaster.getCurrentRound()).powerNumber
      const referralIndexesFromChain = (await lotteryMaster.getCurrentRound()).referralWinnersNumber
      const round = await lotteryMaster.getCurrentRound();
      const roundTicketCount = round.ticketsCount;
      const winnerTicketsResults: any = []
      for (let i = 0; i < roundTicketCount; i++) {
        const ticket = await lotteryMaster.tickets(round.ticketIds[i])
        const powerNumberFound = ticket.powerNumber === winningPowerNumberFromChain
        let rightNumbersForTicket = 0
        for(let i = 0; i < 5; i++) {
          if (checkNumberExistInArray(winningNumbersFromChain.map(b => Number(b)), Number(await lotteryMaster.ticketNumbers(ticket.id, i)))) {
            rightNumbersForTicket++
          }
        }

        const tier = tierForResult(rightNumbersForTicket, rightNumbersForTicket)
        if (tier >= 0) {
          winnerTicketsResults.push([ticket.id, tier])
        }
      }
      // const referralTicketsCount = await lotteryMaster.roundReferralTicketsCount(roundId)
      // const winnerReferralTicketsIndexes: number[] = []
      // for (let i = 0; i < referralTicketsCount; i++) {
      //   const referralTicket = await lotteryMaster.roundReferralTickets(roundId, i);
      // }

      // @ts-ignore
      // await lotteryMaster.evaluateWonAmount(roundId, winnerTicketsResults.map(([id, tier]) => id), winnerReferralTicketsIndexes)
      // await lotteryMaster.markWinnerTickets(roundId, winnerTicketsIndexes, winnerReferralTicketsIndexes)


      // await lotteryMaster.claimWin(roundId)


    })

    it("Should be able to retain referrals", async function () {

    })
  })
});
