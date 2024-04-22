// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import { LotteryRound } from "./LotteryRound.sol";

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
    LotteryMasterReader public reader;
    uint256 public ticketPrice;

    constructor(address cyclixRandomizer, address _paymentToken, uint256 _ticketPrice, uint16 _roundDuration)
    EmergencyFunctions(msg.sender) {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = new LotteryMasterReader(this);
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
//        TicketResults[] memory ticketResults = reader.evaluateWonResultsForTickets(roundId);
//        for(uint16 i = 0; i < ticketResults.length; i++) {
//            TicketResults memory ticketResult = ticketResults[i];
//            Ticket storage ticket = tickets[ticketResult.ticketId - 1];
//            if (ticketResult.victoryTier != RoundVictoryTier.NO_WIN) {
//                ticket.victoryTier = ticketResult.victoryTier;
//                winnersCountByTier[roundId][ticketResult.victoryTier]++;
//            }
//        }
//
//        ReferralTicketResults[] memory referralTicketResults = reader.evaluateWonResultsForReferral(roundId);
//        for(uint16 i = 0; i < referralTicketResults.length; i++) {
//            ReferralTicketResults memory referralTicketResult = referralTicketResults[i];
//            ReferralTicket storage referralTicket = referralTickets[referralTicketResult.referralTicketId - 1];
//            if (referralTicketResult.won) {
//                referralTicket.winner = true;
//                winnersCountByTier[roundId][RoundVictoryTier.Referrer]++;
//            }
//        }
    }
}

contract LotteryMasterReader {
    LotteryMaster public lotteryMaster;

    constructor(LotteryMaster _lotteryMaster) {
        lotteryMaster = _lotteryMaster;
    }

    function poolForHighVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier5_1 || victoryTier == RoundVictoryTier.Tier5 || victoryTier == RoundVictoryTier.Tier4_1, "Invalid victory tier");
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(victoryTier);
    }

    function priceForLowVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier4 || victoryTier == RoundVictoryTier.Tier3_1 || victoryTier == RoundVictoryTier.Tier3, "Invalid victory tier");
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(victoryTier);
    }

    function poolForReferral(uint256 roundId) public view returns(uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.Referrer);
    }

    function tokenHoldersPoolAmount(uint256 roundId) public view returns (uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.TokenHolders);
    }

    function treasuryPoolAmount(uint256 roundId) public view returns (uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.Treasury);
    }

    function numberOfReferralWinnersForRoundId(uint256 roundId) public view returns (uint16) {
        uint16 referralWinnersForRound = 0;
        uint16 referralCounts = LotteryRound(lotteryMaster.rounds(roundId -1)).getRound().referralCounts;
        unchecked {
            referralWinnersForRound = referralCounts / 10;
        }
        if (referralWinnersForRound == 0 && referralCounts > 0) {
            referralWinnersForRound = 1;
        }
        return referralWinnersForRound;
    }

    function existInArrayNumber(uint16 num, uint16[] memory arr) public pure returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == num) {
                return true;
            }
        }
        return false;
    }

    function notExistInArrayNumber(uint16 num, uint16[] memory arr) public pure returns (bool) {
        return existInArrayNumber(num, arr) == false;
    }

    function getRandomUniqueNumberInArrayForMaxValue(uint256 randomNumber, uint16 maxValue, uint16[] memory arr) public pure returns (uint16) {
        uint16 returnedNumber = uint16(randomNumber % maxValue + 1);
        uint16 counter = 0;
        bool existInNumbers = existInArrayNumber(returnedNumber, arr);
        while (existInNumbers) {
            returnedNumber =  uint16(uint256(keccak256(abi.encode(returnedNumber, counter))) % maxValue + 1);
            existInNumbers = existInArrayNumber(returnedNumber, arr);
            counter++;
        }
        return returnedNumber;
    }


    function tierFromResults(uint16 rightNumbersForTicket, bool powerNumberFound) public pure returns (RoundVictoryTier) {
        if (rightNumbersForTicket == 5 && powerNumberFound) {
            return RoundVictoryTier.Tier5_1;
        } else if (rightNumbersForTicket == 5) {
            return RoundVictoryTier.Tier5;
        } else if (rightNumbersForTicket == 4 && powerNumberFound) {
            return RoundVictoryTier.Tier4_1;
        } else if (rightNumbersForTicket == 4) {
            return RoundVictoryTier.Tier4;
        } else if (rightNumbersForTicket == 3 && powerNumberFound) {
            return RoundVictoryTier.Tier3_1;
        } else if (rightNumbersForTicket == 3) {
            return RoundVictoryTier.Tier3;
        }
        return RoundVictoryTier.NO_WIN;
    }

    function evaluateWonResultsForTickets(uint256 roundId) public view returns (TicketResults[] memory){
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.roundForId(roundId));
        Round memory roundForEvaluation = lotteryRound.getRound();
        uint16 roundTicketCount = roundForEvaluation.ticketsCount;
        TicketResults[] memory ticketResults = new TicketResults[](roundForEvaluation.ticketsCount);
        uint16 counter = 0;
        for(uint16 ticketIndexForRound = 0; ticketIndexForRound < roundTicketCount; ticketIndexForRound++) {
            Ticket memory ticket = lotteryRound.ticketAtIndex(roundForEvaluation.ticketIds[ticketIndexForRound]);
            bool powerNumberFound = ticket.powerNumber == roundForEvaluation.powerNumber;
            uint16 rightNumbersForTicket = 0;
            uint16[] memory ticketNumbers = lotteryRound.numbersForTicketId(ticket.id);
            for(uint16 i = 0; i < 5; i++) {
                uint16 ticketNumber = ticketNumbers[i];
                if (existInArrayNumber(ticketNumber, roundForEvaluation.roundNumbers)) {
                    rightNumbersForTicket++;
                }
            }
            ticketResults[counter++] = TicketResults({
                ticketId: ticket.id,
                victoryTier: tierFromResults(rightNumbersForTicket, powerNumberFound)
            });
        }
        return ticketResults;
    }

    function evaluateWonResultsForReferral(uint256 roundId) public view returns (ReferralTicketResults[] memory) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.roundForId(roundId));
        Round memory roundForEvaluation = lotteryRound.getRound();
        ReferralTicketResults[] memory referralWinnerIds = new ReferralTicketResults[](roundForEvaluation.referralCounts);
        uint16 counter = 0;
        for(uint16 referralIndexForRound = 0; referralIndexForRound < roundForEvaluation.referralCounts; referralIndexForRound++) {
            ReferralTicket memory referralTicket = lotteryRound.referralTicketAtIndex(roundForEvaluation.referralTicketIds[referralIndexForRound]);
            bool referralWon = existInArrayNumber(referralTicket.referralTicketNumber, roundForEvaluation.referralWinnersNumber);
            referralWinnerIds[counter++] = ReferralTicketResults({
                referralTicketId: referralTicket.id,
                won: referralWon
            });
        }
        return referralWinnerIds;
    }
}