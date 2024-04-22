// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import { LotteryMaster } from "./LotteryMaster.sol";

contract LotteryRound is EmergencyFunctions {
    Round public round;
    function getRound() public view returns (Round memory) {
        return round;
    }

    Ticket[] public tickets;
    function ticketAtIndex(uint256 ticketId) public view returns (Ticket memory) {
        return tickets[ticketId];
    }
    mapping(uint256 => uint16[]) public ticketNumbers;
    function numbersForTicketId(uint256 ticketId) public view returns (uint16[] memory) {
        return ticketNumbers[ticketId];
    }
    mapping(address => uint256[]) public roundTicketsByAddress;
    mapping(address => uint256) public roundTicketsByAddressCount;

    ReferralTicket[] public referralTickets;
    function referralTicketAtIndex(uint256 index) public view returns (ReferralTicket memory) {
        return referralTickets[index];
    }
    mapping(address => uint256[]) public roundReferralTicketsByAddress;
    mapping(address => uint256) public roundReferralTicketsByAddressCount;

    mapping(RoundVictoryTier => uint256) public victoryTierAmounts;

    constructor(address previousRoundAddress, uint16 roundDurationInSeconds) EmergencyFunctions(msg.sender) {
        uint256 id = 1;
        if (previousRoundAddress != address(0)) {
            LotteryRound previousLotteryRound = LotteryRound(previousRoundAddress);
            Round memory previousRound = previousLotteryRound.getRound();
            id = previousRound.id + 1;
        }
        round = Round({
            id: id,
            startTime: block.timestamp,
            endTime: block.timestamp + roundDurationInSeconds,
            ended : false,
            roundNumbers: new uint16[](0),
            powerNumber: 0,
            referralWinnersNumber: new uint16[](0),
            referralWinnersNumberCount : 0,
            ticketIds : new uint256[](0),
            ticketsCount : 0,
            referralTicketIds : new uint256[](0),
            referralCounts : 0
        });
    }

    function numberIsInRangeForRound(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 69;
    }

    function numberIsInRangeForPowerNumber(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 26;
    }

    function validateBuyTicket(uint16[] memory numbers, uint16 powerNumber, address referral ) public view onlyOwner {
        require(tx.origin != address(0), "Invalid sender");
        require(block.timestamp < round.endTime, "Round is over");
        require(numbers.length == 5, "Invalid numbers count");
        for (uint i = 0; i < numbers.length; i++) {
            require(numberIsInRangeForRound(numbers[i]), "Invalid numbers");
        }
        require(numberIsInRangeForPowerNumber(powerNumber), "Invalid power number");
        require(referral != tx.origin, "Referral cannot be the same as the participant");
    }

    function percentageInBasisPoint(uint256 amount, uint256 basisPoint) public pure returns (uint256) {
        return amount * basisPoint / 10000;
    }

    function updateVictoryPoolForTicket(uint256 paymentTokenAmount) public onlyOwner {
        uint256 forPublicPool = percentageInBasisPoint(paymentTokenAmount, 7000);
        uint256 tier5_1 = percentageInBasisPoint(forPublicPool, 3500) ;
        uint256 tier5 = percentageInBasisPoint(forPublicPool, 1500);
        uint256 tier4_1 = percentageInBasisPoint(forPublicPool, 1000);
        uint256 tier4 = percentageInBasisPoint(forPublicPool, 500);
        uint256 tier3_1 = percentageInBasisPoint(forPublicPool, 200);
        uint256 tier3 = percentageInBasisPoint(forPublicPool, 20);
        uint256 publicPool = forPublicPool;
        uint256 referrer = percentageInBasisPoint(paymentTokenAmount, 1500);
        uint256 tokenHoldersPool = percentageInBasisPoint(paymentTokenAmount, 1000);
        uint256 treasury = percentageInBasisPoint(paymentTokenAmount, 5000);
        victoryTierAmounts[RoundVictoryTier.Tier5_1] += tier5_1;
        victoryTierAmounts[RoundVictoryTier.Tier5] += tier5;
        victoryTierAmounts[RoundVictoryTier.Tier4_1] += tier4_1;
        victoryTierAmounts[RoundVictoryTier.Tier4] += tier4;
        victoryTierAmounts[RoundVictoryTier.Tier3_1] += tier3_1;
        victoryTierAmounts[RoundVictoryTier.Tier3] += tier3;
        victoryTierAmounts[RoundVictoryTier.PublicPool] += publicPool;
        victoryTierAmounts[RoundVictoryTier.Referrer] += referrer;
        victoryTierAmounts[RoundVictoryTier.TokenHolders] += tokenHoldersPool;
        victoryTierAmounts[RoundVictoryTier.Treasury] += treasury;
    }

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, uint16 powerNumber, address referral) public onlyOwner {
        validateBuyTicket(chosenNumbers, powerNumber, referral);

        uint256 ticketId = tickets.length;
        tickets.push(Ticket({
            id: ticketId,
            participantAddress: msg.sender,
            referralAddress: referral,
            claimed: false,
            chainId: chainId,
            victoryTier: RoundVictoryTier.NO_WIN,
            powerNumber: powerNumber
        }));
        for(uint i = 0; i < chosenNumbers.length; i++) {
            ticketNumbers[ticketId].push(chosenNumbers[i]);
        }
        round.ticketIds.push(ticketId);
        round.ticketsCount++;

        roundTicketsByAddress[msg.sender].push(tickets.length - 1);
        roundTicketsByAddressCount[msg.sender]++;
        if (referral != address(0)) {
            uint256 referralTicketId = referralTickets.length;
            round.referralTicketIds.push(referralTicketId);
            round.referralCounts++;
            referralTickets.push(ReferralTicket({
                id: referralTicketId,
                referralAddress: msg.sender,
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

    function storeWinningNumbers(uint16[] memory roundNumbers, uint16 powerNumber, uint16[] memory referralWinnersNumber) public onlyOwner {
        round.roundNumbers = roundNumbers;
        round.powerNumber = powerNumber;
        round.referralWinnersNumber = referralWinnersNumber;
        round.referralWinnersNumberCount = uint16(referralWinnersNumber.length);
    }
}