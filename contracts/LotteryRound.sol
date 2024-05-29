// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import {LotteryRoundInterface} from "./LotteryRoundInterface.sol";

contract LotteryRound is Ownable, LotteryRoundInterface {
    Round public round;
    function getRound() public view returns (Round memory) {
        return round;
    }

    Ticket[] public tickets;
    function ticketById(uint256 ticketId) public view returns (Ticket memory) {
        return tickets[ticketId];
    }
    mapping(uint256 => uint16[]) public ticketNumbers;
    function numbersForTicketId(uint256 ticketId) public view returns (uint16[] memory) {
        return ticketNumbers[ticketId];
    }
    mapping(address => uint256[]) public roundTicketsByAddress;
    mapping(address => uint256) public roundTicketsByAddressCount;

    ReferralTicket[] public referralTickets;
    function referralTicketById(uint256 index) public view returns (ReferralTicket memory) {
        return referralTickets[index];
    }
    mapping(address => uint256[]) public roundReferralTicketsByAddress;
    mapping(address => uint256) public roundReferralTicketsByAddressCount;

    mapping(RoundVictoryTier => uint256) public victoryTierAmounts;
    mapping(RoundVictoryTier => uint256) public victoryTierAmountsClaimed;
    uint256 public totalVictoryPool;
    uint256 public totalClaimed;
    mapping(RoundVictoryTier => uint256) public amountWonForEachTicket;
    address public previousRound;

    uint16[]  public  poolPercentagesBasePoints = [3000, 1500, 1000, 700, 500, 300, 1500, 1000, 500];
    function setPoolPercentagesBasePoints(uint16[] memory _poolPercentagesBasePoints) public onlyOwner {
        poolPercentagesBasePoints = _poolPercentagesBasePoints;
    }

    constructor(address previousRoundAddress, uint256 _statusStartTime, uint256 _statusEndTime, uint256 id, uint256 uiId) Ownable(msg.sender) {
        previousRound = previousRoundAddress;
        if (previousRoundAddress != address(0)) {
            propagateWinningFromPreviousRound();
        }
        round = Round({
            id: id,
            uiId:  uiId,
            startTime: _statusStartTime,
            endTime: _statusEndTime,
            ended : false,
            roundNumbers: new uint16[](0),
            referralWinnersNumber: new uint256[](0),
            referralWinnersNumberCount : 0,
            ticketIds : new uint256[](0),
            ticketsCount : 0,
            referralTicketIds : new uint256[](0),
            referralCounts : 0
        });
    }

    function propagateWinningFromPreviousRound() internal {
        LotteryRound previousLotteryRound = LotteryRound(previousRound);
        updateVictoryPoolForTicket(previousLotteryRound.totalVictoryPool() - previousLotteryRound.totalClaimed());
    }

    function numberIsInRangeForRound(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 69;
    }

    function numberIsInRangeForPowerNumber(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 26;
    }

    function validateBuyTicket(uint16[] memory numbers, address referral) public view onlyOwner {
        require(tx.origin != address(0), "Invalid sender");
        require(block.timestamp < round.endTime, "Round is over");
        require(numbers.length == 6, "Invalid numbers count");
        for (uint i = 0; i < numbers.length - 1; i++) {
            require(numberIsInRangeForRound(numbers[i]), "Invalid numbers");
        }
        require(numberIsInRangeForPowerNumber(numbers[5]), "Invalid power number");
        require(referral != tx.origin, "Referral cannot be the same as the participant");
    }

    function percentageInBasisPoint(uint256 amount, uint256 basisPoint) public pure returns (uint256) {
        return amount * basisPoint / 10000;
    }

    function treasuryAmountOnTicket(uint256 paymentTokenAmount) public view returns (uint256) {
        return percentageInBasisPoint(paymentTokenAmount, poolPercentagesBasePoints[8]);
    }

    function updateVictoryPoolForTicket(uint256 paymentTokenAmount) public onlyOwner {
        totalVictoryPool += paymentTokenAmount - percentageInBasisPoint(paymentTokenAmount, poolPercentagesBasePoints[uint(RoundVictoryTier.TokenHolders)]) -
                        percentageInBasisPoint(paymentTokenAmount, poolPercentagesBasePoints[uint(RoundVictoryTier.Treasury)]);
        for(uint i = 0; i < 9; i++) {
            victoryTierAmounts[RoundVictoryTier(i)] += percentageInBasisPoint(paymentTokenAmount, poolPercentagesBasePoints[i]);
        }
    }

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, address referral, address buyer) public onlyOwner {
        validateBuyTicket(chosenNumbers, referral);

        uint256 ticketId = tickets.length;
        tickets.push(Ticket({
            id: ticketId,
            participantAddress: buyer,
            referralAddress: referral,
            claimed: false,
            chainId: chainId,
            victoryTier: RoundVictoryTier.NO_WIN
        }));
        for(uint i = 0; i < chosenNumbers.length; i++) {
            ticketNumbers[ticketId].push(chosenNumbers[i]);
        }
        round.ticketIds.push(ticketId);
        round.ticketsCount++;

        roundTicketsByAddress[buyer].push(tickets.length - 1);
        roundTicketsByAddressCount[buyer]++;
        if (referral != address(0)) {
            uint256 referralTicketId = referralTickets.length;
            round.referralTicketIds.push(referralTicketId);
            round.referralCounts++;
            referralTickets.push(ReferralTicket({
                id: referralTicketId,
                buyerAddress: buyer,
                referralAddress: referral,
                referralTicketNumber: uint16(round.referralCounts),
                winner: false,
                claimed: false
            }));

            roundReferralTicketsByAddress[referral].push(referralTickets.length - 1);
            roundReferralTicketsByAddressCount[referral]++;
        }
    }

    function closeRound() public onlyOwner {
        require(block.timestamp >= round.endTime, "Round is not over yet");
        round.ended = true;
    }

    function couldReceiveWinningNumbers() public view {
        require(block.timestamp >= round.endTime, "Round is not over yet");
        require(round.roundNumbers.length == 0, "Winning numbers already set");
    }

    function storeWinningNumbers(uint16[] memory roundNumbers, uint16[] memory referralWinnersNumber) public onlyOwner {
        round.roundNumbers = roundNumbers;
        round.referralWinnersNumber = referralWinnersNumber;
        round.referralWinnersNumberCount = uint16(referralWinnersNumber.length);
    }

    function markWinners(TicketResults[] memory ticketResults, ReferralTicketResults[] memory referralTicketResults, uint256[] memory amountWonForEachTicketCrossChain) public onlyOwner {
        for (uint i = 0; i < ticketResults.length; i++) {
            TicketResults memory ticketResult = ticketResults[i];
            Ticket storage ticket = tickets[ticketResult.ticketId];
            ticket.victoryTier = ticketResult.victoryTier;
        }
        for (uint i = 0; i < referralTicketResults.length; i++) {
            ReferralTicketResults memory referralTicketResult = referralTicketResults[i];
            ReferralTicket storage referralTicket = referralTickets[referralTicketResult.referralTicketId];
            referralTicket.winner = referralTicketResult.won;
        }
        for (uint i = 0; i < 7; i++) {
            amountWonForEachTicket[RoundVictoryTier(i)] = amountWonForEachTicketCrossChain[i];
        }
    }

    function markVictoryClaimed(TicketResults[] memory ticketResults, ReferralTicketResults[] memory referralTicketResults) public onlyOwner {
        for(uint i = 0; i < ticketResults.length; i++) {
            TicketResults memory ticketResult = ticketResults[i];
            Ticket storage ticket = tickets[ticketResult.ticketId];
            ticket.claimed = true;
            victoryTierAmountsClaimed[ticketResult.victoryTier] += ticketResult.amountWon;
            totalClaimed += ticketResult.amountWon;
        }
        for(uint i = 0; i < referralTicketResults.length; i++) {
            ReferralTicketResults memory referralTicketResult = referralTicketResults[i];
            ReferralTicket storage referralTicket = referralTickets[referralTicketResult.referralTicketId];
            referralTicket.claimed = true;
            victoryTierAmountsClaimed[RoundVictoryTier.Referrer] += referralTicketResult.amountWon;
            totalClaimed += referralTicketResult.amountWon;
        }
    }

    function markReferralVictoryClaimed(uint256 referralTicketId, uint256 amountClaimed) public onlyOwner {
        ReferralTicket storage referralTicket = referralTickets[referralTicketId];
        referralTicket.claimed = true;
        victoryTierAmountsClaimed[RoundVictoryTier.Referrer] += amountClaimed;
    }
}