// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface LotteryRoundCreatorInterface {
   function startNewRound(uint256 _statusStartTime, uint256 _statusEndTime, address previousRoundAddress, uint256 id, uint256 uiId) external returns(address);
}