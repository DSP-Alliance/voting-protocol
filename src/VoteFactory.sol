// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./VoteTracker.sol";

contract VoteFactory {
    mapping (uint64 => address) public FIPnumToAddress;
    address[] public deployedVotes;

    event VoteStarted(address vote, uint64 fipNum, uint32 length);

    function startVote(uint32 length, uint64 fipNum) public returns (address vote) {
        require(FIPnumToAddress[fipNum] == address(0), "Vote already exists for this FIP");

        bytes memory bytecode = type(VoteTracker).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(fipNum, length));
        assembly {
            vote := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        FIPnumToAddress[fipNum] = vote;
        deployedVotes.push(vote);
    }
}