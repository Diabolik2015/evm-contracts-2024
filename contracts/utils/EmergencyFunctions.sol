// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmergencyFunctions is Ownable {
    address teamAddress;
    constructor(address _teamAddress) Ownable(_teamAddress) {
        teamAddress = _teamAddress;
    }
    // Emergency Functions
    function sendTokenToTeam(address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount > 0) {
            IERC20(_token).transfer(teamAddress, amount);
        }
    }

    function sendCryptoToTeam() public onlyOwner {
        if (address(this).balance > 0) {
            payable(teamAddress).transfer(address(this).balance);
        }
    }

    /** @notice Check if an address is a contract */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
