// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EmergencyFunctions is Ownable {
    address internal teamAddress;
    constructor(address _teamAddress) Ownable(_teamAddress) {
        teamAddress = _teamAddress;
    }

    function updateTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }

    // Emergency Functions
    function sendTokenToTeam(address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount > 0) {
            SafeERC20.safeTransfer(IERC20(_token), teamAddress, amount);
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
