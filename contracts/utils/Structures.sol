// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract WithDynamicAddressArray {
    address[] public dynamicAddresses;
    mapping(address => uint256) public dynAddressesPositions;
    uint256 public addressesLength;

    constructor() {
        dynamicAddresses.push(address(0));
    }

    function addDynamicAddress(address _a) internal {
        if (dynAddressesPositions[_a] == 0) {
            dynamicAddresses.push(_a);
            addressesLength += 1;
            dynAddressesPositions[_a] = addressesLength;
        }
    }

    function removeDynamicAddress(address _a) internal {
        if (dynAddressesPositions[_a] > 0) {
            uint256 toUsePosition = dynAddressesPositions[_a];
            dynAddressesPositions[_a] = 0;
            if (toUsePosition < addressesLength) {
                address lastAddress = dynamicAddresses[addressesLength];
                dynamicAddresses[toUsePosition] = lastAddress;
                dynAddressesPositions[lastAddress] = toUsePosition;
            }
            dynamicAddresses.pop();
            addressesLength -= 1;
        }
    }
}
