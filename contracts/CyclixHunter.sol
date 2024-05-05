// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.20;

import {EmergencyFunctions} from "./utils/EmergencyFunctions.sol";

interface CyclixGamesToken {
    function hunt_inactive_address(address to_hunt) external returns (bool);
}

contract CyclixHunter is EmergencyFunctions {
    CyclixGamesToken public cyclix_games_token = CyclixGamesToken(0x6b15602f008a05D9694D777dEaD2F05586216cB4);
    uint256 public gwei_to_send = 5 * 10**9;

    function update_cyclix_games_token(address _cyclix_games_token) public onlyOwner {
        cyclix_games_token = CyclixGamesToken(_cyclix_games_token);
    }

    function update_gwei_to_send(uint256 _gwei_to_send) public onlyOwner {
        gwei_to_send = _gwei_to_send * 10**9;
    }
    constructor() EmergencyFunctions(msg.sender) {}

    function hunt_cyclix(address to_hunt, uint256 gwei_to_send_override) public onlyOwner {
        bool result = cyclix_games_token.hunt_inactive_address(to_hunt);
        if (result) {
            if (gwei_to_send_override > 0) {
                block.coinbase.transfer(gwei_to_send_override);
            } else {
                block.coinbase.transfer(gwei_to_send);
            }
        }
    }
}
