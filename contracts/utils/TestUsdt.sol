// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUsdt is ERC20 {
    constructor(uint256 initialSupply) ERC20("Tether Usdt", "USDT") {
        _mint(msg.sender, 10 ** 6 * (10 ** uint256(decimals())));
    }
}