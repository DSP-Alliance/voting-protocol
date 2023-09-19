// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./interfaces/GlifFactory.sol";
import "./interfaces/ERC20.sol";

import "shim/MinerAPI.sol";
import "shim/PowerAPI.sol";
import "filecoin-solidity/types/CommonTypes.sol";
import "filecoin-solidity/types/PowerTypes.sol";

import "solmate/auth/Owned.sol";

contract VoteTracker is Owned {
    using CommonTypes for uint64;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Public Storage                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint32 public voteStart;
    uint32 public voteLength;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Internal Storage                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    bool internal doubleYesOption;
    address immutable glifFactory;
    uint64 immutable FIP;

    // Note: Tallies are initialized at 1 to save gas and keep warm storage

    // Raw Byte Power Tallies
    uint256 private yesVotesRBP = 1;
    uint256 private yesVoteOption2RBP = 1;
    uint256 private noVotesRBP = 1;
    uint256 private abstainVotesRBP = 1;

    // Miner Token Tally
    uint256 private yesVotesMinerToken = 1;
    uint256 private yesVoteOption2MinerToken = 1;
    uint256 private noVotesMinerToken = 1;
    uint256 private abstainVotesMinerToken = 1;

    // Token Tallies
    uint256 private yesVotesToken = 1;
    uint256 private yesVoteOption2Token = 1;
    uint256 private noVotesToken = 1;
    uint256 private abstainVotesToken = 1;

    address[] internal lsdTokens;

    mapping(address => uint256) internal voterWeightRBP;
    mapping(address => uint256) internal voterWeightMinerToken;
    mapping(address => uint256) internal voterWeightToken;
    mapping(address => bool) internal hasVoted;
    mapping(uint64 => bool) internal registeredMiner;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Events                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event VoteCast(
        address voter,
        uint256 weightRBP,
        uint256 weightToken,
        uint256 vote
    );
    event VoterRegistered(
        address voter,
        uint64[] minerIds,
        uint256 weightRBP,
        uint256 weightToken
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Errors                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error AlreadyVoted();
    error NotRegistered();
    error AlreadyRegistered();
    error VoteNotConcluded();
    error VoteConcluded();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Errors                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    enum Vote {
        Yes,
        Yes2,
        No,
        Abstain
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Modifiers                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Checks if the vote has concluded and if the user has already voted
    /// @param sender The address to check
    modifier voting(address sender) {
        if (hasVoted[sender]) {
            revert AlreadyVoted();
        }
        if (uint32(block.timestamp) > voteStart + voteLength) {
            revert VoteConcluded();
        }
        _;
        hasVoted[sender] = true;
    }

    /// @notice Checks if the sender is a registered voter
    /// @param sender The address to check
    modifier isRegistered(address sender) {
        if (voterWeightRBP[sender] == 0 || voterWeightToken[sender] == 0) {
            revert NotRegistered();
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         Constructor                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @param length The length of the vote in seconds
    /// @param _doubleYesOption If true, the vote will have two yes options
    /// @param _glifFactory The address of the glif factory
    /// @param _lsdTokens The addresses of the LSD tokens to count as voting power
    /// @param owner The owner of the vote
    constructor(
        uint32 length,
        bool _doubleYesOption,
        address _glifFactory,
        address[] memory _lsdTokens,
        uint64 _FIP,
        address owner
    ) Owned(owner) {
        doubleYesOption = _doubleYesOption;
        glifFactory = _glifFactory;
        FIP = _FIP;
        voteLength = length;
        voteStart = uint32(block.timestamp);
        lsdTokens = _lsdTokens;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Public Functions                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice A combination function of `castVote` and `registerVoter`
    /// @notice If not registering for a glif pool, pass in address(0)
    /// @notice If don't have any minerId's pass in an empty list
    /// @param vote The vote to cast
    /// @param glifPool The address of the glifpool to register for, address(0) if not using glif pools
    /// @param minerIds The miner IDs to register for
    /// @return voteWeightRBP The voting power of the voter in Raw Byte Power
    /// @return voteWeightToken The voting power of the voter in FIL and LSD's
    function voteAndRegister(
        uint256 vote,
        address glifPool,
        uint64[] calldata minerIds
    ) public returns (uint256 voteWeightRBP, uint256 voteWeightToken) {
        (voteWeightRBP, voteWeightToken) = registerVoter(glifPool, minerIds);
        castVote(vote);
    }

    /// @notice Msg sender must be a registered voter
    /// @param vote The vote to cast
    function castVote(
        uint256 vote
    ) public voting(msg.sender) isRegistered(msg.sender) {
        uint vote_num = vote % 3;
        uint weightRBP = voterWeightRBP[msg.sender];
        uint weightMinerToken = voterWeightMinerToken[msg.sender];
        uint weightToken = voterWeightToken[msg.sender];

        // YES VOTE
        if (vote_num == 0) {
            if (doubleYesOption) {
                yesChoice(vote, weightRBP, weightMinerToken, weightToken);
            } else {
                yesVotesRBP += weightRBP;
                yesVotesToken += weightToken;
            }

            // NO VOTE
        } else if (vote_num == 1) {
            noVotesRBP += weightRBP;
            noVotesMinerToken += weightMinerToken;
            noVotesToken += weightToken;

            // ABSTAIN VOTE
        } else {
            abstainVotesRBP += weightRBP;
            abstainVotesMinerToken += weightMinerToken;
            abstainVotesToken += weightToken;
        }

        emit VoteCast(msg.sender, weightRBP, weightToken, vote_num);
    }

    /// @notice Msg sender must be a controlling address for the miner
    /// @notice If not registering for a miner, pass in address(0)
    /// @param minerIds The miner IDs to register for
    /// @param glifpool The address of the glifpool to register for, address(0) if not using glif pools
    /// @return powerRBP The voting power in Raw Byte Power of the voter
    /// @return powerToken The voting power in FIL and LSD's of the voter
    function registerVoter(
        address glifpool,
        uint64[] calldata minerIds
    ) public returns (uint256 powerRBP, uint256 powerToken) {
        // Do not let user register twice
        if (
            voterWeightRBP[msg.sender] > 0 || voterWeightToken[msg.sender] > 0
        ) {
            revert AlreadyRegistered();
        }

        // Determine if glifpool is valid
        bool glif = (GlifFactory(glifFactory).isAgent(glifpool) &&
            Owned(glifpool).owner() == msg.sender);

        // Collect RBP voting weight
        uint length = minerIds.length;
        for (uint i = 0; i < minerIds.length; ++i) {
            uint64 minerId = minerIds[i];

            if (registeredMiner[minerId]) {
                continue;
            }

            // Add their RBP voting weight
            address minerOwner = glif ? glifpool : msg.sender;

            // Set the RBP voting weight
            powerRBP += voterRBP(minerId, minerOwner);

            registeredMiner[minerId] = true;
        }

        // Collect FIL voting weight
        powerToken += msg.sender.balance;

        // Collect LSD voting weight
        length = lsdTokens.length;
        for (uint i = 0; i < length; ++i) {
            ERC20 token = ERC20(lsdTokens[i]);

            uint balance = token.balanceOf(msg.sender);

            powerToken += balance;
        }

        // Finalize state changes
        emit VoterRegistered(msg.sender, minerIds, powerRBP, powerToken);

        voterWeightRBP[msg.sender] = powerRBP;

        // If they have RBP then assign their token power to the miner's
        if (powerRBP > 0) {
            voterWeightMinerToken[msg.sender] = powerToken;

            // If they have no RBP then assign to normal token category
        } else {
            voterWeightToken[msg.sender] = powerToken;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       View Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function winningVote() public view returns (Vote) {
        Vote rbp;
        // Braces are used here to prevent stack too deep errors
        {
            (
                uint yesRBP,
                uint yes2RBP,
                uint noRBP,
                uint abstainRBP
            ) = getVoteResultsRBP();
            if (yesRBP > noRBP && yesRBP > abstainRBP) {
                // Win for yes RBP
                if (doubleYesOption && yes2RBP > yesRBP) {
                    rbp = Vote.Yes2;
                } else {
                    rbp = Vote.Yes;
                }
            } else if (noRBP > abstainRBP) {
                // Win for no RBP
                rbp = Vote.No;
            } else {
                // Win for abstain RBP
                rbp = Vote.Abstain;
            }
        }

        (
            uint yesMinerToken,
            uint yes2MinerToken,
            uint noMinerToken,
            uint abstainMinerToken
        ) = getVoteResultsMinerToken();
        (
            uint yesToken,
            uint yes2Token,
            uint noToken,
            uint abstainToken
        ) = getVoteResultsToken();

        Vote token;
        // Braces are used here to prevent stack too deep errors
        {
            uint yesTokenVotes = yesToken + yesMinerToken;
            uint noTokenVotes = noToken + noMinerToken;
            uint abstainTokenVotes = abstainToken + abstainMinerToken;
            uint yes2TokenVotes = yes2Token + yes2MinerToken;
            if (
                yesTokenVotes > noTokenVotes &&
                yesTokenVotes > abstainTokenVotes
            ) {
                // Win for yes Miner Token
                if (doubleYesOption && yes2MinerToken > yesTokenVotes) {
                    token = Vote.Yes2;
                } else {
                    token = Vote.Yes;
                }
            } else if (noTokenVotes > abstainTokenVotes) {
                // Win for no Miner Token
                token = Vote.No;
            } else {
                // Win for abstain Miner Token
                token = Vote.Abstain;
            }
        }

        if (rbp == token) {
            return rbp;
        } else {
            return Vote.No;
        }
    }

    /// @notice Returns the vote results
    /// @notice Will not return results if the vote is still in progress
    /// @return yesVotesRBP The number of yes votes
    /// @return yesVoteOption2RBP The number of yes votes for the second option, 0 if there is no second option
    /// @return noVotesRBP The number of no votes
    /// @return abstainVotesRBP The number of abstain votes
    function getVoteResultsRBP()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        if (uint32(block.timestamp) < voteStart + voteLength) {
            revert VoteNotConcluded();
        }
        return (yesVotesRBP, yesVoteOption2RBP, noVotesRBP, abstainVotesRBP);
    }

    /// @notice Returns the vote results
    /// @notice Will not return results if the vote is still in progress
    /// @return yesVotesMinerToken The number of yes votes
    /// @return yesVoteOption2MinerToken The number of yes votes for the second option, 0 if there is no second option
    /// @return noVotesMinerToken The number of no votes
    /// @return abstainVotesMinerToken The number of abstain votes
    function getVoteResultsMinerToken()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        if (uint32(block.timestamp) < voteStart + voteLength) {
            revert VoteNotConcluded();
        }
        return (
            yesVotesMinerToken,
            yesVoteOption2MinerToken,
            noVotesMinerToken,
            abstainVotesMinerToken
        );
    }

    /// @notice Returns the vote results
    /// @notice Will not return results if the vote is still in progress
    /// @return yesVotesToken The number of yes votes
    /// @return yesVoteOption2Token The number of yes votes for the second option, 0 if there is no second option
    /// @return noVotesToken The number of no votes
    /// @return abstainVotesToken The number of abstain votes
    function getVoteResultsToken()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        if (uint32(block.timestamp) < voteStart + voteLength) {
            revert VoteNotConcluded();
        }
        return (
            yesVotesToken,
            yesVoteOption2Token,
            noVotesToken,
            abstainVotesToken
        );
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     Internal Functions                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Checks if an address is a controlling address for a miner
    /// @param minerId The miner to check
    /// @param sender The address to check
    /// @return isMiner True if the address is a controlling address for the miner
    function isMiner(
        uint64 minerId,
        address sender
    ) internal view returns (bool) {
        if (minerId == 0) {
            return false;
        }
        return
            MinerAPI.isControllingAddress(
                CommonTypes.FilActorId.wrap(minerId),
                toFilAddr(sender)
            );
    }

    /// @notice Calculates the voting power of a voter for a single miner
    /// @notice If voting power is zero, voting power is calculated off of FIL balance and LSD token balances
    /// @param minerId The miner to calculate voting power for
    /// @param voter The address of the voter
    /// @return power The voting power of the voter
    function voterRBP(
        uint64 minerId,
        address voter
    ) internal view returns (uint256 power) {
        bool isminer = isMiner(minerId, voter);
        if (!isminer) return 0;

        // Vote weight as a miner
        PowerTypes.MinerRawPowerReturn memory pow = PowerAPI.minerRawPower(
            uint64(minerId)
        );
        CommonTypes.BigInt memory p = pow.raw_byte_power;

        if (p.neg) {
            return 0;
        }

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

    /// @notice Converts an address to a filecoin address
    /// @param addr The address to convert
    /// @return filAddr The filecoin address
    function toFilAddr(
        address addr
    ) internal pure returns (CommonTypes.FilAddress memory filAddr) {
        bytes memory delegatedAddr = abi.encodePacked(hex"040a", addr);
        filAddr = CommonTypes.FilAddress(delegatedAddr);
    }

    /// @notice If this vote has two yes options then this function will put it in the correct category
    /// @notice This function should only be called if the vote param modulo 3 == 0
    function yesChoice(
        uint256 vote,
        uint256 weightRBP,
        uint256 weightMinerToken,
        uint256 weightToken
    ) internal {
        uint option = vote % 6;
        // Option should only result in 0 or 3
        if (option >= 3) {
            yesVoteOption2RBP += weightRBP;
            yesVoteOption2MinerToken += weightMinerToken;
            yesVoteOption2Token += weightToken;
        } else {
            yesVotesRBP += weightRBP;
            yesVotesMinerToken += weightMinerToken;
            yesVotesToken += weightToken;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Admin Functions                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Adds a token to the list of tokens that are counted as voting power
    /// @param token The address of the token to add
    function addLSDToken(address token) public onlyOwner {
        lsdTokens.push(token);
    }

    /// @notice Removes a token from the list of tokens that are counted as voting power
    /// @param index The index of the token to remove
    function removeLSDToken(uint index) public onlyOwner {
        lsdTokens[index] = lsdTokens[lsdTokens.length - 1];
        lsdTokens.pop();
    }
}
