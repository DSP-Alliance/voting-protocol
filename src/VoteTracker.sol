// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract VoteTracker {

    uint32 private voteStart;
    uint32 private voteLength;

    uint256 private yesVotes;
    uint256 private noVotes;
    uint256 private abstainVotes;

    mapping (bytes32 => bool) internal hasVoted;
    mapping (address => uint256) internal voterWeight;

    // TODO: Add custom error messages for each revert

    modifier voting(address sender) {
        bytes32 senderHash = keccak256(abi.encodePacked(sender));
        if (hasVoted[senderHash]) {
            revert();
        }
        _;
        hasVoted[senderHash] = true;
    }

    modifier isRegistered(address sender) {
        if (voterWeight[sender] == 0) {
            revert();
        }
        _;
    }

    constructor(uint32 length) {
        voteLength = length;
        voteStart = uint32(block.timestamp);
    }

    function castVote(uint256 vote) public voting(msg.sender) isRegistered(msg.sender) {
        uint vote_num = vote % 3;
        if (vote_num == 0) {
            addYesVote(msg.sender);
        } else if (vote_num == 1) {
            addNoVote(msg.sender);
        } else {
            addAbstainVote(msg.sender);
        }
    }

    function registerVoter() public returns (uint256 power) {
        bool miner = isMiner(msg.sender);
        if (miner) {
            power = minerPower(msg.sender);
        } else {
            power = 1;
        }
        voterWeight[msg.sender] = power;
    }

    function addYesVote(address voter) internal {
        uint weight = voterWeight[voter];
        yesVotes += weight;
    }
    function addNoVote(address voter) internal {
        uint weight = voterWeight[voter];
        noVotes += weight;
    }
    function addAbstainVote(address voter) internal {
        uint weight = voterWeight[voter];
        abstainVotes += weight;
    }


    /// TODO: Implement this function
    function isMiner(address sender) internal pure returns (bool) {
        if (sender == address(0)) {
            return false;
        }
        return true;
    }

    /// TODO: Implement this function
    function minerPower(address miner) internal pure returns (uint256) {
        if (miner == address(0)) {
            return 0;
        }
        return 10;
    }

    function getVoteResults() public view returns (uint256, uint256, uint256) {
        if (uint32(block.timestamp) < voteStart + voteLength) {
            revert();
        }
        return (yesVotes, noVotes, abstainVotes);
    }
}
