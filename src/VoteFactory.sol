// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./VoteTracker.sol";
import "./VoteTracker2.sol";
import "solmate/auth/Owned.sol";

contract VoteFactory is Owned {
    mapping (uint64 => address) public FIPnumToAddress;
    address[] public deployedVotes;

    event VoteStarted(address vote, uint64 fipNum, uint32 length);

    constructor() Owned(msg.sender) {}

    function startVote(uint32 length, uint64 fipNum, bool doubleYesOption) public onlyOwner returns (address vote) {
        require(FIPnumToAddress[fipNum] == address(0), "Vote already exists for this FIP");

        bytes memory bytecode;
        if (doubleYesOption) {
            bytecode = type(VoteTrackerDoubleYes).creationCode;
        } else {
            bytecode = type(VoteTracker).creationCode;
        }
        bytes32 salt = keccak256(abi.encodePacked(fipNum, length));
        assembly {
            vote := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        FIPnumToAddress[fipNum] = vote;
        deployedVotes.push(vote);
    }
}