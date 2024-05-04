// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import { LotteryRound } from "./LotteryRound.sol";
import { LotteryReaderInterface } from "./LotteryReaderInterface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LotteryRoundCreatorInterface.sol";
enum LotteryStatuses {
    DrawOpen,
    EvaluatingResults,
    ResultsEvaluated,
    ClaimInProgress
}

struct LotteryStatus {
    LotteryStatuses status;
    uint256 startTime;
    uint256 endTime;
    uint256 roundId;
}

contract LotteryMaster is EmergencyFunctions {

    uint256 public roundCount;
    address[] public rounds;
    LotteryStatus public lotteryStatus;
    function roundForId(uint256 roundId) public view returns (address) {
        return rounds[roundId - 1];
    }

    function getCurrentRound() public view returns (address) {
        return rounds[roundCount - 1];
    }
    mapping(address => uint16) public freeRounds;

    uint16 public counterForBankWallets;
    address[] public bankWallets;
    function addBankWallet(address wallet) public onlyOwner {
        for (uint i = 0; i < bankWallets.length; i++) {
            if (bankWallets[i] == wallet) {
                require(false, "Wallet already added");
            }
        }
        bankWallets.push(wallet);
    }
    function removeBankWallet(address wallet) public onlyOwner {
        for (uint i = 0; i < bankWallets.length; i++) {
            if (bankWallets[i] == wallet) {
                bankWallets[i] = bankWallets[bankWallets.length - 1];
                bankWallets.pop();
            }
        }
    }
    address public treasuryWallets;
    function setTreasuryWallet(address wallet) public onlyOwner {
        treasuryWallets = wallet;
    }
    IERC20Metadata public paymentToken;
    function setPaymentToken(address _paymentToken) public onlyOwner {
        paymentToken = IERC20Metadata(_paymentToken);
    }
    CyclixRandomizerInterface public randomizer;
    LotteryReaderInterface public reader;
    uint256 public ticketPrice;
    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }

    bool public freeRoundsAreEnabled = false;
    function setFreeRoundsOnPurchase(bool v) public onlyOwner {
        freeRoundsAreEnabled = v;
    }

    uint16 public percentageOfReferralWinners = 10;
    function setPercentageOfReferralWinners(uint16 percentage) public onlyOwner {
        percentageOfReferralWinners = percentage;
    }

    LotteryRoundCreatorInterface public lotteryRoundCreator;

    constructor(address cyclixRandomizer, address lotteryReader, address _lotteryRoundCreator, address _paymentToken, uint256 _ticketPrice)
    EmergencyFunctions(msg.sender) {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = LotteryReaderInterface(lotteryReader);
        lotteryRoundCreator = LotteryRoundCreatorInterface(_lotteryRoundCreator);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        treasuryWallets = msg.sender;
        bankWallets.push(msg.sender);
    }

    function startNewRound(uint256 roundDurationInSeconds) public onlyOwner {
        roundCount++;
        if (roundCount > 1) {
            rounds.push(lotteryRoundCreator.startNewRound(roundDurationInSeconds, rounds[roundCount - 2]));
            require(LotteryRound(rounds[roundCount - 2]).getRound().ended, "Previous round not ended");
            require(rounds[roundCount - 2] == LotteryRound(rounds[roundCount - 1]).previousRound(), "Previous round not propagated correctly");
        } else {
            rounds.push(lotteryRoundCreator.startNewRound(roundDurationInSeconds, address(0)));
        }
        lotteryStatus = LotteryStatus(LotteryStatuses.DrawOpen, block.timestamp, block.timestamp + roundDurationInSeconds, roundCount);
    }

    function buyTickets(uint256 chainId, uint16[] memory moreTicketNumbers, address referral) public {
        for (uint i = 0; i < moreTicketNumbers.length; i += 6) {
            uint16[] memory chosenNumbers = new uint16[](5);
            for (uint j = 0; j < 5; j++) {
                chosenNumbers[j] = moreTicketNumbers[i + j];
            }
            buyTicket(chainId, chosenNumbers, moreTicketNumbers[5], referral);
        }
    }

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, uint16 powerNumber, address referral) public {
        require(freeRounds[tx.origin] > 0 || paymentToken.allowance(tx.origin, address(this)) >= ticketPrice, "Missing Allowance");
        LotteryRound lotteryRound = LotteryRound(rounds[roundCount - 1]);
        if (freeRounds[msg.sender] > 0) {
            freeRounds[msg.sender]--;
        } else {
            require(paymentToken.balanceOf(tx.origin) >= ticketPrice, "Insufficient funds");
            counterForBankWallets = uint16(counterForBankWallets++ % bankWallets.length);
            uint256 treasuryAmount = lotteryRound.treasuryAmountOnTicket(ticketPrice);
            SafeERC20.safeTransferFrom(paymentToken, msg.sender, bankWallets[counterForBankWallets], ticketPrice - treasuryAmount);
            SafeERC20.safeTransferFrom(paymentToken, msg.sender, treasuryWallets, treasuryAmount);
            lotteryRound.updateVictoryPoolForTicket(ticketPrice);
            addFreeRoundForBuyTicket(msg.sender, referral);
        }

        lotteryRound.buyTicket(chainId, chosenNumbers, powerNumber, referral);
    }

    function addFreeRoundForBuyTicket(address buyer, address referral) internal {
        if (referral != address(0) && freeRoundsAreEnabled) {
            freeRounds[buyer]++;
            freeRounds[referral]++;
        }
    }

    function addFreeRound(address[] calldata participant) public onlyOwner {
        for (uint i = 0; i < participant.length; i++) {
            freeRounds[participant[i]]++;
        }
    }

    mapping(uint256 => uint256) public publicRoundRandomNumbersRequestId;

    function closeRound(uint256 durationOfResultEvaluationInSeconds) external onlyOwner {
        LotteryRound lotteryRound = LotteryRound(rounds[roundCount - 1]);
        lotteryRound.closeRound();
        uint16 referralWinners = reader.numberOfReferralWinnersForRoundId(roundCount);
        publicRoundRandomNumbersRequestId[roundCount] = randomizer.requestRandomWords(6 + referralWinners);
        lotteryStatus = LotteryStatus(LotteryStatuses.EvaluatingResults, block.timestamp, block.timestamp + durationOfResultEvaluationInSeconds, roundCount);
    }

    function fetchRoundNumbers(uint256 roundId, uint256 secondsBeforeStartingClaimingInSeconds) external onlyOwner {
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
        lotteryStatus = LotteryStatus(LotteryStatuses.ResultsEvaluated, block.timestamp, block.timestamp + secondsBeforeStartingClaimingInSeconds, roundId);
    }

    function markWinners(uint256 roundId, uint256 claimingTimeInSeconds) public onlyOwner {
        LotteryRound(rounds[roundId - 1]).markWinners(reader.evaluateWonResultsForTickets(roundId), reader.evaluateWonResultsForReferral(roundId));
        lotteryStatus = LotteryStatus(LotteryStatuses.ClaimInProgress, block.timestamp, block.timestamp + claimingTimeInSeconds, roundId);
    }

    function claimVictory(uint256 ticketId) public {
        LotteryRound lotteryRound = LotteryRound(getCurrentRound());
        Ticket memory ticket = lotteryRound.ticketById(ticketId);
        require(ticket.id == ticketId, "Invalid ticket id");
        require(ticket.participantAddress == msg.sender, "Invalid ticket owner");
        require(!ticket.claimed, "Ticket already claimed");
        require(lotteryRound.getRound().ended, "Round not ended");
        require(lotteryStatus.status == LotteryStatuses.ClaimInProgress, "Claim not started");
        require(block.timestamp > lotteryStatus.startTime, "Claim not started: too early");
        require(block.timestamp < lotteryStatus.endTime, "Claim not started: too late");
        require(ticket.victoryTier != RoundVictoryTier.NO_WIN, "No prize for this ticket");
        require(ticket.victoryTier == reader.evaluateWonResultsForOneTicket(lotteryRound.getRound().id, ticketId).victoryTier, "Invalid ticket tier");
        unchecked {
            uint256 amountWon = lotteryRound.victoryTierAmounts(ticket.victoryTier) / lotteryRound.winnersForEachTier(ticket.victoryTier);
            require(paymentToken.balanceOf(address(this)) >= amountWon, "Not enough funds on contract");
            LotteryRound(getCurrentRound()).markVictoryClaimed(ticketId, amountWon);
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
            LotteryRound(getCurrentRound()).markReferralVictoryClaimed(referralTicketId, amountWon);
            paymentToken.transfer(msg.sender, amountWon);
        }
    }
}
