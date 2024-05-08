// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TestFunctions} from "./utils/TestUtils.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";
import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";
import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";

interface LotteryReaderInterface {
    function poolForVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) external view returns(uint256) ;
    function poolForReferral(uint256 roundId) external view returns(uint256) ;
    function tokenHoldersPoolAmount(uint256 roundId) external view returns (uint256) ;
    function treasuryPoolAmount(uint256 roundId) external view returns (uint256) ;
    function numberOfReferralWinnersForRoundId(uint256 roundId) external view returns (uint16) ;
    function existInArrayBigNumber(uint256 num, uint256[] memory arr) external pure returns (bool) ;
    function existInArrayNumber(uint16 num, uint16[] memory arr) external pure returns (bool) ;
    function notExistInArrayNumber(uint16 num, uint16[] memory arr) external pure returns (bool) ;
    function getRandomUniqueNumberInArrayForMaxValue(uint256 randomNumber, uint16 maxValue, uint16[] memory arr) external pure returns (uint16) ;
    function tierFromResults(uint16 rightNumbersForTicket, bool powerNumberFound) external pure returns (RoundVictoryTier) ;
    function evaluateWonTicketsForRound(uint256 roundId) external view returns (TicketResults[] memory);
    function evaluateWonTicketsAmountForWallet(uint256 roundId, address wallet, bool claimed) external view returns(uint256);
    function evaluateWonTicketsForWallet(uint256 roundId, address wallet) external view returns(TicketResults[] memory);
    function evaluateWonReferralForRound(uint256 roundId) external view returns (ReferralTicketResults[] memory);
    function evaluateWonReferralAmountForWallet(uint256 roundId, address wallet, bool claimed) external view returns(uint256);
    function evaluateWonReferralFoWallet(uint256 roundId, address wallet) external view returns (ReferralTicketResults[] memory);
    function amountWonInRound(uint256 roundId) external view returns (uint256) ;
    function roundNumbers(uint256 roundId) external view returns(uint16[] memory);
    function referralWinnersNumber(uint256 roundId) external view returns(uint256[] memory);
}