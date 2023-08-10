// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "filecoin-solidity/MinerAPI.sol";
import "filecoin-solidity/PowerAPI.sol";
import "filecoin-solidity/PrecompilesAPI.sol";
import "filecoin-solidity/types/CommonTypes.sol";
import "filecoin-solidity/types/PowerTypes.sol";

contract VoteTracker {
    using CommonTypes for uint64;

    uint32 public voteStart;
    uint32 public voteLength;

    uint256 private yesVotes;
    uint256 private noVotes;
    uint256 private abstainVotes;

    mapping (bytes32 => bool) internal hasVoted;
    mapping (address => uint256) internal voterWeight;
    mapping (address => bool) internal registeredMiner;

    error AlreadyVoted();
    error NotRegistered();
    error AlreadyRegistered();
    error VoteNotConcluded();
    error VoteConcluded();

    modifier voting(address sender) {
        bytes32 senderHash = keccak256(abi.encodePacked(sender));
        if (hasVoted[senderHash]) {
            revert AlreadyVoted();
        }
        if (uint32(block.timestamp) > voteStart + voteLength) {
            revert VoteConcluded();
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

    /// @param miner The miner to register for
    /// @notice Msg sender must be a controlling address for the miner
    /// @notice If not registering for a miner, pass in address(0)
    function registerVoter(CommonTypes.FilActorId miner) public returns (uint256 power) {
        if (voterWeight[msg.sender] != 0) {
            revert AlreadyRegistered();
        }
        if (registeredMiner[miner]) {
            revert AlreadyRegistered();
        }

        power = voterPower(CommonTypes.FilActorId.unwrap(miner), msg.sender);
        voterWeight[msg.sender] = power;
        registeredMiner[miner] = true;
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

    function isMiner(uint64 minerId, address sender) internal view returns (bool) {
        if (minerId == 0) {
            return false;
        }
        bool controlling = MinerAPI.isControllingAddress(CommonTypes.FilActorId.wrap(minerId), toFilAddr(sender));
        return controlling;
    }

    function voterPower(uint64 minerId, address voter) internal view returns (uint256 power) {
        bool isminer = isMiner(minerId, voter);

        if (isminer) {
            // Vote weight as a miner
            PowerTypes.MinerRawPowerReturn memory pow = PowerAPI.minerRawPower(uint64(minerId));
            CommonTypes.BigInt memory p = pow.raw_byte_power;
            if (p.neg) {
                power = 10;
            } else {
                assembly {
                    power := mload(add(p, 32))
                }
            }
        } else {
            // Vote weight as a non-miner
            power = 10;
        }
    }

    function toFilAddr(address addr) internal view returns (CommonTypes.FilAddress memory) {
        uint64 actorid = PrecompilesAPI.resolveEthAddress(addr);
        bytes memory delg = PrecompilesAPI.lookupDelegatedAddress(actorid);
        CommonTypes.FilAddress memory filaddr = CommonTypes.FilAddress(delg);
        return filaddr;
    }
}
