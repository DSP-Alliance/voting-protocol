// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./VoteTracker.sol";
import "solmate/auth/Owned.sol";

contract VoteFactory is Owned {
    address immutable glifFactory;

    address[] public deployedVotes;

    mapping (uint64 => address) public FIPnumToAddress;

    event VoteStarted(address vote, uint64 fipNum, uint32 length);

    constructor(address _glifFactory) Owned(msg.sender) {
        glifFactory = _glifFactory;
    }

    function startVote(uint32 length, uint64 fipNum, bool doubleYesOption, address[] memory lsdTokens) public onlyOwner returns (address vote) {
        require(FIPnumToAddress[fipNum] == address(0), "Vote already exists for this FIP");

        vote = address(new VoteTracker(length, doubleYesOption, glifFactory, lsdTokens, owner));

        emit VoteStarted(vote, fipNum, length);
        FIPnumToAddress[fipNum] = vote;
        deployedVotes.push(vote);
    }
}