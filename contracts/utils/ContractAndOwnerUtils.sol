// SPDX-License-Identifier: MIT
pragma solidity >=0.8.x <0.9.0;

contract ContractAndOwnerUtils {
    address _creatorContract;
    address _owner;
    constructor(address _c, address _o) {
        _creatorContract = _c;
        _owner = _o;
    }

    modifier onlyCreatorContractOrOwner() {
        require(_owner == msg.sender || _creatorContract == msg.sender, "Only owner or creator contract can call this function");
        _;
    }

    modifier onlyCreatorContract() {
        require(_creatorContract == msg.sender, "CreatorContractNotCalling: caller is not the creator contract");
        _;
    }

    modifier onlyFromOwner() {
        require(_owner == msg.sender, "OwnerNotCalling: caller is not the owner");
        _;
    }

    function updateOwner(address _newOwner) public onlyFromOwner {
        _owner = _newOwner;
    }

    function updateCreatorContract(address _newCreatorContract) public onlyCreatorContractOrOwner {
        _creatorContract = _newCreatorContract;
    }
}
