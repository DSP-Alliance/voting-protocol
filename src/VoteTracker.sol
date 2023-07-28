// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract VoteTracker {

    uint32 private voteStart;

    uint72 private yesVotes;

    uint256 private voteDetermination;
    uint32 private voteLength;

    uint96 private noVotes;
    mapping (address => bool) public hasVoted;

    uint80 private abstainVotes;

    constructor(uint32 length) {
        voteLength = length;
        voteStart = uint32(block.timestamp);
    }

    function castVote(uint256 vote) public {
        if (hasVoted[msg.sender]) {
            revert();
        }
        hasVoted[msg.sender] = true;

        uint vote_num = vote % 3;
        if (vote_num == 0) {
            addYesVote();
        } else if (vote_num == 1) {
            addNoVote();
        } else {
            addAbstainVote();
        }
    }

    function addYesVote() internal {
        yesVotes += 1;
    }
    function addNoVote() internal {
        noVotes += 1;
    }
    function addAbstainVote() internal {
        abstainVotes += 1;
    }

    function getVoteResults() public view returns (uint256, uint256, uint256) {
        if (uint32(block.timestamp) < voteStart + voteLength) {
            revert();
        }
        return (yesVotes, noVotes, abstainVotes);
    }
}
