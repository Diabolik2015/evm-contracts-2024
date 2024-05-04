// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

    enum RoundVictoryTier {
        NO_WIN,
        Tier5_1,
        Tier5,
        Tier4_1,
        Tier4,
        Tier3_1,
        Tier3,
        Referrer,
        PublicPool,
        TokenHolders,
        Treasury
    }

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        bool ended;
        uint16[] roundNumbers;
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