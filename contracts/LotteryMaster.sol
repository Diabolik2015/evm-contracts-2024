// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";

    enum RoundVictoryTier {
        NO_WIN,
        Tier5_1,
        Tier5,
        Tier4_1,
        Tier4,
        Tier3_1,
        Tier3,
        PublicPool,
        Referrer,
        TokenHolders,
        Treasury
    }

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        bool ended;
        uint16[] roundNumbers;
        uint16 powerNumber;
        uint16[] referralWinnersNumber;
        uint16 referralWinnersNumberCount;
        uint256[] ticketIds;
        uint16 ticketsCount;
        uint256[] referralTicketIds;
        uint16 referralCounts;
    }

    struct Ticket {
        uint256 id;
        address participantAddress;
        address referralAddress;
        bool claimed;
        uint256 chainId;
        RoundVictoryTier victoryTier;
        uint16 powerNumber;
    }

    struct TicketResults {
        uint256 ticketId;
        RoundVictoryTier victoryTier;
    }

    struct ReferralTicket {
        uint256 id;
        address referralAddress;
        uint16 referralTicketNumber;
        bool winner;
        bool claimed;
    }

    struct ReferralTicketResults {
        uint256 referralTicketId;
        bool won;
    }

contract LotteryMaster is EmergencyFunctions {

    uint256 public roundCount;
    Round[] public rounds;
    function roundForId(uint256 roundId) public view returns (Round memory) {
        return rounds[roundId - 1];
    }

    function getCurrentRound() public view returns (Round memory) {
        return rounds[roundCount - 1];
    }
    mapping(uint256 => mapping(RoundVictoryTier => uint256)) winnersCountByTier;
    Ticket[] public tickets;
    function ticketAtIndex(uint256 ticketId) public view returns (Ticket memory) {
        return tickets[ticketId];
    }
    mapping(uint256 => uint16[]) public ticketNumbers;
    function numbersForTicketId(uint256 ticketId) public view returns (uint16[] memory) {
        return ticketNumbers[ticketId];
    }
    mapping(uint256 => mapping(address => uint256[])) public roundTicketsByAddress;
    mapping(uint256 => mapping(address => uint256)) public roundTicketsByAddressCount;

    ReferralTicket[] public referralTickets;
    function referralTicketAtIndex(uint256 index) public view returns (ReferralTicket memory) {
        return referralTickets[index];
    }
    mapping(uint256 => mapping(address => uint256[])) public roundReferralTicketsByAddress;
    mapping(uint256 => mapping(address => uint256)) public roundReferralTicketsByAddressCount;

    mapping(address => uint16) public freeRounds;
    mapping(uint => mapping(RoundVictoryTier => uint256)) public victoryTierAmounts;
    function victoryTierAmountFor(uint256 roundId, RoundVictoryTier victoryTier) public view returns (uint256) {
        return victoryTierAmounts[roundId][victoryTier];
    }
    address[] public bankWallets;
    uint16 public counterForBankWallets;
    function addBankWallet(address wallet) public onlyOwner {
        bankWallets.push(wallet);
    }
    uint256 public roundDurationInSeconds;
    function setRoundDurationInSeconds(uint256 _roundDuration) public onlyOwner {
        roundDurationInSeconds = _roundDuration;
    }
    IERC20Metadata public paymentToken;
    CyclixRandomizerInterface public randomizer;
    LotteryMasterReader public reader;
    uint256 public ticketPrice;

    constructor(address cyclixRandomizer, address _paymentToken, uint256 _ticketPrice, uint256 _roundDuration)
    EmergencyFunctions(msg.sender) {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = new LotteryMasterReader(this);
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
            referralWinnersNumber: new uint16[](0),
            referralWinnersNumberCount : 0,
            ticketIds : new uint256[](0),
            ticketsCount : 0,
            referralTicketIds : new uint256[](0),
            referralCounts : 0
        }));
        if (roundCount > 1) {
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier5_1] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier5_1];
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier5] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier5];
            victoryTierAmounts[roundCount][RoundVictoryTier.Tier4_1] = victoryTierAmounts[roundCount - 1][RoundVictoryTier.Tier4_1];
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

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, uint16 powerNumber, address referral ) public {
        validateBuyTicket(chosenNumbers, powerNumber, referral);

        if (freeRounds[msg.sender] > 0) {
            freeRounds[msg.sender]--;
        } else {
            counterForBankWallets = uint16(counterForBankWallets++ % bankWallets.length);
            paymentToken.transferFrom(msg.sender, bankWallets[counterForBankWallets], ticketPrice);
            updateVictoryPoolForTicket(ticketPrice);
        }

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
        rounds[roundCount - 1].ticketIds.push(ticketId);
        rounds[roundCount - 1].ticketsCount++;

        roundTicketsByAddress[roundCount][msg.sender].push(tickets.length - 1);
        roundTicketsByAddressCount[roundCount][msg.sender]++;
        if (referral != address(0)) {
            uint256 referralTicketId = referralTickets.length;
            rounds[roundCount - 1].referralTicketIds.push(referralTicketId);
            rounds[roundCount - 1].referralCounts++;
            referralTickets.push(ReferralTicket({
                id: referralTicketId,
                referralAddress: msg.sender,
                referralTicketNumber: uint16(rounds[roundCount - 1].referralCounts),
                winner: false,
                claimed: false
            }));

            roundReferralTicketsByAddress[roundCount][referral].push(referralTickets.length - 1);
            roundReferralTicketsByAddressCount[roundCount][referral]++;
        }
    }

    function addFreeRound(address[] calldata participant) public onlyOwner {
        for (uint i = 0; i < participant.length; i++) {
            freeRounds[participant[i]]++;
        }
    }

    mapping(uint256 => uint256) public publicRoundRandomNumbersRequestId;

    function closeRound() external onlyOwner {
        Round storage currentRound = rounds[roundCount - 1];
        require(block.timestamp >= currentRound.endTime, "Round is not over yet");
        currentRound.ended = true;
        publicRoundRandomNumbersRequestId[roundCount] = randomizer.requestRandomWords(6 + reader.numberOfReferralWinnersForRound(roundCount));
    }

    function fetchRoundNumbers(uint256 roundId) external onlyOwner {
        Round storage roundForNumbers = rounds[roundId - 1];
        require(roundForNumbers.ended == true, "Round should be closed to evaluate the numbers");
        require(roundForNumbers.powerNumber == 0, "Random numbers already fetched");
        (bool fulfilled, uint256[] memory randomWords) = randomizer.getRequestStatus(publicRoundRandomNumbersRequestId[roundId]);
        require(fulfilled, "Random numbers not ready");
        if (fulfilled) {
            for (uint i = 0; i < 5; i++) {
                roundForNumbers.roundNumbers.push(reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i], 69, roundForNumbers.roundNumbers));
            }
            roundForNumbers.powerNumber = uint16(randomWords[5] % 26 + 1);
            for (uint i = 6; i < randomWords.length; i++) {
                roundForNumbers.referralWinnersNumber.push(reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i],
                    roundForNumbers.referralCounts, roundForNumbers.referralWinnersNumber));
                roundForNumbers.referralWinnersNumberCount++;
            }
        }
    }

    function markWinners(uint256 roundId) public onlyOwner {
        TicketResults[] memory ticketResults = reader.evaluateWonResultsForTickets(roundId);
        for(uint16 i = 0; i < ticketResults.length; i++) {
            TicketResults memory ticketResult = ticketResults[i];
            Ticket storage ticket = tickets[ticketResult.ticketId - 1];
            if (ticketResult.victoryTier != RoundVictoryTier.NO_WIN) {
                ticket.victoryTier = ticketResult.victoryTier;
                winnersCountByTier[roundId][ticketResult.victoryTier]++;
            }
        }

        ReferralTicketResults[] memory referralTicketResults = reader.evaluateWonResultsForReferral(roundId);
        for(uint16 i = 0; i < referralTicketResults.length; i++) {
            ReferralTicketResults memory referralTicketResult = referralTicketResults[i];
            ReferralTicket storage referralTicket = referralTickets[referralTicketResult.referralTicketId - 1];
            if (referralTicketResult.won) {
                referralTicket.winner = true;
                winnersCountByTier[roundId][RoundVictoryTier.Referrer]++;
            }
        }
    }
}

