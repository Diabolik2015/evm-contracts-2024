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
    enum LotteryStatuses {
        DrawOpen,
        EvaluatingResults,
        ResultsEvaluated,
        ClaimInProgress
    }

contract LotteryMaster is EmergencyFunctions {

    uint256 public roundCount;
    address[] public rounds;
    LotteryStatuses public lotteryStatus;
    uint256 public statusStartTime;
    uint256 public statusEndTime;

    mapping(address => uint16) public freeRounds;
    mapping(address => bool) public crossChainOperator;
    function setCrossChainOperator(address operator, bool value) public onlyOwner {
        crossChainOperator[operator] = value;
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

    address public treasuryWallets;
    IERC20Metadata public paymentToken;
    CyclixRandomizerInterface public randomizer;
    LotteryReaderInterface public reader;
    uint256 public ticketPrice;
    bool public freeRoundsAreEnabled = false;
    uint16 public percentageOfReferralWinners = 10;
    LotteryRoundCreatorInterface public lotteryRoundCreator;

    constructor(address cyclixRandomizer, address lotteryReader, address _lotteryRoundCreator, address _paymentToken, uint256 _ticketPrice, bool _freeRoundsAreEnabled)
    EmergencyFunctions(msg.sender) {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = LotteryReaderInterface(lotteryReader);
        lotteryRoundCreator = LotteryRoundCreatorInterface(_lotteryRoundCreator);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        freeRoundsAreEnabled = _freeRoundsAreEnabled;
        treasuryWallets = msg.sender;
        bankWallets.push(msg.sender);
    }

    function updateSetup(address cyclixRandomizer, address lotteryReader, address _lotteryRoundCreator, address _paymentToken, uint256 _ticketPrice,
        address _treasuryWallet, uint16 _percentageOfReferralWinners, uint16[] memory _poolPercentagesBasePoints, bool _freeRoundsAreEnabled) public onlyOwner {
        if (address(randomizer) != cyclixRandomizer) {
            randomizer = CyclixRandomizerInterface(cyclixRandomizer);
            randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        }
        reader = LotteryReaderInterface(lotteryReader);
        lotteryRoundCreator = LotteryRoundCreatorInterface(_lotteryRoundCreator);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        treasuryWallets = _treasuryWallet;
        percentageOfReferralWinners = _percentageOfReferralWinners;
        LotteryRoundInterface(rounds[roundCount - 1]).setPoolPercentagesBasePoints(_poolPercentagesBasePoints);
        freeRoundsAreEnabled = _freeRoundsAreEnabled;
    }

    function startNewRound(uint256 _statusEndTime) public onlyOwner {
        roundCount++;
        if (roundCount > 1) {
            rounds.push(lotteryRoundCreator.startNewRound(_statusEndTime, rounds[roundCount - 2]));
            require(lotteryStatus == LotteryStatuses.ClaimInProgress && statusEndTime < block.timestamp, "Previous round not ended");
        } else {
            rounds.push(lotteryRoundCreator.startNewRound(_statusEndTime, address(0)));
        }
        setLotteryStatus(LotteryStatuses.DrawOpen, _statusEndTime);
    }

    function setLotteryStatus(LotteryStatuses _lotteryStatus, uint256 _statusEndTime) internal onlyOwner {
        lotteryStatus = _lotteryStatus;
        statusStartTime = block.timestamp;
        statusEndTime = block.timestamp + _statusEndTime;
    }

    function buyTickets(uint256 chainId, uint16[] memory moreTicketNumbers, address referral, address buyer) public {
        for (uint i = 0; i < moreTicketNumbers.length; i += 6) {
            uint16[] memory chosenNumbers = new uint16[](6);
            for (uint j = 0; j < 6; j++) {
                chosenNumbers[j] = moreTicketNumbers[i + j];
            }
            buyTicket(chainId, chosenNumbers, referral, buyer);
        }
    }

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, address referral, address buyer) public {
        require(freeRounds[buyer] > 0
        || paymentToken.allowance(buyer, address(this)) >= ticketPrice
        || crossChainOperator[msg.sender], "Missing Allowance");
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        if (freeRounds[buyer] > 0) {
            freeRounds[buyer]--;
        } else {
            if (!crossChainOperator[msg.sender]) {
                require(paymentToken.balanceOf(tx.origin) >= ticketPrice, "Insufficient funds");
                counterForBankWallets = uint16(counterForBankWallets++ % bankWallets.length);
                uint256 treasuryAmount = lotteryRound.treasuryAmountOnTicket(ticketPrice);
                SafeERC20.safeTransferFrom(paymentToken, buyer, bankWallets[counterForBankWallets], ticketPrice - treasuryAmount);
                SafeERC20.safeTransferFrom(paymentToken, buyer, treasuryWallets, treasuryAmount);
            }
            lotteryRound.updateVictoryPoolForTicket(ticketPrice);

            if (referral != address(0) && freeRoundsAreEnabled) {
                freeRounds[buyer]++;
                freeRounds[referral]++;
            }
        }

        lotteryRound.buyTicket(chainId, chosenNumbers, referral, buyer);
    }

    function addFreeRound(address[] calldata participant) public onlyOwner {
        for (uint i = 0; i < participant.length; i++) {
            freeRounds[participant[i]]++;
        }
    }

    mapping(uint256 => uint256) public publicRoundRandomNumbersRequestId;

    function closeRound(uint256 _statusEndTime) external onlyOwner {
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        lotteryRound.closeRound();
        uint16 referralWinners = reader.numberOfReferralWinnersForRoundId(roundCount);
        publicRoundRandomNumbersRequestId[roundCount] = randomizer.requestRandomWords(6 + referralWinners);
        setLotteryStatus(LotteryStatuses.EvaluatingResults, _statusEndTime);
    }

    function fetchRoundNumbers(uint256 roundId, uint256 _statusEndTime) external onlyOwner {
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
                    round.getRound().referralCounts, referralWinnersNumber);
            }
        }
        round.storeWinningNumbers(roundNumbers, referralWinnersNumber);
        setLotteryStatus(LotteryStatuses.ResultsEvaluated, _statusEndTime);
    }

    function markWinners(uint256 roundId, uint256 _statusEndTime) public onlyOwner {
        LotteryRoundInterface(rounds[roundId - 1]).markWinners(reader.evaluateWonTicketsForRound(roundId), reader.evaluateWonReferralForRound(roundId));
        setLotteryStatus(LotteryStatuses.ClaimInProgress, _statusEndTime);
    }

    function claimVictory() public {
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