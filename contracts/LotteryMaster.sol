// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import { LotteryRound } from "./LotteryRound.sol";
import { LotteryReader } from "./LotteryReader.sol";

contract LotteryMaster is EmergencyFunctions {

    uint256 public roundCount;
    address[] public rounds;
    function roundForId(uint256 roundId) public view returns (address) {
        return rounds[roundId - 1];
    }

    function getCurrentRound() public view returns (address) {
        return rounds[roundCount - 1];
    }
    mapping(address => uint16) public freeRounds;

    address[] public bankWallets;
    uint16 public counterForBankWallets;
    function addBankWallet(address wallet) public onlyOwner {
        bankWallets.push(wallet);
    }
    uint16 public roundDurationInSeconds;
    function setRoundDurationInSeconds(uint16 _roundDuration) public onlyOwner {
        roundDurationInSeconds = _roundDuration;
    }
    IERC20Metadata public paymentToken;
    CyclixRandomizerInterface public randomizer;
    LotteryReader public reader;
    uint256 public ticketPrice;

    constructor(address cyclixRandomizer, address _paymentToken, uint256 _ticketPrice, uint16 _roundDuration)
    EmergencyFunctions(msg.sender) {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = new LotteryReader(this);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        roundDurationInSeconds = _roundDuration;
    }

    function startNewRound(address newLotteryRoundAddress) public onlyOwner {
        roundCount++;
        rounds.push(address(newLotteryRoundAddress));
//        if (roundCount > 1) {
//
////            victoryTierAmounts[roundCount][RoundVictoryTier.Tier5_1] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier5_1];
////            victoryTierAmounts[roundCount][RoundVictoryTier.Tier5] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier5];
////            victoryTierAmounts[roundCount][RoundVictoryTier.Tier4_1] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier4_1];
////            victoryTierAmounts[roundCount][RoundVictoryTier.Referrer] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Referrer];
////            victoryTierAmounts[roundCount][RoundVictoryTier.TokenHolders] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.TokenHolders];
////            victoryTierAmounts[roundCount][RoundVictoryTier.Treasury] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Treasury];
//        } else {
//            LotteryRound newRound = new LotteryRound(address(0), roundDurationInSeconds);
//            rounds.push(address(newRound));
//        }
    }

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, uint16 powerNumber, address referral) public {
        require(freeRounds[tx.origin] > 0 || paymentToken.allowance(tx.origin, address(this)) >= ticketPrice, "Missing Allowance");
        if (freeRounds[msg.sender] > 0) {
            freeRounds[msg.sender]--;
        } else {
            require(paymentToken.balanceOf(tx.origin) >= ticketPrice, "Insufficient funds");
            counterForBankWallets = uint16(counterForBankWallets++ % bankWallets.length);
            paymentToken.transferFrom(msg.sender, bankWallets[counterForBankWallets], ticketPrice);
            LotteryRound(rounds[roundCount - 1]).updateVictoryPoolForTicket(ticketPrice);
        }

        LotteryRound(rounds[roundCount - 1]).buyTicket(chainId, chosenNumbers, powerNumber, referral);
    }

    function addFreeRound(address[] calldata participant) public onlyOwner {
        for (uint i = 0; i < participant.length; i++) {
            freeRounds[participant[i]]++;
        }
    }

    mapping(uint256 => uint256) public publicRoundRandomNumbersRequestId;

    function closeRound() external onlyOwner {
        LotteryRound lotteryRound = LotteryRound(rounds[roundCount - 1]);
        lotteryRound.closeRound();
        uint16 referralWinners = reader.numberOfReferralWinnersForRoundId(roundCount);
        publicRoundRandomNumbersRequestId[roundCount] = randomizer.requestRandomWords(6 + referralWinners);
    }

    function fetchRoundNumbers(uint256 roundId) external onlyOwner {
        LotteryRound round = LotteryRound(rounds[roundId - 1]);
        round.couldReceiveWinningNumbers();
        (bool fulfilled, uint256[] memory randomWords) = randomizer.getRequestStatus(publicRoundRandomNumbersRequestId[roundId]);
        require(fulfilled, "Random numbers not ready");
        uint16[] memory roundNumbers = new uint16[](5);
        uint16 powerNumber;
        uint16[] memory referralWinnersNumber = new uint16[](randomWords.length - 6);
        if (fulfilled) {
            for (uint i = 0; i < 5; i++) {
                roundNumbers[i] = reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i], 69, roundNumbers);
            }
            powerNumber = uint16(randomWords[5] % 26 + 1);
            for (uint i = 6; i < randomWords.length; i++) {
                referralWinnersNumber [i - 6] = reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i],
                    round.getRound().referralCounts, referralWinnersNumber);
            }
        }
        round.storeWinningNumbers(roundNumbers, powerNumber, referralWinnersNumber);
    }

    function markWinners(uint256 roundId) public onlyOwner {
        LotteryRound(rounds[roundId - 1]).markWinners(reader.evaluateWonResultsForTickets(roundId), reader.evaluateWonResultsForReferral(roundId));
    }

    function claimVictory(uint256 ticketId) public {
        LotteryRound lotteryRound = LotteryRound(getCurrentRound());
        Ticket memory ticket = lotteryRound.ticketById(ticketId);
        require(ticket.id == ticketId, "Invalid ticket id");
        require(ticket.participantAddress == msg.sender, "Invalid ticket owner");
        require(!ticket.claimed, "Ticket already claimed");
        require(lotteryRound.getRound().ended, "Round not ended");
        require(ticket.victoryTier != RoundVictoryTier.NO_WIN, "No prize for this ticket");
        require(ticket.victoryTier == reader.evaluateWonResultsForOneTicket(lotteryRound.getRound().id, ticketId).victoryTier, "Invalid ticket tier");
        unchecked {
            uint256 amountWon = lotteryRound.victoryTierAmounts(ticket.victoryTier) / lotteryRound.winnersForEachTier(ticket.victoryTier);
            require(paymentToken.balanceOf(address(this)) >= amountWon, "Not enough funds on contract");
            LotteryRound(getCurrentRound()).markVictoryClaimed(ticketId);
            paymentToken.transfer(msg.sender, amountWon);
        }
    }

    function claimReferralVictory(uint256 referralTicketId) public {
        LotteryRound lotteryRound = LotteryRound(getCurrentRound());
        ReferralTicket memory referralTicket = lotteryRound.referralTicketById(referralTicketId);
        require(referralTicket.id == referralTicketId, "Invalid ticket id");
        require(referralTicket.referralAddress == msg.sender, "Invalid ticket owner");
        require(!referralTicket.claimed, "Ticket already claimed");
        require(lotteryRound.getRound().ended, "Round not ended");
        require(referralTicket.winner == true, "No prize for this ticket");
        require(referralTicket.winner == reader.evaluateWonResultsForOneReferralTicket(lotteryRound.getRound().id, referralTicketId).won, "Invalid ticket tier");
        unchecked {
            uint256 amountWon = lotteryRound.victoryTierAmounts(RoundVictoryTier.Referrer) / reader.numberOfReferralWinnersForRoundId(lotteryRound.getRound().id);
            require(paymentToken.balanceOf(address(this)) >= amountWon, "Not enough funds on contract");
            LotteryRound(getCurrentRound()).markReferralVictoryClaimed(referralTicketId);
            paymentToken.transfer(msg.sender, amountWon);
        }
    }
}
