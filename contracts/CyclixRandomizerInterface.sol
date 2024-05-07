// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface CyclixRandomizerInterface {
    function requestRandomWords(uint32 numWords) external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords);
    function registerGameContract(address gameAddress, string calldata name) external;
    function getLastRequestIdForCaller(address _gameAddress) external view returns (uint256);
    function recoverLostNumberRequest(uint256 _requestId) external returns (uint256);
}