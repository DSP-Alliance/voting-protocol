// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/GlifFactory.sol";
import "./interfaces/ERC20.sol";

import "shim/MinerAPI.sol";
import "shim/PowerAPI.sol";
import "filecoin-solidity/types/CommonTypes.sol";
import "filecoin-solidity/types/PowerTypes.sol";

import "solmate/auth/Owned.sol";

import "./interfaces/VoteFactory.sol";

contract VoteTracker is Owned {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Public Storage                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint32 public voteStart;
    uint32 public voteLength;
    string[2] public yesOptions;
    uint32 immutable public FIP;

    address[] public lsdTokens;
    string public question;

    mapping(address => bool) public hasVoted;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Internal Storage                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address constant glifFactory = address(0x526Ab27Af261d28c2aC1fD24f63CcB3bd44D50e0);
    IVoteFactory immutable factory;

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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Events                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event VoteCast(
        address voter,
        uint256 weightRBP,
        uint256 weightToken,
        uint256 vote
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Errors                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error AlreadyVoted();
    error VoteNotConcluded();
    error VoteConcluded();
    error InvalidGlifPool();
    error InvalidMiner();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Enums                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    enum Vote {
        Yes,
        No,
        Abstain,
        Yes2
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
        if (!factory.registered(sender)) {
            revert NotRegistered();
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         Constructor                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @param length The length of the vote in seconds
    /// @param _yesOptions If length > 0, vote will present these options if voting yes
    /// @param _lsdTokens The addresses of the LSD tokens to count as voting power
    /// @param owner The owner of the vote
    constructor(
        address factoryAddress,
        uint32 length,
        string[2] memory _yesOptions,
        address[] memory _lsdTokens,
        uint32 _FIP,
        address owner,
        string memory _question
    ) Owned(owner) {
        factory = IVoteFactory(factoryAddress);
        yesOptions = _yesOptions;
        FIP = _FIP;
        voteLength = length;
        voteStart = uint32(block.timestamp);
        lsdTokens = _lsdTokens;
        question = _question;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Public Functions                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Msg sender must be a registered voter
    /// @param vote The vote to cast
    function castVote(
        uint256 vote
    ) public voting(msg.sender) isRegistered(msg.sender) {
        uint vote_num = vote % 3;
        (uint weightToken, uint weightRBP, uint weightMinerToken) = getVotingPower(msg.sender);

        // YES VOTE
        if (vote_num == 0) {
            if (yesOptions.length > 0) {
                yesChoice(vote, weightRBP, weightMinerToken, weightToken);
            } else {
                yesVotesRBP += weightRBP;
                yesVotesMinerToken += weightMinerToken;
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

        emit VoteCast(msg.sender, weightRBP, weightToken, vote % 6);
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

            if (yesRBP > noRBP && yesRBP > abstainRBP && yesRBP > yes2RBP) {
                rbp = Vote.Yes;
            } else if (yes2RBP > noRBP && yes2RBP > abstainRBP) {
                rbp = Vote.Yes2;
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
                yesTokenVotes > abstainTokenVotes &&
                yesTokenVotes > yes2TokenVotes
            ) {
                // Win for yes Miner Token
                token = Vote.Yes;
            } else if (yes2TokenVotes > noTokenVotes && yes2TokenVotes > abstainTokenVotes) {
                token = Vote.Yes2;
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

    function hasRegistered(address voter) public view returns (bool) {
        return factory.registered(voter);
    }

    function getVotingPower(address voter) public view returns (uint256 tokenPower, uint256 bytePower, uint256 minerTokenPower) {
        address glifpool = factory.ownedGlifPool(voter);
        // Determine if glifpool is valid
        bool glif = (GlifFactory(glifFactory).isAgent(glifpool) &&
            Owned(glifpool).owner() == voter);
        
        if (glifpool != address(0) && !glif) {
            revert InvalidGlifPool();
        }
        
        // Collect RBP voting weight
        uint64[] storage minerIds = factory.ownedMiners(voter);
        uint length = minerIds.length;
        for (uint i = 0; i < length; ++i) {
            uint64 minerId = minerIds[i];

            // Add their RBP voting weight
            address minerOwner = glif ? glifpool : voter;

            // Set the RBP voting weight
            uint rbp = factory.voterRBP(minerId, minerOwner);
            if (rbp == 0) continue;

            bytePower += rbp;
        }

        // Collect FIL voting weight
        tokenPower += voter.balance;

        // Collect LSD voting weight
        length = lsdTokens.length;
        for (uint i = 0; i < length; ++i) {
            ERC20 token = ERC20(lsdTokens[i]);

            uint balance = token.balanceOf(voter);

            tokenPower += balance;
        }

        // If they have RBP then assign their token power to the miner's
        if (bytePower > 0) {
            return (0, bytePower, tokenPower);

            // If they have no RBP then assign to normal token category
        } else {
            return (tokenPower, bytePower, 0);
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
