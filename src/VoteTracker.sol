// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./interfaces/GlifFactory.sol";
import "./interfaces/ERC20.sol";

import "filecoin-solidity/MinerAPI.sol";
import "filecoin-solidity/PowerAPI.sol";
import "filecoin-solidity/types/CommonTypes.sol";
import "filecoin-solidity/types/PowerTypes.sol";

import "solmate/auth/Owned.sol";

contract VoteTracker is Owned {
    using CommonTypes for uint64;

    uint32 public voteStart;
    uint32 public voteLength;
    bool internal doubleYesOption;
    address immutable glifFactory;

    uint256 private yesVotes;
    uint256 private noVotes;
    uint256 private abstainVotes;

    uint256 private yesVoteOption2;

    address[] internal lsdTokens;

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

    constructor(uint32 length, bool _doubleYesOption, address _glifFactory, address[] memory _lsdTokens, address owner) Owned(owner) {
        doubleYesOption = _doubleYesOption;
        glifFactory = _glifFactory;
        voteLength = length;
        voteStart = uint32(block.timestamp);
        lsdTokens = _lsdTokens;
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

        bool glif = (GlifFactory(glifFactory).isAgent(glifpool) && Owned(glifpool).owner() == msg.sender);

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

    function voterPower(uint64 minerId, address voter) internal returns (uint256 power) {
        bool isminer = isMiner(minerId, voter);

        if (isminer) {
            // Vote weight as a miner
            PowerTypes.MinerRawPowerReturn memory pow = PowerAPI.minerRawPower(uint64(minerId));
            CommonTypes.BigInt memory p = pow.raw_byte_power;
            if (p.neg) {
                power = voter.balance / 1 ether;
            } else {
                bytes memory rpower = p.val;
                assembly {
                    // Length of the byte array
                    let length := mload(rpower)

                    // Load the bytes from the memory slot after the length
                    // Assuming power is > 32 bytes is okay because 1 PiB 
                    // is only 1e16
                    let _bytes := mload(add(rpower, 0x20))
                    let shift := mul(sub(0x40, mul(length, 2)), 0x04)

                    // bytes slot will be left aligned 
                    power := shr(shift, _bytes)
                }
            }
        } else {
            // 1 undenominated filecoin would be equal to 1,000 PiB raw byte power
            // Vote weight as a non-miner
            uint length = lsdTokens.length;
            for (uint i = 0; i < length; ) {
                ERC20 token = ERC20(lsdTokens[i]);
                // a users balance cannot exceed uint256 and realistically won't get close so power won't overflow
                unchecked {
                    power += token.balanceOf(voter) / 1 ether;
                    ++i;
                }
            }
            power += voter.balance / 1 ether;
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

    function addLSDToken(address token) public onlyOwner {
        lsdTokens.push(token);
    }
    function removeLSDToken(uint index) public onlyOwner {
        lsdTokens[index] = lsdTokens[lsdTokens.length - 1];
        lsdTokens.pop();
    }
}
