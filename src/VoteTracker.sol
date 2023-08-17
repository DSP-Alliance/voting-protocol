// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./interfaces/GlifFactory.sol";

import "filecoin-solidity/MinerAPI.sol";
import "filecoin-solidity/PowerAPI.sol";
import "filecoin-solidity/types/CommonTypes.sol";
import "filecoin-solidity/types/PowerTypes.sol";

contract VoteTracker {
    using CommonTypes for uint64;

    uint32 public voteStart;
    uint32 public voteLength;
    bool internal doubleYesOption;
    address immutable glifFactory;

    uint256 private yesVotes;
    uint256 private noVotes;
    uint256 private abstainVotes;

    uint256 private yesVoteOption2;

    mapping (bytes32 => bool) internal hasVoted;
    mapping (address => uint256) internal voterWeight;
    mapping (uint64 => bool) internal registeredMiner;

    event VoteCast(address voter, uint256 weight, uint256 vote);
    event VoterRegistered(address voter, uint64[] minerIds, uint256 weight);

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

    constructor(uint32 length, bool _doubleYesOption, address _glifFactory) {
        doubleYesOption = _doubleYesOption;
        glifFactory = _glifFactory;
        voteLength = length;
        voteStart = uint32(block.timestamp);
    }

    /******************************************************************/
    /*                        Public Functions                        */
    /******************************************************************/

    function voteAndRegister(uint256 vote, address glifPool, uint64[] calldata minerIds) public returns (uint256 voteWeight) {
        voteWeight = registerVoter(glifPool, minerIds);
        castVote(vote);
    }

    function castVote(uint256 vote) public voting(msg.sender) isRegistered(msg.sender) {
        uint vote_num = vote % 3;
        uint weight = voterWeight[msg.sender];
        if (vote_num == 0) {
            if (doubleYesOption) {
                yesChoice(vote, weight);
            } else {
                yesVotes += weight;
            }
        } else if (vote_num == 1) {
            noVotes += weight;
        } else {
            abstainVotes += weight;
        }

        emit VoteCast(msg.sender, weight, vote_num);
    }

    /// @param minerIds The miner to register for
    /// @notice Msg sender must be a controlling address for the miner
    /// @notice If not registering for a miner, pass in address(0)
    function registerVoter(address glifpool, uint64[] calldata minerIds) public returns (uint256 power) {
        if (voterWeight[msg.sender] != 0) {
            revert AlreadyRegistered();
        }

        if (minerIds.length == 0) {
            power = msg.sender.balance;

            emit VoterRegistered(msg.sender, minerIds, power);

            voterWeight[msg.sender] = power;
            return power;
        }

        bool glif = (glifpool != address(0) && GlifFactory(glifFactory).isAgent(glifpool));

        for (uint i = 0; i < minerIds.length; ++i) {
            uint64 minerId = minerIds[i];

            if (registeredMiner[minerId]) {
                continue;
            }

            if (glif) {
                power += voterPower(minerId, glifpool);
            } else {
                power += voterPower(minerId, msg.sender);
            }
            registeredMiner[minerId] = true;
        }

        emit VoterRegistered(msg.sender, minerIds, power);

        voterWeight[msg.sender] = power;
    }

    function getVoteResults() public view returns (uint256, uint256, uint256, uint256) {
        if (uint32(block.timestamp) < voteStart + voteLength) {
            revert VoteNotConcluded();
        }
        if (doubleYesOption) {
            return (yesVotes, yesVoteOption2, noVotes, abstainVotes);
        } else {
            return (yesVotes, 0, noVotes, abstainVotes);
        }
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
                // TODO: Cast bytes to uint256 correctly
                assembly {
                    power := mload(add(p, 32))
                }
            }
        } else {
            // TODO: Fetch user balance as weight;
            // Vote weight as a non-miner
            power = 10;
        }
    }

    function toFilAddr(address addr) internal pure returns (CommonTypes.FilAddress memory filAddr) {
        bytes memory delegatedAddr = abi.encodePacked(hex"040a", addr);
        filAddr = CommonTypes.FilAddress(delegatedAddr);
    }

    /// @notice If this vote has two yes options then this function will put it in the correct category
    /// @notice This function should only be called if the vote param modulo 3 == 0
    function yesChoice(uint256 vote, uint256 weight) internal {
        uint option = vote % 6;
        // Option should only result in 0 or 3
        if (option >= 3) {
            yesVoteOption2 += weight;
        } else {
            yesVotes += weight;
        }
    }
}
