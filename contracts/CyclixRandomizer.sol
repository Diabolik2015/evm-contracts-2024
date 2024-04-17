// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {CyclixRandomizerInterface} from "./CyclixRandomizerInterface.sol";

contract CyclixRandomizer is CyclixRandomizerInterface, VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords, address requestor);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(address => bool) public gameContractAdded;
    mapping(address => bool) public gameContractActive;
    mapping(address => string) public gameContractName;
    mapping(address => uint256) public gameContractRequestsCount;
    mapping(address => uint256[]) public gameContractRequests;
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimitForOneWord = 34000;
    function setCallbackGasLimitForOneWord(uint32 newGas) external onlyOwner {
        callbackGasLimitForOneWord = newGas;
    }
    uint16 requestConfirmations = 3;

    constructor(uint64 subscriptionId, bytes32 _keyHash, address coordinatorAddress)
    VRFConsumerBaseV2(coordinatorAddress)
    ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(coordinatorAddress);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
    }

    function registerGameContract(address gameAddress, string calldata name) public {
        require(tx.origin == owner(), "Only owner can register game contract");
        require(gameContractAdded[gameAddress] == false, "Game contracts will remain for verifications" );
        gameContractAdded[gameAddress] = true;
        gameContractActive[gameAddress] = true;
        gameContractName[gameAddress] = name;
    }

    function setGameContractStatus(address gameAddress, bool status) external onlyOwner {
        gameContractActive[gameAddress] = status;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint32 numWords) public returns (uint256 requestId)
    {
        require(msg.sender == owner() || gameContractAdded[msg.sender], "Only Owner and Game can request random number");
        uint32 callbackGasLimit = callbackGasLimitForOneWord;

        requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId,
            requestConfirmations, callbackGasLimit * numWords, numWords);

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        gameContractRequests[msg.sender].push(requestId);
        gameContractRequestsCount[msg.sender]++;
        emit RequestSent(requestId, numWords, msg.sender);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getLastRequestIdForCaller() public view returns (uint256) {
        return gameContractRequests[msg.sender][gameContractRequestsCount[msg.sender] - 1];
    }

    function getRequestStatus(
        uint256 _requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}