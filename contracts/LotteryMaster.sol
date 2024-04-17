// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";

    enum RoundVictoryTier {
        Jackpot,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5,
        Tier6,
        NO_WIN
    }

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint16[] roundNumbers;
        uint16 powerNumber;
        uint256 pricePool;
        uint256 ticketsCount;
        uint256 referralMaxNumbers;
    }

    struct Ticket {
        address participantAddress;
        address referralAddress;
        uint16[] numbers;
        uint16 powerNumber;
        bool winner;
        bool claimed;
        uint256 chainId;
        RoundVictoryTier victoryTier;
    }

    struct ReferralTicket {
        address referralAddress;
        uint256 referralNumber;
    }

contract LotteryMaster is Ownable, TestFunctions {

    uint256 public roundCount;
    Round[] public rounds;
    mapping(uint256 => Ticket[]) public roundTickets;
    mapping(uint256 => mapping(address => Ticket[])) public roundParticipantTickets;
    mapping(uint256 => mapping(address => uint256)) public roundParticipantTicketsCount;
    mapping(uint256 => mapping(address => ReferralTicket[])) public roundReferralTickets;
    mapping(uint256 => mapping(address => uint256)) public roundReferralTicketsCount;
    uint256 public roundDurationInSeconds;
    function setRoundDurationInSeconds(uint256 _roundDuration) public onlyOwner {
        roundDurationInSeconds = _roundDuration;
    }
    IERC20Metadata public paymentToken;
    uint256 public ticketPrice;

    constructor(address cyclixRandomizer, address _paymentToken, uint256 _ticketPrice, uint256 _roundDuration) {
        CyclixRandomizerInterface(cyclixRandomizer).registerGameContract(address(this), "LotteryMasterV0.1");
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        roundDurationInSeconds = _roundDuration;
    }

    function startNewRound() public onlyOwner {
        roundCount++;
        rounds.push(Round({
            id: roundCount,
            startTime: block.timestamp,
            endTime: block.timestamp + roundDurationInSeconds,
            roundNumbers: new uint16[](0),
            powerNumber: 0,
            ticketsCount: 0,
            pricePool : 0,
            referralMaxNumbers: 0
        }));
    }

    function numberIsInRangeForRound(uint256 number) public view returns (bool) {
        return number > 0 && number <= 69;
    }

    function validateBuyTicket(uint16[] memory numbers, uint16 powerNumber, address referral ) public {
        require(roundCount > 0, "No active round");
        require(block.timestamp < rounds[roundCount - 1].endTime, "Round is over");
        require(numbers.length == 5, "Invalid numbers count");
        for (uint i = 0; i < numbers.length; i++) {
            require(numberIsInRangeForRound(numbers[i]), "Invalid numbers");
        }
        require(numberIsInRangeForRound(powerNumber), "Invalid power number");
        require(referral != msg.sender, "Referral cannot be the same as the participant");
        require(paymentToken.balanceOf(msg.sender) >= ticketPrice, "Insufficient funds");
        require(paymentToken.allowance(msg.sender, address(this)) >= ticketPrice, "Missing Allowance");
    }

    function buyTicket(uint256 chainId, uint16[] memory numbers, uint16 powerNumber, address referral ) public {
        validateBuyTicket(numbers, powerNumber, referral);

        paymentToken.transferFrom(msg.sender, address(this), ticketPrice);

        Ticket memory ticket = Ticket({
            participantAddress: msg.sender,
            referralAddress: referral,
            numbers: numbers,
            powerNumber: powerNumber,
            winner: false,
            claimed: false,
            chainId: chainId,
            victoryTier: RoundVictoryTier.NO_WIN
        });
        roundTickets[roundCount - 1].push(ticket);
        roundParticipantTickets[roundCount - 1][msg.sender].push(ticket);
        roundParticipantTicketsCount[roundCount - 1][msg.sender]++;
        Round storage currentRound = rounds[roundCount - 1];
        currentRound.ticketsCount++;
        currentRound.pricePool += ticketPrice;
        if (referral != address(0)) {
            roundReferralTickets[roundCount - 1][referral].push(ReferralTicket({
                referralAddress: msg.sender,
                referralNumber: currentRound.ticketsCount
            }));
            roundReferralTicketsCount[roundCount - 1][referral]++;
            currentRound.referralMaxNumbers++;
        }
    }

    function getCurrentRound() external view returns (Round memory) {
        return rounds[roundCount - 1];
    }
}