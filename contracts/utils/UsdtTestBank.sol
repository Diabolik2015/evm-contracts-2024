// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UsdtTestBank  {
    address public usdtAddress;
    constructor(address _usdt) {
        usdtAddress = _usdt;
    }

    function getOneHundredDollars() public {
        SafeERC20.safeTransfer(IERC20(usdtAddress), msg.sender, 100 * 10 ** 18);
    }
    function getOneThousandsDollars() public {
        SafeERC20.safeTransfer(IERC20(usdtAddress), msg.sender, 1000 * 10 ** 18);
    }
}