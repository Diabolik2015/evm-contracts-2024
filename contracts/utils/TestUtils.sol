// SPDX-License-Identifier: MIT
pragma solidity >=0.8.x <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Extension {
    function decimals() external view returns (uint8);
}

contract TestFunctions is Ownable {
    constructor() Ownable(msg.sender) {}
    //Used for mock testing, contract ownership will be renounced on release
    uint public currentTimestampOverride;
    function updateCurrentTimestampOverride(uint _v) external onlyOwner {
        currentTimestampOverride = _v;
    }
    function currentTimestamp() public view returns(uint) {
        if (currentTimestampOverride > 0) {
            return currentTimestampOverride;
        }
        return block.timestamp;
    }
}
