// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import { LotteryRound } from "./LotteryRound.sol";
import { LotteryMaster } from "./LotteryMaster.sol";

contract LotteryReader is EmergencyFunctions {
    LotteryMaster public lotteryMaster;

    constructor(LotteryMaster _lotteryMaster)
    EmergencyFunctions(tx.origin) {
        lotteryMaster = _lotteryMaster;
    }

    function poolForVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier5_1 || victoryTier == RoundVictoryTier.Tier5 || victoryTier == RoundVictoryTier.Tier4_1 ||
        victoryTier == RoundVictoryTier.Tier4 || victoryTier == RoundVictoryTier.Tier3_1 || victoryTier == RoundVictoryTier.Tier3,
            "Invalid victory tier");
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

    function evaluateWonResultsForOneTicket(uint256 roundId, uint256 ticketId) public view returns (TicketResults memory){
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.roundForId(roundId));
        Round memory roundForEvaluation = lotteryRound.getRound();
        Ticket memory ticket = lotteryRound.ticketById(roundForEvaluation.ticketIds[ticketId]);
        bool powerNumberFound = ticket.powerNumber == roundForEvaluation.powerNumber;
        uint16 rightNumbersForTicket = 0;
        uint16[] memory ticketNumbers = lotteryRound.numbersForTicketId(ticket.id);
        for(uint16 i = 0; i < 5; i++) {
            uint16 ticketNumber = ticketNumbers[i];
            if (existInArrayNumber(ticketNumber, roundForEvaluation.roundNumbers)) {
                rightNumbersForTicket++;
            }
        }
        return TicketResults({
            ticketId: ticket.id,
            victoryTier: tierFromResults(rightNumbersForTicket, powerNumberFound)
        });
    }

    function evaluateWonResultsForTickets(uint256 roundId) public view returns (TicketResults[] memory){
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.roundForId(roundId));
        Round memory roundForEvaluation = lotteryRound.getRound();
        uint16 roundTicketCount = roundForEvaluation.ticketsCount;
        TicketResults[] memory ticketResults = new TicketResults[](roundForEvaluation.ticketsCount);
        uint16 counter = 0;
        for(uint16 ticketIndexForRound = 0; ticketIndexForRound < roundTicketCount; ticketIndexForRound++) {
            Ticket memory ticket = lotteryRound.ticketById(roundForEvaluation.ticketIds[ticketIndexForRound]);
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

    function evaluateWonResultsForOneReferralTicket(uint256 roundId, uint256 referralTicketId) public view returns (ReferralTicketResults memory) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.roundForId(roundId));
        Round memory roundForEvaluation = lotteryRound.getRound();
        ReferralTicket memory referralTicket = lotteryRound.referralTicketById(roundForEvaluation.referralTicketIds[referralTicketId]);
        bool referralWon = existInArrayNumber(referralTicket.referralTicketNumber, roundForEvaluation.referralWinnersNumber);
        return ReferralTicketResults({
            referralTicketId: referralTicket.id,
            won: referralWon
        });
    }

    function evaluateWonResultsForReferral(uint256 roundId) public view returns (ReferralTicketResults[] memory) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.roundForId(roundId));
        Round memory roundForEvaluation = lotteryRound.getRound();
        ReferralTicketResults[] memory referralWinnerIds = new ReferralTicketResults[](roundForEvaluation.referralCounts);
        uint16 counter = 0;
        for(uint16 referralIndexForRound = 0; referralIndexForRound < roundForEvaluation.referralCounts; referralIndexForRound++) {
            ReferralTicket memory referralTicket = lotteryRound.referralTicketById(roundForEvaluation.referralTicketIds[referralIndexForRound]);
            bool referralWon = existInArrayNumber(referralTicket.referralTicketNumber, roundForEvaluation.referralWinnersNumber);
            referralWinnerIds[counter++] = ReferralTicketResults({
                referralTicketId: referralTicket.id,
                won: referralWon
            });
        }
        return referralWinnerIds;
    }

    function amountWonInRound(uint256 roundId) public view returns (uint256) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId -1));
        return lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5_1) + lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5) + lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4_1) +
        lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4) + lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3_1) + lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3) +
            lotteryRound.victoryTierAmounts(RoundVictoryTier.Referrer);
    }
}