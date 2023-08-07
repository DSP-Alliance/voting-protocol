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

    error AlreadyVoted();
    error NotRegistered();
    error AlreadyRegistered();
    error VoteNotConcluded();

    modifier voting(address sender) {
        bytes32 senderHash = keccak256(abi.encodePacked(sender));
        if (hasVoted[senderHash]) {
            revert AlreadyVoted();
        }
        _;
        hasVoted[senderHash] = true;
    }

    modifier isRegistered(address sender) {
        if (voterWeight[sender] == 0) {
            revert NotRegistered();
        }
        _;
    }

    constructor(uint32 length) {
        voteLength = length;
        voteStart = uint32(block.timestamp);
    }

    /******************************************************************/
    /*                        Public Functions                        */
    /******************************************************************/

    function castVote(uint256 vote) public voting(msg.sender) isRegistered(msg.sender) {
        uint vote_num = vote % 3;
        uint weight = voterWeight[msg.sender];
        if (vote_num == 0) {
            addYesVote(weight);
        } else if (vote_num == 1) {
            addNoVote(weight);
        } else {
            addAbstainVote(weight);
        }
    }

    function registerVoter() public returns (uint256 power) {
        if (voterWeight[msg.sender] != 0) {
            revert AlreadyRegistered();
        }

        power = voterPower(msg.sender);
        voterWeight[msg.sender] = power;
    }

    function getVoteResults() public view returns (uint256, uint256, uint256) {
        if (uint32(block.timestamp) < voteStart + voteLength) {
            revert VoteNotConcluded();
        }
        return (yesVotes, noVotes, abstainVotes);
    }

    /******************************************************************/
    /*                          Vote Adding                           */
    /******************************************************************/

    function addYesVote(uint256 weight) internal {
        yesVotes += weight;
    }
    function addNoVote(uint256 weight) internal {
        noVotes += weight;
    }
    function addAbstainVote(uint256 weight) internal {
        abstainVotes += weight;
    }

    /******************************************************************/
    /*                       Miner Verification                       */
    /******************************************************************/

    /// TODO: Implement valid miner determination
    function isMiner(address sender) internal pure returns (bool) {
        if (sender == address(0)) {
            return false;
        }
        return true;
    }

    /// TODO: Implement this function
    function voterPower(address voter) internal pure returns (uint256 power) {
        if (voter == address(0)) {
            return 0;
        }
        bool miner = isMiner(voter);

        // TODO: Implement precise weight calculation
        if (miner) {
            // Vote weight as a miner
            power = 10;
        } else {
            // Vote weight as a non-miner
            power = 1;
        }
    }
}
