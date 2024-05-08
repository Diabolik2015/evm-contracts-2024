// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.20;

import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";

interface CyclixGamesToken {
    function hunt_inactive_address(address to_hunt) external returns (bool);
    function lastTXtime(address _address) external view returns (uint256);
    function lastHunted_TXtime(address _address) external view returns (uint256);
    function huntingRate() external view returns (uint256);
    function huntingPct() external view returns (uint256);
    function balanceOf(address _address) external view returns (uint256);
}

contract CyclixHunter is EmergencyFunctions {
    CyclixGamesToken public cyclix_games_token = CyclixGamesToken(0x6b15602f008a05D9694D777dEaD2F05586216cB4);

    constructor() EmergencyFunctions(msg.sender) {}

    function hunt_cyclix(address to_hunt, uint256 gwei_to_send_override) public onlyOwner {
        bool result = cyclix_games_token.hunt_inactive_address(to_hunt);
        if (result) {
            block.coinbase.transfer(gwei_to_send_override);
        }
    }

    function getInactiveBalanceAtRisk(address _address, uint256 timestamp_after_huntable) public view returns (uint256 inactive_bal) {
        inactive_bal = 0;

        uint256 weeksSinceLastActivity = (timestamp_after_huntable - cyclix_games_token.lastTXtime(_address)) / cyclix_games_token.huntingRate();
        uint256 weeksSinceLastHunted = (timestamp_after_huntable - cyclix_games_token.lastHunted_TXtime(_address)) / cyclix_games_token.huntingRate();
        uint256 pctAtRiskSinceLastActivity = weeksSinceLastActivity * cyclix_games_token.huntingPct();
        uint256 pctAtRiskSinceLastHunted = weeksSinceLastHunted * cyclix_games_token.huntingPct();
        uint256 lastactivitylasthunted = pctAtRiskSinceLastActivity - pctAtRiskSinceLastHunted;

        if (pctAtRiskSinceLastHunted >= 1000 ){
            return (inactive_bal = cyclix_games_token.balanceOf(_address));
        }

        if (weeksSinceLastHunted <= 0){
            inactive_bal = 0;
        }

        else if (weeksSinceLastHunted == weeksSinceLastActivity ){
            uint256 originalBalance = cyclix_games_token.balanceOf(_address);
            inactive_bal = (pctAtRiskSinceLastActivity) * originalBalance / 1000;
            inactive_bal = (inactive_bal > cyclix_games_token.balanceOf(_address)) ? cyclix_games_token.balanceOf(_address) : inactive_bal;
        }
        else {

            uint256 originalBalance = cyclix_games_token.balanceOf(_address) * 1000 / (1000- (lastactivitylasthunted));
            inactive_bal = (pctAtRiskSinceLastHunted) * originalBalance / 1000;
            inactive_bal = (inactive_bal > cyclix_games_token.balanceOf(_address)) ? cyclix_games_token.balanceOf(_address) : inactive_bal;
        }

        return inactive_bal;
    }
}