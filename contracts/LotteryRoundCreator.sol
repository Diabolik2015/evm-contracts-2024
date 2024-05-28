// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./LotteryRoundCreatorInterface.sol";
import "./LotteryRound.sol";

contract LotteryRoundCreator is LotteryRoundCreatorInterface, Ownable {
    constructor() Ownable(msg.sender) {}

    function startNewRound(uint256 roundDurationInSeconds, address previousRoundAddress, uint256 id, uint256 uiId) public override onlyOwner returns(address) {
        LotteryRound newRound = new LotteryRound(previousRoundAddress, roundDurationInSeconds, id, uiId);
        newRound.transferOwnership(owner());
        return address(newRound);
    }
}