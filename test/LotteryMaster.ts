import {expect} from "chai";
import hre from "hardhat";
import {deployAndSetupCyclixRandomizer, toEtherBigInt} from "./common";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/src/signers";
import {LotteryMaster, LotteryReader, LotteryRound, TestUsdt} from "../typechain-types";
import {AddressLike} from "ethers";
import {VRFCoordinatorV2Mock} from "../typechain-types";
`r`
let owner: HardhatEthersSigner
let player1: HardhatEthersSigner
let player2: HardhatEthersSigner
let player3: HardhatEthersSigner
let referral1: HardhatEthersSigner
let referral2: HardhatEthersSigner
let referral3: HardhatEthersSigner
let usdtContract: TestUsdt

describe("Lottery Master", function () {

  async function deployLotteryMaster() {
    const { cyclixRandomizer, vrfMock } = await deployAndSetupCyclixRandomizer();
    const usdt = await hre.ethers.getContractFactory("TestUsdt");
    usdtContract = await usdt.deploy();
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

    const lotteryReaderFactory = await hre.ethers.getContractFactory("LotteryReader");
    const lotteryReader = await lotteryReaderFactory.deploy();
    const lotteryRoundCreatorFactory = await hre.ethers.getContractFactory("LotteryRoundCreator");
    const lotteryRoundCreator = await lotteryRoundCreatorFactory.deploy();

    const lotteryMasterFactory = await hre.ethers.getContractFactory("LotteryMaster");
    const lotteryMaster = await lotteryMasterFactory.deploy(cyclixRandomizer.getAddress(), lotteryReader.getAddress(),
        lotteryRoundCreator.getAddress(), usdtContract, 10)
    await lotteryRoundCreator.transferOwnership(lotteryMaster.getAddress())
    await lotteryReader.setLotteryMaster(lotteryMaster.getAddress());

    await usdtContract.connect(player1).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(player2).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(player3).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(referral1).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(referral2).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    await usdtContract.connect(referral3).approve(await lotteryMaster.getAddress(), toEtherBigInt(1000))
    return { lotteryMaster, lotteryReader,  cyclixRandomizer, vrfMock };
  }

  async function deployLotteryMasterAndStartRound() {
    const deployed = await deployLotteryMaster();
    await deployed.lotteryMaster.startNewRound(50);
    const lotteryRoundAddress = await deployed.lotteryMaster.getCurrentRound()
    const contract = await hre.ethers.getContractFactory("LotteryRound");
    // @ts-ignore
    const lotteryRound = contract.attach(lotteryRoundAddress) as LotteryRound;

    return { ...deployed, lotteryRound }
  }

  async function addPlayersToLotteryRound(lotteryMaster: LotteryMaster) {
    await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 69], 26, referral1);
    await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 69], 24, referral2);
    await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 14], 26, referral3);
    await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 14], 24, referral1);
    await lotteryMaster.connect(player3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [36, 2, 3, 13, 14], 26, referral1);
    await lotteryMaster.connect(player3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 13, 14], 24, referral1);
    await lotteryMaster.connect(referral1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 69], 26, hre.ethers.ZeroAddress);
    await lotteryMaster.connect(referral1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 13, 14], 26, hre.ethers.ZeroAddress);
    await lotteryMaster.connect(referral2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 4, 6, 14], 24, hre.ethers.ZeroAddress);
    await lotteryMaster.connect(referral3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 14], 26, hre.ethers.ZeroAddress);
  }

  async function executeChainLinkVrf(roundId: number, winningNumbers: number[], winningPowerNumber: number, referralIndexes: number[],
                                     lotteryMaster: any, cyclixRandomizer: any, vrfMock: VRFCoordinatorV2Mock) {
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

  async function computeTicketResultsOffChain(lotteryRound: LotteryRound) {
    const winningNumbersFromChain =(await lotteryRound.getRound()).roundNumbers
    const winningPowerNumberFromChain =(await lotteryRound.getRound()).powerNumber
    const roundTicketCount =(await lotteryRound.getRound()).ticketsCount;
    const ticketResults: any = []
    for (let i = 0; i < roundTicketCount; i++) {
      const ticket = await lotteryRound.tickets((await lotteryRound.getRound()).ticketIds[i])
      const powerNumberFound = ticket.powerNumber === winningPowerNumberFromChain
      let rightNumbersForTicket = 0
      for(let i = 0; i < 5; i++) {
        let ticketNumber = Number(await lotteryRound.ticketNumbers(ticket.id, i));
        if (checkNumberExistInArray(winningNumbersFromChain.map(b => Number(b)), ticketNumber)) {
          rightNumbersForTicket++
        }
      }

      const tier = tierIndexToName(tierIndexForResult(rightNumbersForTicket, powerNumberFound))
      ticketResults.push([ticket.id, tier])
    }
    return ticketResults
  }

  async function computeReferralResultsOffChain(lotteryRound: LotteryRound) {
    let round = await lotteryRound.getRound();
    const referralWinnersNumber = round.referralWinnersNumber
    const roundReferralCount = round.referralCounts;
    const referralResults: any = []
    for (let i = 0; i < roundReferralCount; i++) {
      const referralTicket = await lotteryRound.referralTickets(round.referralTicketIds[i])
      const referralTicketWon = checkNumberExistInArray(referralWinnersNumber.map(b => Number(b)),
          Number(referralTicket.referralTicketNumber))
      referralResults.push([referralTicket.id, referralTicketWon])
    }
    return referralResults
  }

  function tierIndexToName(index: number) {
    if (index == 0) {
      return "NO_WIN"
    } else if (index === 1) {
      return "Tier5_1"
    } else if (index === 2) {
      return "Tier5"
    } else if (index === 3) {
      return "Tier4_1"
    } else if (index === 4) {
      return "Tier4"
    } else if (index === 5) {
      return "Tier3_1"
    } else if (index === 6) {
      return "Tier3"
    }
  }

  function tierIndexForResult(numberOfRightNumbers: number, powerNumberFound: boolean) {
    if (numberOfRightNumbers === 5 && powerNumberFound) {
      return 1
    } else if (numberOfRightNumbers === 5) {
      return 2
    } else if (numberOfRightNumbers === 4 && powerNumberFound) {
      return 3
    } else if (numberOfRightNumbers === 4) {
      return 4
    } else if (numberOfRightNumbers === 3 && powerNumberFound) {
      return 5
    } else if (numberOfRightNumbers === 3) {
      return 6
    } else {
      return 0
    }
  }

  describe("Behaviour", function () {
    it("Deploy", async function () {
      const { lotteryMaster } = await deployLotteryMaster();
      expect(lotteryMaster.getAddress()).to.not.equal(0);
    });

    it("Should be able to Start Lottery Round", async function () {
      const { lotteryMaster, lotteryRound } = await deployLotteryMasterAndStartRound();
      expect((await lotteryRound.getRound()).id).equal(1);
    });

    it("Should validate numbers to Join Lottery Round", async function () {
      const {lotteryMaster} = await deployLotteryMasterAndStartRound();

      await expect(lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 70], 24, hre.ethers.ZeroAddress)).to.be.revertedWith("Invalid numbers");
      await expect(lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [0, 4, 6, 10, 21], 24, hre.ethers.ZeroAddress)).to.be.revertedWith("Invalid numbers");
      await expect(lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 27, hre.ethers.ZeroAddress)).to.be.revertedWith("Invalid power number");
    })

    it("Should be able to Make wallets Join Lottery Round", async function () {
      const { lotteryMaster, lotteryRound } = await deployLotteryMasterAndStartRound();
      const initialOwnerBalance = await usdtContract.balanceOf(owner.address)

      await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, hre.ethers.ZeroAddress);
      let round = await lotteryRound.getRound();
      expect(round.ticketsCount).equal(1);

      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      round = await lotteryRound.getRound();
      expect(round.ticketsCount).equal(3);
      expect(round.referralCounts).equal(2);
      expect((await usdtContract.balanceOf(owner.address)) - initialOwnerBalance).equal(toEtherBigInt(30))
    });

    it("Should be able to give free rounds to a list of wallets", async function () {
      const { lotteryMaster, lotteryRound } = await deployLotteryMasterAndStartRound();
      const initialOwnerBalance = await usdtContract.balanceOf(owner.address)

      await lotteryMaster.addFreeRound([player1.address, player3.address])
      await lotteryMaster.connect(player1).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player2.address);
      await lotteryMaster.connect(player2).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      await lotteryMaster.connect(player3).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, player1.address);
      const round = await lotteryRound.getRound();
      expect(round.ticketsCount).equal(3);
      expect(round.referralCounts).equal(3);
      expect((await usdtContract.balanceOf(owner.address)) - initialOwnerBalance).equal(toEtherBigInt(10))
    });

    it("Should rightly split winning pools", async function () {
      const { lotteryMaster, lotteryRound, lotteryReader } = await deployLotteryMasterAndStartRound();
      const initialOwnerBalance = await usdtContract.balanceOf(owner.address)

      await lotteryMaster.addFreeRound([player1.address, player3.address])
      const players = [player1, player2, player3]
      for (let i = 0; i < 10; i++) {
        let playerId = i % 3;
        await lotteryMaster.connect(players[playerId]).buyTicket((await hre.ethers.provider.getNetwork()).chainId, [1, 4, 6, 10, 21], 24, players[(i + 1) % 3]);
      }
      expect((await usdtContract.balanceOf(owner.address)) - initialOwnerBalance).equal(toEtherBigInt(80))
      const round = await lotteryRound.getRound();
      expect(round.ticketsCount).to.equal(10)
      const reader = await lotteryMaster.reader()
      expect(await lotteryReader.poolForVictoryTier(round.id, 1)).to.equal(toEtherBigInt((80 * 0.7 * 0.35).toPrecision(3)))
      expect(await lotteryReader.poolForVictoryTier(round.id, 2)).to.equal(toEtherBigInt((80 * 0.7 * 0.15).toPrecision(3)))
      expect(await lotteryReader.poolForVictoryTier(round.id, 3)).to.equal(toEtherBigInt((80 * 0.7 * 0.1).toPrecision(3)))
      expect(await lotteryReader.poolForVictoryTier(round.id, 4)).to.equal(toEtherBigInt((80 * 0.7 * 0.07).toPrecision(3)))
      expect(await lotteryReader.poolForVictoryTier(round.id, 5)).to.equal(toEtherBigInt((80 * 0.7 * 0.05).toPrecision(3)))
      expect(await lotteryReader.poolForVictoryTier(round.id, 6)).to.equal(toEtherBigInt((80 * 0.7 * 0.03).toPrecision(3)))
      expect(await lotteryReader.poolForReferral(round.id)).to.equal(toEtherBigInt((80 * 0.15).toPrecision(3)))
      expect(await lotteryReader.tokenHoldersPoolAmount(round.id)).to.equal(toEtherBigInt((80 * 0.10).toPrecision(3)))
      expect(await lotteryReader.treasuryPoolAmount(round.id)).to.equal(toEtherBigInt((80 * 0.5).toPrecision(3)))
    })

    it("Should have always different numbers for draw also if the randomizer return two times the same number", async function () {
      const winningPowerNumber = 26
      const winningNumbers = [1, 1, 3, 4, 69]
      const roundId = 1
      const { lotteryMaster, lotteryRound, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      await hre.ethers.provider.send("evm_increaseTime", [50])

      await lotteryMaster.closeRound()

      await executeChainLinkVrf(roundId, winningNumbers, winningPowerNumber, [], lotteryMaster, cyclixRandomizer, vrfMock);

      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.fulfilled

      let publicRoundWinningNumbers = (await lotteryRound.getRound()).roundNumbers;
      expect(publicRoundWinningNumbers[0]).to.equal(winningNumbers[0]);
      expect(publicRoundWinningNumbers[1]).to.not.equal(winningNumbers[1]);
    })

    it("Should be able to draw public round winners", async function () {
      const winningPowerNumber = 26
      const winningNumbers = [1, 2, 3, 4, 69]
      const referralIndexes = [1]
      const roundId = 1

      const { lotteryMaster, lotteryRound, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      await addPlayersToLotteryRound(lotteryMaster);

      const referralCountTickets = await lotteryRound.roundReferralTicketsByAddressCount(referral1.address)
      const referralTickets = []
      for (let i = 0; i < referralCountTickets; i++) {
        referralTickets.push(await lotteryRound.referralTickets(await lotteryRound.roundReferralTicketsByAddress(referral1, i)))
      }
      expect(referralTickets.map(r => r.referralTicketNumber)).to.deep.equal([1, 4, 5, 6]);

      await expect(lotteryMaster.closeRound()).to.be.revertedWith("Round is not over yet")

      await hre.ethers.provider.send("evm_increaseTime", [50])

      await lotteryMaster.closeRound()

      expect(await lotteryMaster.publicRoundRandomNumbersRequestId(roundId)).to.equal(1)
      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.revertedWith("Random numbers not ready")
      expect((await lotteryRound.getRound()).powerNumber).to.equal(0);
      await executeChainLinkVrf(roundId, winningNumbers, winningPowerNumber, referralIndexes, lotteryMaster, cyclixRandomizer, vrfMock);

      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.fulfilled
      expect((await lotteryRound.getRound()).roundNumbers[0]).to.equal(winningNumbers[0]);
      expect((await lotteryRound.getRound()).roundNumbers[4]).to.equal(winningNumbers[4]);
      expect((await lotteryRound.getRound()).powerNumber).to.equal(26);
      expect((await lotteryRound.getRound()).referralWinnersNumber).to.deep.equal(referralIndexes);
    })

    it("Should retain the amounts of the lottery pools", async function () {
      const winningPowerNumber = 26
      const winningNumbers = [1, 2, 3, 4, 69]
      const referralWinnerNumber = [2]
      const roundId: number = 1

      const { lotteryMaster, lotteryRound, lotteryReader, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      await addPlayersToLotteryRound(lotteryMaster);
      await hre.ethers.provider.send("evm_increaseTime", [50])
      await lotteryMaster.closeRound()
      await executeChainLinkVrf(roundId, winningNumbers, winningPowerNumber, referralWinnerNumber, lotteryMaster, cyclixRandomizer, vrfMock);

      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.fulfilled

      const ticketResultsOffChain = await computeTicketResultsOffChain(lotteryRound)
      const ticketResultsFromChain = (await lotteryReader.evaluateWonResultsForTickets(roundId))
          .map(([id, tier]) => [id, tierIndexToName(Number(tier))])

      expect(ticketResultsFromChain).to.deep.equal(ticketResultsOffChain)

      const referralResultsOffChain = await computeReferralResultsOffChain(lotteryRound)
      let referralResultsFromChain = await lotteryReader.evaluateWonResultsForReferral(roundId);
      expect(referralResultsOffChain).to.deep.equal(referralResultsFromChain)

      await lotteryMaster.markWinners(roundId)

      const round = await lotteryRound.getRound();
      const ticketResults = []
      for (let i = 0; i < round.ticketsCount; i++) {
        const ticket = await lotteryRound.tickets(round.ticketIds[i])
        ticketResults.push([ticket.id, tierIndexToName(Number(ticket.victoryTier))])
      }
      expect(ticketResults).to.deep.equal(ticketResultsOffChain)

      for (let i = 0; i < round.referralCounts; i++) {
        const referral = await lotteryRound.referralTickets(round.referralTicketIds[i])
        if (Number(referral.referralTicketNumber) === 2) {
          expect(referral.winner).to.equal(true)
        } else {
          expect(referral.winner).to.equal(false)
        }
      }

      expect(await lotteryRound.winnersForEachTier(1)).to.equal(2)
      expect(await lotteryRound.winnersForEachTier(2)).to.equal(1)
      expect(await lotteryRound.winnersForEachTier(3)).to.equal(2)
      expect(await lotteryRound.winnersForEachTier(4)).to.equal(1)
      expect(await lotteryRound.winnersForEachTier(5)).to.equal(1)
      expect(await lotteryRound.winnersForEachTier(6)).to.equal(2)
      expect(await lotteryRound.winnersForEachTier(7)).to.equal(1)

      await expect(lotteryMaster.connect(player2).claimVictory(0)).to.be.revertedWith("Invalid ticket owner")
      await expect(lotteryMaster.connect(player1).claimVictory(0)).to.be.revertedWith("Not enough funds on contract")

      expect(await lotteryReader.amountWonInRound(roundId)).to.be.lt(toEtherBigInt(85))
      await usdtContract.connect(owner).transfer(await lotteryMaster.getAddress(), await lotteryReader.amountWonInRound(round.id))

      await lotteryMaster.connect(player1).claimVictory(0)
      await lotteryMaster.connect(player1).claimVictory(1)
      await lotteryMaster.connect(player2).claimVictory(2)
      await lotteryMaster.connect(player2).claimVictory(3)
      await expect(lotteryMaster.connect(player3).claimVictory(4)).to.be.revertedWith('No prize for this ticket')
      await lotteryMaster.connect(player3).claimVictory(5)
      await lotteryMaster.connect(referral1).claimVictory(6)
      await lotteryMaster.connect(referral1).claimVictory(7)
      await lotteryMaster.connect(referral2).claimVictory(8)
      await lotteryMaster.connect(referral3).claimVictory(9)
      await lotteryMaster.connect(referral2).claimReferralVictory(1)
    })

    it("Should be able to execute more rounds bringing the pools not collected", async function () {
      const winningPowerNumber = 24
      const winningNumbers = [5, 7, 3, 13, 14]
      const referralIndexes = [1]
      const roundId = 1

      const { lotteryMaster, lotteryRound,
        lotteryReader, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      await addPlayersToLotteryRound(lotteryMaster);
      await hre.ethers.provider.send("evm_increaseTime", [50])
      await lotteryMaster.closeRound()
      await executeChainLinkVrf(roundId, winningNumbers, winningPowerNumber, referralIndexes, lotteryMaster, cyclixRandomizer, vrfMock);
      await expect(lotteryMaster.fetchRoundNumbers(roundId)).to.be.fulfilled
      await lotteryMaster.markWinners(roundId)

      expect(await lotteryRound.winnersForEachTier(1)).to.equal(0)
      expect(await lotteryRound.winnersForEachTier(2)).to.equal(0)
      expect(await lotteryRound.winnersForEachTier(3)).to.equal(0)
      expect(await lotteryRound.winnersForEachTier(4)).to.equal(0)
      expect(await lotteryRound.winnersForEachTier(5)).to.equal(1)
      expect(await lotteryRound.winnersForEachTier(6)).to.equal(2)
      expect(await lotteryRound.winnersForEachTier(7)).to.equal(1)
      const lotteryWinAmountThatWillBePropagated = await lotteryRound.victoryTierAmounts(5)

      await usdtContract.connect(owner).transfer(await lotteryMaster.getAddress(), await lotteryReader.amountWonInRound(roundId))

      await lotteryMaster.connect(referral1).claimVictory(7)
      expect(await lotteryRound.victoryTierAmountsClaimed(6)).to.equal((await lotteryRound.victoryTierAmounts(6)) / BigInt(2))

      const roundId2 = 2
      await lotteryMaster.startNewRound(50)
      const lotteryRound2 = await hre.ethers.getContractAt("LotteryRound", await lotteryMaster.getCurrentRound()) as LotteryRound

      expect(roundId2).to.equal(2)
      await expect(lotteryMaster.connect(player3).claimVictory(5)).to.be.reverted
      expect(await lotteryRound2.victoryTierAmounts(5)).to.equal((await lotteryRound.victoryTierAmounts(5)))
      expect(await lotteryRound2.victoryTierAmounts(6)).to.equal((await lotteryRound.victoryTierAmounts(6)) / BigInt(2))
      expect(await lotteryRound2.victoryTierAmounts(7)).to.equal(await lotteryRound.victoryTierAmounts(7))
      await addPlayersToLotteryRound(lotteryMaster);

      expect(await lotteryRound2.victoryTierAmounts(5)).to.equal((await lotteryRound.victoryTierAmounts(5)) + lotteryWinAmountThatWillBePropagated)

      await hre.ethers.provider.send("evm_increaseTime", [50])
      await lotteryMaster.closeRound()
      const winningNumbersRound2 = [8, 9, 12, 51, 55]
      const referralIndexes2 = [3]
      await executeChainLinkVrf(roundId2, winningNumbersRound2, winningPowerNumber, referralIndexes2, lotteryMaster, cyclixRandomizer, vrfMock);
      await expect(lotteryMaster.fetchRoundNumbers(roundId2)).to.be.fulfilled
      await lotteryMaster.markWinners(roundId2)
      expect(await lotteryRound2.winnersForEachTier(1)).to.equal(0)
      expect(await lotteryRound2.winnersForEachTier(2)).to.equal(0)
      expect(await lotteryRound2.winnersForEachTier(3)).to.equal(0)
      expect(await lotteryRound2.winnersForEachTier(4)).to.equal(0)
      expect(await lotteryRound2.winnersForEachTier(5)).to.equal(0)
      expect(await lotteryRound2.winnersForEachTier(6)).to.equal(0)
      expect(await lotteryRound2.winnersForEachTier(7)).to.equal(1)

      // Attempt to claim the prize for the previous round
      await expect(lotteryMaster.connect(player3).claimVictory(5)).to.be.reverted
      await lotteryMaster.connect(referral3).claimReferralVictory(2)
    })

    it("Should be able to buy more tickets", async function () {
      const { lotteryMaster, lotteryRound,
        lotteryReader, cyclixRandomizer, vrfMock } = await deployLotteryMasterAndStartRound();
      let round = await lotteryRound.getRound();
      expect(round.ticketsCount).equal(0);
      await lotteryMaster.connect(player1).buyTickets((await hre.ethers.provider.getNetwork()).chainId, [1, 2, 3, 4, 69, 26, 4, 2, 1, 28, 29, 4], referral1);
      round = await lotteryRound.getRound();
      expect(round.ticketsCount).equal(2);
    })
  })
});
