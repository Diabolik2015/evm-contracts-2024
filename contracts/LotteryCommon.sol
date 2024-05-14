// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

    enum RoundVictoryTier {
        Tier5_1,
        Tier5,
        Tier4_1,
        Tier4,
        Tier3_1,
        Tier3,
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
        uint256[] referralWinnersNumber;
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
    }

    struct TicketResults {
        uint256 ticketId;
        address participantAddress;
        RoundVictoryTier victoryTier;
        bool won;
        bool claimed;
        uint256 amountWon;
    }

    struct ReferralTicket {
        uint256 id;
        address buyerAddress;
        address referralAddress;
        uint256 referralTicketNumber;
        bool winner;
        bool claimed;
    }

    struct ReferralTicketResults {
        uint256 referralTicketId;
        address buyerAddress;
        address referralAddress;
        uint256 referralTicketNumber;
        bool won;
        bool claimed;
        uint256 amountWon;
    }