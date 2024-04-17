// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface CyclixRandomizerInterface {
    function requestRandomWords(uint32 numWords) external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords);
    function registerGameContract(address gameAddress, string calldata name) external;
    function getLastRequestIdForCaller() external view returns (uint256);
}