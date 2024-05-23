// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./LotteryRoundCreatorInterface.sol";
import "./LotteryRound.sol";

contract LotteryRoundCreator is LotteryRoundCreatorInterface, Ownable {
    bool public isContractsUpgrade;
    constructor(bool _isContractsUpgrade) Ownable(msg.sender) {
        isContractsUpgrade = _isContractsUpgrade;
    }

    function startNewRound(uint256 roundDurationInSeconds, address previousRoundAddress, uint256 forcedUiIdForUpgrade) public override onlyOwner returns(address) {
        if (previousRoundAddress == address(0) && isContractsUpgrade) {
            LotteryRound newRound = new LotteryRound(address(0xAC9F3eA5FC297D0648ea1b9b0c7446E28fE12867), roundDurationInSeconds, 3);
            newRound.transferOwnership(owner());
            return address(newRound);
        } else {
            LotteryRound newRound = new LotteryRound(previousRoundAddress, roundDurationInSeconds, forcedUiIdForUpgrade);
            newRound.transferOwnership(owner());
            return address(newRound);
        }
    }
}