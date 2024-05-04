// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { RoundVictoryTier, Round, Ticket, TicketResults, ReferralTicket, ReferralTicketResults } from "./LotteryCommon.sol";

interface LotteryRoundInterface {
    function getRound() external returns(Round memory);
    function previousRound() external returns(address);
    function markWinners(TicketResults[] memory ticketResults, ReferralTicketResults[] memory referralTicketResults) external;
    function markVictoryClaimed(uint256 ticketId, uint256 amountClaimed) external;
    function markReferralVictoryClaimed(uint256 referralTicketId, uint256 amountClaimed) external;
    function treasuryAmountOnTicket(uint256 paymentTokenAmount) external view returns (uint256);
    function updateVictoryPoolForTicket(uint256 paymentTokenAmount) external;
    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, address referral, address buyer) external;
    function closeRound() external;
    function couldReceiveWinningNumbers() external view;
    function storeWinningNumbers(uint16[] memory roundNumbers, uint16[] memory referralWinnersNumber) external;
    function ticketById(uint256 ticketId) external view returns (Ticket memory);
    function numbersForTicketId(uint256 ticketId) external view returns (uint16[] memory);
    function referralTicketById(uint256 index) external view returns (ReferralTicket memory);
    function victoryTierAmounts(RoundVictoryTier tier) external view returns (uint256);
    function winnersForEachTier(RoundVictoryTier tier) external returns(uint256);
    function setPoolPercentagesBasePoints(uint16[] memory _poolPercentagesBasePoints) external;
}