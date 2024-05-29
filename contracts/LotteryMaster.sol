// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";
import { LotteryRoundInterface } from "./LotteryRoundInterface.sol";
import { LotteryReaderInterface } from "./LotteryReaderInterface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LotteryRoundCreatorInterface.sol";
import {LotteryMasterInterface} from "./LotteryMasterInterface.sol";
    enum LotteryStatuses {
        DrawOpen,
        EvaluatingResults,
        ResultsEvaluated,
        ClaimInProgress
    }

contract LotteryMaster is EmergencyFunctions, LotteryMasterInterface{

    uint chainId;
    uint256 public roundCount;
    address[] public rounds;
    LotteryStatuses public lotteryStatus;
    uint256 public statusStartTime;
    uint256 public statusEndTime;

    mapping(uint256 => mapping(address => uint256)) public freeRounds;
    function addFreeRound(address[] calldata participant, uint256[] calldata freeTicketAmounts) public onlyOwner {
        for (uint i = 0; i < participant.length; i++) {
            freeRounds[roundCount][participant[i]] += freeTicketAmounts[i];
        }
    }

    uint16 public counterForBankWallets;
    address[] public bankWallets;
    function setBankWallet(address wallet, bool add) public onlyOwner {
        for (uint i = 0; i < bankWallets.length; i++) {
            if (bankWallets[i] == wallet) {
                if (add) {
                    require(false, "Wallet already added");
                } else {
                    bankWallets[i] = bankWallets[bankWallets.length - 1];
                    bankWallets.pop();
                }
            }
        }
        if (add) {
            bankWallets.push(wallet);
        }
    }

    IERC20Metadata public paymentToken;
    CyclixRandomizerInterface public randomizer;
    LotteryReaderInterface public reader;
    uint256 public ticketPrice;
    bool public freeRoundsAreEnabled = false;
    uint16 public percentageOfReferralWinners = 10;
    LotteryRoundCreatorInterface public lotteryRoundCreator;

    constructor(address cyclixRandomizer, address lotteryReader, address _lotteryRoundCreator, address _paymentToken, uint256 _ticketPrice, bool _freeRoundsAreEnabled)
    EmergencyFunctions(msg.sender) {
        chainId = block.chainid;
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = LotteryReaderInterface(lotteryReader);
        lotteryRoundCreator = LotteryRoundCreatorInterface(_lotteryRoundCreator);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        freeRoundsAreEnabled = _freeRoundsAreEnabled;
        bankWallets.push(msg.sender);
    }

    function updateSetup(address cyclixRandomizer, address lotteryReader, address _lotteryRoundCreator, address _paymentToken, uint256 _ticketPrice,
        uint16 _percentageOfReferralWinners, uint16[] memory _poolPercentagesBasePoints, bool _freeRoundsAreEnabled) public onlyOwner {
        if (address(randomizer) != cyclixRandomizer) {
            randomizer = CyclixRandomizerInterface(cyclixRandomizer);
            randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        }
        reader = LotteryReaderInterface(lotteryReader);
        lotteryRoundCreator = LotteryRoundCreatorInterface(_lotteryRoundCreator);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        percentageOfReferralWinners = _percentageOfReferralWinners;
        LotteryRoundInterface(rounds[roundCount - 1]).setPoolPercentagesBasePoints(_poolPercentagesBasePoints);
        freeRoundsAreEnabled = _freeRoundsAreEnabled;
    }

    function startNewRound(uint256 _statusEndTime) public onlyOwner {
        if (roundCount > 0) {
            LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
            startNewRoundForUpgrade(_statusEndTime, rounds[roundCount - 1], lotteryRound.getRound().uiId + 1);
        } else {
            startNewRoundForUpgrade(_statusEndTime, address(0), 1);
        }
    }

    function startNewRoundForUpgrade(uint256 _statusEndTime, address previousRound, uint256 uiId) public onlyOwner {
        roundCount++;
        require(previousRound == address(0) || (lotteryStatus == LotteryStatuses.ClaimInProgress && statusEndTime < block.timestamp) || statusEndTime == 0, "Previous round not ended");
        rounds.push(lotteryRoundCreator.startNewRound(_statusEndTime, previousRound, roundCount, uiId));
        setLotteryStatus(LotteryStatuses.DrawOpen, _statusEndTime);
    }

    function setLotteryStatus(LotteryStatuses _lotteryStatus, uint256 _statusEndTime) internal onlyOwner {
        lotteryStatus = _lotteryStatus;
        statusStartTime = block.timestamp;
        statusEndTime = block.timestamp + _statusEndTime;
    }

    function buyTickets(uint16[] memory moreTicketNumbers, address referral, address buyer) public override {
        uint256 paidWithFreeTicket = 0;
        for (uint i = 0; i < moreTicketNumbers.length; i += 6) {
            uint16[] memory chosenNumbers = new uint16[](6);
            for (uint j = 0; j < 6; j++) {
                chosenNumbers[j] = moreTicketNumbers[i + j];
            }
            if (buyTicket(chosenNumbers, referral, buyer)) {
                paidWithFreeTicket += 1;
            }
        }

        if (referral != address(0) && freeRoundsAreEnabled) {
            unchecked {
                freeRounds[roundCount][buyer] = freeRounds[roundCount][buyer] + moreTicketNumbers.length / 6 - paidWithFreeTicket;
                freeRounds[roundCount][referral] = freeRounds[roundCount][referral] + moreTicketNumbers.length / 6 - paidWithFreeTicket;
            }
        }
    }

    function buyTicket(uint16[] memory chosenNumbers, address referral, address buyer) internal returns(bool) {
        require(freeRounds[roundCount][buyer] > 0
        || paymentToken.allowance(buyer, address(this)) >= ticketPrice
        || crossChainOperator[msg.sender], "Missing Allowance");
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        bool paidWithFreeTicket = false;
        if (freeRounds[roundCount][buyer] > 0) {
            freeRounds[roundCount][buyer]--;
            paidWithFreeTicket = true;
        } else {
            if (!crossChainOperator[msg.sender]) {
                require(paymentToken.balanceOf(tx.origin) >= ticketPrice, "Insufficient funds");
                counterForBankWallets = uint16(counterForBankWallets++ % bankWallets.length);
                SafeERC20.safeTransferFrom(paymentToken, buyer, bankWallets[counterForBankWallets], ticketPrice);
            }
            lotteryRound.updateVictoryPoolForTicket(ticketPrice);
        }

        if (paidWithFreeTicket) {
            lotteryRound.buyTicket(chainId, chosenNumbers, address(0), buyer);
        } else {
            lotteryRound.buyTicket(chainId, chosenNumbers, referral, buyer);
        }
        return paidWithFreeTicket;
    }

    mapping(uint256 => uint256) public publicRoundRandomNumbersRequestId;

    function closeRound(uint256 _statusEndTime, uint32 referralWinners) external onlyOwner {
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        lotteryRound.closeRound();
        publicRoundRandomNumbersRequestId[roundCount] = randomizer.requestRandomWords(6 + referralWinners);
        setLotteryStatus(LotteryStatuses.EvaluatingResults, _statusEndTime);
    }

    function fetchRoundNumbers(uint256 roundId, uint256 _statusEndTime, uint16 referralWinnersCountCrossChain) external onlyOwner {
        LotteryRoundInterface round = LotteryRoundInterface(rounds[roundId - 1]);
        round.couldReceiveWinningNumbers();
        (bool fulfilled, uint256[] memory randomWords) = randomizer.getRequestStatus(publicRoundRandomNumbersRequestId[roundId]);
        require(fulfilled, "Random numbers not ready");
        uint16[] memory roundNumbers = new uint16[](6);
        uint16[] memory referralWinnersNumber = new uint16[](randomWords.length - 6);
        if (fulfilled) {
            for (uint i = 0; i < 6; i++) {
                roundNumbers[i] = reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i], 69, roundNumbers);
            }
            roundNumbers[5] = uint16(randomWords[5] % 26 + 1);
            for (uint i = 6; i < randomWords.length; i++) {
                referralWinnersNumber [i - 6] = reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i],
                    referralWinnersCountCrossChain, referralWinnersNumber);
            }
        }
        round.storeWinningNumbers(roundNumbers, referralWinnersNumber);
        setLotteryStatus(LotteryStatuses.ResultsEvaluated, _statusEndTime);
    }

    function markWinners(uint256 roundId, uint256 _statusEndTime, uint256[] memory amountWonForEachTicketCrossChain) public onlyOwner {
        LotteryRoundInterface(rounds[roundId - 1]).markWinners(reader.evaluateWonTicketsForRound(roundId), reader.evaluateWonReferralForRound(roundId), amountWonForEachTicketCrossChain);
        setLotteryStatus(LotteryStatuses.ClaimInProgress, _statusEndTime);
    }

    function claimVictory() public {
        require(lotteryStatus == LotteryStatuses.ClaimInProgress, "Lottery is not in claim period");
        require(statusEndTime > block.timestamp, "Claim Period ended");
        uint256 amountForEntries = reader.evaluateWonTicketsAmountForWallet(roundCount, msg.sender, false);
        uint256 amountForReferral = reader.evaluateWonReferralAmountForWallet(roundCount, msg.sender, false);
        require(amountForEntries > 0 || amountForReferral > 0, "Nothing to claim for this wallet");
        require(paymentToken.balanceOf(address(this)) >= amountForEntries + amountForReferral, "Not enough funds on contract");
        LotteryRoundInterface(rounds[roundCount - 1]).markVictoryClaimed(
            reader.evaluateWonTicketsForWallet(roundCount, msg.sender),
            reader.evaluateWonReferralFoWallet(roundCount, msg.sender)
        );
        paymentToken.transfer(msg.sender, amountForEntries + amountForReferral);
    }
}