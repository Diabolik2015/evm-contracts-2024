// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface LotteryRoundCreatorInterface {
   function startNewRound(uint256 roundDurationInSeconds, address previousRoundAddress, uint256 forcedUiIdForUpgrade) external returns(address);
}