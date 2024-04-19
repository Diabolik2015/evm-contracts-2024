// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";

    enum RoundVictoryTier {
        Tier5_1,
        Tier5,
        Tier4_1,
        Tier4,
        Tier3_1,
        Tier3,
        PublicPool,
        Referrer,
        TokenHolders,
        Treasury,
        NO_WIN
    }

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        bool ended;
        uint16[] roundNumbers;
        uint16 powerNumber;
        uint16[] referralWinnersIndexes;
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
        uint256 referralTicketNumber;
        bool winner;
        bool claimed;
    }

contract LotteryMaster is EmergencyFunctions {

    uint256 public roundCount;
    Round[] public rounds;
    mapping(uint256 => Ticket[]) public roundTickets;
    mapping(uint256 => uint256) public roundTicketsCount;
    mapping(uint256 => mapping(address => uint256[])) public roundTicketsByAddress;
    mapping(uint256 => mapping(address => uint256)) public roundTicketsByAddressCount;
    mapping(uint256 => ReferralTicket[]) public roundReferralTickets;
    mapping(uint256 => uint256) public roundReferralTicketsCount;
    mapping(uint256 => mapping(address => uint256[])) public roundReferralTicketsByAddress;
    mapping(uint256 => mapping(address => uint256)) public roundReferralTicketsByAddressCount;
    mapping(address => uint16) public freeRounds;
    mapping(uint => mapping(RoundVictoryTier => uint256)) public victoryTierAmounts;
    uint256 public roundDurationInSeconds;
    function setRoundDurationInSeconds(uint256 _roundDuration) public onlyOwner {
        roundDurationInSeconds = _roundDuration;
    }
    IERC20Metadata public paymentToken;
    CyclixRandomizerInterface public randomizer;
    uint256 public ticketPrice;

    constructor(address cyclixRandomizer, address _paymentToken, uint256 _ticketPrice, uint256 _roundDuration)
    EmergencyFunctions(msg.sender) {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
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
            ended : false,
            roundNumbers: new uint16[](0),
            powerNumber: 0,
            referralWinnersIndexes: new uint16[](0)
        }));
        if (roundCount > 1) {
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier5_1] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier5_1];
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier5] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier5];
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier4_1] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier4_1];
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier4] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier4];
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier3_1] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier3_1];
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier3] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier3];
            victoryTierAmounts[roundCount][RoundVictoryTier.Referrer] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Referrer];
            victoryTierAmounts[roundCount][RoundVictoryTier.TokenHolders] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.TokenHolders];
            victoryTierAmounts[roundCount][RoundVictoryTier.Treasury] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Treasury];
        }
    }

    function numberIsInRangeForRound(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 69;
    }

    function numberIsInRangeForPowerNumber(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 26;
    }

    function validateBuyTicket(uint16[] memory numbers, uint16 powerNumber, address referral ) public view {
        require(roundCount > 0, "No active round");
        require(block.timestamp < rounds[roundCount - 1].endTime, "Round is over");
        require(numbers.length == 5, "Invalid numbers count");
        for (uint i = 0; i < numbers.length; i++) {
            require(numberIsInRangeForRound(numbers[i]), "Invalid numbers");
        }
        require(numberIsInRangeForPowerNumber(powerNumber), "Invalid power number");
        require(referral != msg.sender, "Referral cannot be the same as the participant");
        require(paymentToken.balanceOf(msg.sender) >= ticketPrice, "Insufficient funds");
        require(freeRounds[msg.sender] > 0 || paymentToken.allowance(msg.sender, address(this)) >= ticketPrice, "Missing Allowance");
    }

    function percentageInBasisPoint(uint256 amount, uint256 basisPoint) public pure returns (uint256) {
        return amount * basisPoint / 10000;
    }

    function updateVictoryPoolForTicket(uint256 paymentTokenAmount) internal {
        uint256 roundId = roundCount;
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
        victoryTierAmounts[roundId][RoundVictoryTier.Tier5_1] += tier5_1;
        victoryTierAmounts[roundId][RoundVictoryTier.Tier5] += tier5;
        victoryTierAmounts[roundId][RoundVictoryTier.Tier4_1] += tier4_1;
        victoryTierAmounts[roundId][RoundVictoryTier.Tier4] += tier4;
        victoryTierAmounts[roundId][RoundVictoryTier.Tier3_1] += tier3_1;
        victoryTierAmounts[roundId][RoundVictoryTier.Tier3] += tier3;
        victoryTierAmounts[roundId][RoundVictoryTier.PublicPool] += publicPool;
        victoryTierAmounts[roundId][RoundVictoryTier.Referrer] += referrer;
        victoryTierAmounts[roundId][RoundVictoryTier.TokenHolders] += tokenHoldersPool;
        victoryTierAmounts[roundId][RoundVictoryTier.Treasury] += treasury;
    }

    function buyTicket(uint256 chainId, uint16[] memory numbers, uint16 powerNumber, address referral ) public {
        validateBuyTicket(numbers, powerNumber, referral);

        if (freeRounds[msg.sender] > 0) {
            freeRounds[msg.sender]--;
        } else {
            paymentToken.transferFrom(msg.sender, address(this), ticketPrice);
            updateVictoryPoolForTicket(ticketPrice);
        }

        roundTickets[roundCount].push(Ticket({
            participantAddress: msg.sender,
            referralAddress: referral,
            numbers: numbers,
            powerNumber: powerNumber,
            winner: false,
            claimed: false,
            chainId: chainId,
            victoryTier: RoundVictoryTier.NO_WIN
        }));
        roundTicketsCount[roundCount]++;
        roundTicketsByAddress[roundCount][msg.sender].push(roundTickets[roundCount].length - 1);
        roundTicketsByAddressCount[roundCount][msg.sender]++;
        Round storage currentRound = rounds[roundCount - 1];
        if (referral != address(0)) {
            roundReferralTicketsCount[roundCount]++;
            roundReferralTickets[roundCount].push(ReferralTicket({
                referralAddress: msg.sender,
                referralTicketNumber: roundReferralTicketsCount[roundCount],
                winner: false,
                claimed: false
            }));
            roundReferralTicketsByAddress[roundCount][referral].push(roundReferralTickets[roundCount].length - 1);
            roundReferralTicketsByAddressCount[roundCount][referral]++;
        }
    }

    function addFreeRound(address[] calldata participant) public onlyOwner {
        for (uint i = 0; i < participant.length; i++) {
            freeRounds[participant[i]]++;
        }
    }

    function poolForHighVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier5_1 || victoryTier == RoundVictoryTier.Tier5 || victoryTier == RoundVictoryTier.Tier4_1, "Invalid victory tier");
        return victoryTierAmounts[roundId][victoryTier];
    }

    function poolForReferral(uint256 roundId) public view returns(uint256) {
        return victoryTierAmounts[roundId][RoundVictoryTier.Referrer];
    }

    function priceForLowVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier4 || victoryTier == RoundVictoryTier.Tier3_1 || victoryTier == RoundVictoryTier.Tier3, "Invalid victory tier");
        return victoryTierAmounts[roundId][victoryTier];
    }

    function tokenHoldersPoolAmount(uint256 roundId) public view returns (uint256) {
        return victoryTierAmounts[roundId][RoundVictoryTier.TokenHolders];
    }

    function treasuryAmount(uint256 roundId) public view returns (uint256) {
        return victoryTierAmounts[roundId][RoundVictoryTier.Treasury];
    }

    function getCurrentRound() public view returns (Round memory) {
        return rounds[roundCount - 1];
    }

    mapping(uint256 => uint256) public publicRoundRandomNumbersRequestId;

    function closeRound() external onlyOwner {
        Round storage currentRound = rounds[roundCount - 1];
        require(block.timestamp >= currentRound.endTime, "Round is not over yet");
        currentRound.ended = true;
        uint32 randomNumbersForReferrals = 0;
        unchecked {
            randomNumbersForReferrals = randomNumbersForReferrals / 10;
        }
        if (randomNumbersForReferrals == 0 && roundReferralTicketsCount[roundCount] > 0) {
            randomNumbersForReferrals = 1;
        }
        publicRoundRandomNumbersRequestId[roundCount] = randomizer.requestRandomWords(6 + randomNumbersForReferrals);
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

    function fetchRoundNumbers(uint256 roundId) external onlyOwner {
        Round storage roundForNumbers = rounds[roundId - 1];
        require(roundForNumbers.ended == true, "Round should be closed to evaluate the numbers");
        require(roundForNumbers.powerNumber == 0, "Random numbers already fetched");
        (bool fulfilled, uint256[] memory randomWords) = randomizer.getRequestStatus(publicRoundRandomNumbersRequestId[roundId]);
        require(fulfilled, "Random numbers not ready");
        if (fulfilled) {
            for (uint i = 0; i < 5; i++) {
                roundForNumbers.roundNumbers.push(getRandomUniqueNumberInArrayForMaxValue(randomWords[i], 69, roundForNumbers.roundNumbers));
            }
            roundForNumbers.powerNumber = uint16(randomWords[5] % 26 + 1);
            for (uint i = 6; i < randomWords.length; i++) {
                roundForNumbers.referralWinnersIndexes.push(getRandomUniqueNumberInArrayForMaxValue(randomWords[i],
                    uint16(roundReferralTicketsCount[roundCount]), roundForNumbers.referralWinnersIndexes));
            }
        }
    }

    function getPublicRoundWinningNumbers(uint256 roundId) public view returns (uint16[] memory) {
        return rounds[roundId - 1].roundNumbers;
    }

    function getPublicRoundPowerNumber(uint256 roundId) public view returns (uint16) {
        return rounds[roundId - 1].powerNumber;
    }

    function getReferralWinnersIndexes(uint256 roundId) public view returns (uint16[] memory) {
        return rounds[roundId - 1].referralWinnersIndexes;
    }

    function markWinnerTickets(uint256 roundId, uint16[] memory ticketIndexes, uint16 referralTicketIndexes) public {

    }
}
