// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import { LotteryRound } from "./LotteryRound.sol";
import { LotteryMaster } from "./LotteryMaster.sol";
import {LotteryReaderInterface} from "./LotteryReaderInterface.sol";

contract LotteryReader is LotteryReaderInterface, EmergencyFunctions {
    LotteryMaster public lotteryMaster;

    function setLotteryMaster(address _lotteryMaster) public onlyOwner {
        lotteryMaster = LotteryMaster(_lotteryMaster);
    }

    constructor() EmergencyFunctions(tx.origin) {}

    function poolForVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view override returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier5_1 || victoryTier == RoundVictoryTier.Tier5 || victoryTier == RoundVictoryTier.Tier4_1 ||
        victoryTier == RoundVictoryTier.Tier4 || victoryTier == RoundVictoryTier.Tier3_1 || victoryTier == RoundVictoryTier.Tier3,
            "Invalid victory tier");
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(victoryTier);
    }

    function roundNumbers(uint256 roundId) public view returns(uint16[] memory) {
        Round memory round = LotteryRound(lotteryMaster.rounds(roundId -1)).getRound();
        return round.roundNumbers;
    }

    function referralWinnersNumber(uint256 roundId) public view returns(uint256[] memory) {
        Round memory round = LotteryRound(lotteryMaster.rounds(roundId -1)).getRound();
        return round.referralWinnersNumber;
    }

    function poolForReferral(uint256 roundId) public view override returns(uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.Referrer);
    }

    function tokenHoldersPoolAmount(uint256 roundId) public view override returns (uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.TokenHolders);
    }

    function treasuryPoolAmount(uint256 roundId) public view override returns (uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.Treasury);
    }

    function numberOfReferralWinnersForRoundId(uint256 roundId) public view override returns (uint16) {
        uint16 referralWinnersForRound = 0;
        uint16 referralCounts = LotteryRound(lotteryMaster.rounds(roundId -1)).getRound().referralCounts;
        unchecked {
            referralWinnersForRound = referralCounts / lotteryMaster.percentageOfReferralWinners();
        }
        if (referralWinnersForRound == 0 && referralCounts > 0) {
            referralWinnersForRound = 1;
        }
        return referralWinnersForRound;
    }

    function existInArrayBigNumber(uint256 num, uint256[] memory arr) public pure override returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == num) {
                return true;
            }
        }
        return false;
    }

    function existInArrayNumber(uint16 num, uint16[] memory arr) public pure override returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == num) {
                return true;
            }
        }
        return false;
    }

    function notExistInArrayNumber(uint16 num, uint16[] memory arr) public pure override returns (bool) {
        return existInArrayNumber(num, arr) == false;
    }

    function getRandomUniqueNumberInArrayForMaxValue(uint256 randomNumber, uint16 maxValue, uint16[] memory arr) public pure override returns (uint16) {
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


    function tierFromResults(uint16 rightNumbersForTicket, bool powerNumberFound) public pure override returns (RoundVictoryTier) {
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

    function evaluateWonTicketsForRound(uint256 roundId) public view override returns (TicketResults[] memory){
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        Round memory roundForEvaluation = lotteryRound.getRound();
        uint16 roundTicketCount = roundForEvaluation.ticketsCount;
        TicketResults[] memory ticketResults = new TicketResults[](roundForEvaluation.ticketsCount);
        uint16 counter = 0;
        for(uint16 ticketIndexForRound = 0; ticketIndexForRound < roundTicketCount; ticketIndexForRound++) {
            Ticket memory ticket = lotteryRound.ticketById(roundForEvaluation.ticketIds[ticketIndexForRound]);
            uint16[] memory ticketNumbers = lotteryRound.numbersForTicketId(ticket.id);
            bool powerNumberFound = ticketNumbers[5] == roundForEvaluation.roundNumbers[5];
            uint16 rightNumbersForTicket = 0;
            for(uint16 i = 0; i < 5; i++) {
                uint16 ticketNumber = ticketNumbers[i];
                if (existInArrayNumber(ticketNumber, roundForEvaluation.roundNumbers)) {
                    rightNumbersForTicket++;
                }
            }
            RoundVictoryTier tierResult = tierFromResults(rightNumbersForTicket, powerNumberFound);
            uint256 amountWon = 0;
            if (tierResult != RoundVictoryTier.NO_WIN && lotteryRound.winnersForEachTier(tierResult) > 0) {
                amountWon = poolForVictoryTier(roundId, tierResult) / lotteryRound.winnersForEachTier(tierResult);
            }
            ticketResults[counter++] = TicketResults({
                ticketId: ticket.id,
                participantAddress : ticket.participantAddress,
                victoryTier: tierResult,
                won: tierResult != RoundVictoryTier.NO_WIN,
                claimed: ticket.claimed,
                amountWon : amountWon
            });
        }
        return ticketResults;
    }

    function evaluateWonTicketsAmountForWallet(uint256 roundId, address wallet, bool claimed) public view override returns(uint256) {
        uint256 wonAmount = 0;
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        TicketResults[] memory results = evaluateWonTicketsForWallet(roundId, wallet);
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].claimed == claimed) {
                RoundVictoryTier tierForTicket = results[i].victoryTier;
                wonAmount += results[i].amountWon;
            }
        }
        return wonAmount;
    }

    function evaluateWonTicketsForWallet(uint256 roundId, address wallet) public view override returns(TicketResults[] memory) {
        TicketResults[] memory results = evaluateWonTicketsForRound(roundId);
        uint256 counterForWalletTicket = 0;
        TicketResults[] memory resultsForWallet = new TicketResults[](results.length);
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].participantAddress == wallet && results[i].won) {
                resultsForWallet[counterForWalletTicket] = results[i];
                counterForWalletTicket++;
            }
        }
        TicketResults[] memory onlyResultsForWallet = new TicketResults[](counterForWalletTicket);
        for (uint256 i = 0; i < counterForWalletTicket; i++) {
            onlyResultsForWallet[i] = resultsForWallet[i];
        }
        return onlyResultsForWallet;
    }

    function evaluateWonReferralForRound(uint256 roundId) public view override returns (ReferralTicketResults[] memory) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        Round memory roundForEvaluation = lotteryRound.getRound();
        ReferralTicketResults[] memory referralWinnerIds = new ReferralTicketResults[](roundForEvaluation.referralCounts);
        uint16 counter = 0;
        for(uint16 referralIndexForRound = 0; referralIndexForRound < roundForEvaluation.referralCounts; referralIndexForRound++) {
            ReferralTicket memory referralTicket = lotteryRound.referralTicketById(roundForEvaluation.referralTicketIds[referralIndexForRound]);
            bool referralWon = existInArrayBigNumber(referralTicket.referralTicketNumber, roundForEvaluation.referralWinnersNumber);
            uint256 amountWon = 0;
            if (referralWon && lotteryRound.winnersForEachTier(RoundVictoryTier.Referrer) > 0) {
                amountWon = poolForReferral(roundId) / lotteryRound.winnersForEachTier(RoundVictoryTier.Referrer);
            }
            referralWinnerIds[counter++] = ReferralTicketResults({
                referralTicketId: referralTicket.id,
                referralAddress : referralTicket.referralAddress,
                referralTicketNumber: referralTicket.referralTicketNumber,
                won: referralWon,
                claimed: referralTicket.claimed,
                amountWon : amountWon
            });
        }
        return referralWinnerIds;
    }

    function evaluateWonReferralAmountForWallet(uint256 roundId, address wallet, bool claimed) public view override returns(uint256) {
        uint256 wonAmount = 0;
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        ReferralTicketResults[] memory results = evaluateWonReferralFoWallet(roundId, wallet);
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].claimed == claimed) {
                wonAmount += results[i].amountWon;
            }
        }
        return wonAmount;
    }

    function evaluateWonReferralFoWallet(uint256 roundId, address wallet) public view override returns(ReferralTicketResults[] memory) {
        ReferralTicketResults[] memory results = evaluateWonReferralForRound(roundId);
        uint256 counterForWalletTicket = 0;
        ReferralTicketResults[] memory resultsForWallet = new ReferralTicketResults[](results.length);
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].referralAddress == wallet && results[i].won) {
                resultsForWallet[counterForWalletTicket] = results[i];
                counterForWalletTicket++;
            }
        }
        ReferralTicketResults[] memory onlyResultsForWallet = new ReferralTicketResults[](counterForWalletTicket);
        for (uint256 i = 0; i < counterForWalletTicket; i++) {
            onlyResultsForWallet[i] = resultsForWallet[i];
        }
        return onlyResultsForWallet;
    }

    function amountWonInRound(uint256 roundId) public view override returns (uint256) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId -1));
        uint256 amountWon = 0;
        TicketResults[] memory ticketResults = evaluateWonTicketsForRound(roundId);
        ReferralTicketResults[] memory referralResults = evaluateWonReferralForRound(roundId);
        uint256 tier5_1Winners = 0;
        uint256 tier5Winners = 0;
        uint256 tier4_1Winners = 0;
        uint256 tier4Winners = 0;
        uint256 tier3_1Winners = 0;
        uint256 tier3Winners = 0;
        for(uint16 i = 0; i < ticketResults.length; i++) {
            if (ticketResults[i].victoryTier == RoundVictoryTier.Tier5_1) {
                tier5_1Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier5) {
                tier5Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier4_1) {
                tier4_1Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier4) {
                tier4Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier3_1) {
                tier3_1Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier3) {
                tier3Winners++;
            }
        }

        if (tier5_1Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5_1);
        }
        if (tier5Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5);
        }
        if (tier4_1Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4_1);
        }
        if (tier4Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4);
        }
        if (tier3_1Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3_1);
        }
        if (tier3Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3);
        }
        if (referralResults.length > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Referrer);
        }
        return amountWon;
    }
}