contract LotteryMasterReader {
    LotteryMaster public lotteryMaster;

    constructor(LotteryMaster _lotteryMaster) {
        lotteryMaster = _lotteryMaster;
    }

    function poolForHighVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier5_1 || victoryTier == RoundVictoryTier.Tier5 || victoryTier == RoundVictoryTier.Tier4_1, "Invalid victory tier");
        return lotteryMaster.victoryTierAmountFor(roundId, victoryTier);
    }

    function poolForReferral(uint256 roundId) public view returns(uint256) {
        return lotteryMaster.victoryTierAmountFor(roundId,RoundVictoryTier.Referrer);
    }

    function priceForLowVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier4 || victoryTier == RoundVictoryTier.Tier3_1 || victoryTier == RoundVictoryTier.Tier3, "Invalid victory tier");
        return lotteryMaster.victoryTierAmountFor(roundId,victoryTier);
    }

    function tokenHoldersPoolAmount(uint256 roundId) public view returns (uint256) {
        return lotteryMaster.victoryTierAmountFor(roundId,RoundVictoryTier.TokenHolders);
    }

    function treasuryPoolAmount(uint256 roundId) public view returns (uint256) {
        return lotteryMaster.victoryTierAmountFor(roundId,RoundVictoryTier.Treasury);
    }

    function numberOfReferralWinnersForRound(uint256 roundId) public view returns (uint16) {
        uint16 referralWinnersForRound = 0;
        unchecked {
            referralWinnersForRound = lotteryMaster.roundForId(roundId).referralCounts / 10;
        }
        if (referralWinnersForRound == 0 && lotteryMaster.roundForId(roundId).referralCounts > 0) {
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
        Round memory roundForEvaluation = lotteryMaster.roundForId(roundId);
        uint16 roundTicketCount = roundForEvaluation.ticketsCount;
        TicketResults[] memory ticketResults = new TicketResults[](roundForEvaluation.ticketsCount);
        uint16 counter = 0;
        for(uint16 ticketIndexForRound = 0; ticketIndexForRound < roundTicketCount; ticketIndexForRound++) {
            Ticket memory ticket = lotteryMaster.ticketAtIndex(roundForEvaluation.ticketIds[ticketIndexForRound]);
            bool powerNumberFound = ticket.powerNumber == roundForEvaluation.powerNumber;
            uint16 rightNumbersForTicket = 0;
            uint16[] memory ticketNumbers = lotteryMaster.numbersForTicketId(ticket.id);
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
        Round memory roundForEvaluation = lotteryMaster.roundForId(roundId);
        uint16 roundReferralTicketCount = roundForEvaluation.referralCounts;
        ReferralTicketResults[] memory referralWinnerIds = new ReferralTicketResults[](roundForEvaluation.referralCounts);
        uint16 counter = 0;
        for(uint16 referralIndexForRound = 0; referralIndexForRound < roundReferralTicketCount; referralIndexForRound++) {
            ReferralTicket memory referralTicket = lotteryMaster.referralTicketAtIndex(roundForEvaluation.referralTicketIds[referralIndexForRound]);
            bool referralWon = existInArrayNumber(referralTicket.referralTicketNumber, roundForEvaluation.referralWinnersNumber);
            referralWinnerIds[counter++] = ReferralTicketResults({
                referralTicketId: referralTicket.id,
                won: referralWon
            });
        }
        return referralWinnerIds;
    }
}