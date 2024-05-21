// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./LotteryRoundCreatorInterface.sol";
import "./LotteryRound.sol";

contract LotteryRoundCreator is LotteryRoundCreatorInterface, Ownable {
    constructor() Ownable(msg.sender) {}

    function startNewRound(uint256 roundDurationInSeconds, address previousRoundAddress, uint256 forcedUiIdForUpgrade) public override onlyOwner returns(address) {
        if (previousRoundAddress == address(0)) {
            LotteryRound newRound = new LotteryRound(address(0x07a67AaE7b84734Ac48658cb2d33251F7274820c), roundDurationInSeconds, 3);
            newRound.transferOwnership(owner());
            return address(newRound);
        } else {
            LotteryRound newRound = new LotteryRound(previousRoundAddress, roundDurationInSeconds, forcedUiIdForUpgrade);
            newRound.transferOwnership(owner());
            return address(newRound);
        }
    }
}