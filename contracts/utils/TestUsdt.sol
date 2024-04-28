// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUsdt is ERC20 {
    constructor() ERC20("Lottery Tether Usdt", "LUSDT") {
        _mint(msg.sender, 10 ** 9 * (10 ** uint256(decimals())));
    }
}