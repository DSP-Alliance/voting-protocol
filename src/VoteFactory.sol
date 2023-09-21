// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./VoteTracker.sol";
import "solmate/auth/Owned.sol";

contract VoteFactory is Owned {

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Internal Storage                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address immutable glifFactory;
    address[] public starters;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Public Storage                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address[] public deployedVotes;

    mapping (uint32 => address) public FIPnumToAddress;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Events                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event VoteStarted(address vote, uint32 fipNum, uint32 length);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Modifers                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier onlyStarter() {
        bool isStarter = false;
        uint length = starters.length;
        for (uint256 i = 0; i < length; ) {
            if (starters[i] == msg.sender) {
                isStarter = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!isStarter) revert NotAStarter(msg.sender);
        _;
    }
    
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Errors                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error VoteAlreadyExists(uint32 fipNum);
    error NotAStarter(address sender);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         Constructor                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @param _glifFactory The address of the GlifFactory contract
    constructor(address _glifFactory) Owned(msg.sender) {
        glifFactory = _glifFactory;
        starters.push(msg.sender);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Admin Function                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Deploys a new VoteTracker contract
    /// @param length The length of the vote in seconds
    /// @param fipNum The FIP number that this vote is for
    /// @param doubleYesOption Whether or not to include two yes options
    /// @param lsdTokens The LSD tokens to use for the vote
    /// @return vote The address of the newly deployed VoteTracker contract
    function startVote(uint32 length, uint32 fipNum, bool doubleYesOption, address[] memory lsdTokens) public onlyStarter returns (address vote) {
        if (FIPnumToAddress[fipNum] != address(0)) revert VoteAlreadyExists(fipNum);

        vote = address(new VoteTracker(length, doubleYesOption, glifFactory, lsdTokens, fipNum, owner));

        emit VoteStarted(vote, fipNum, length);
        FIPnumToAddress[fipNum] = vote;
        deployedVotes.push(vote);
    }

    function addStarter(address starter) public onlyOwner {
        starters.push(starter);
    }

    function removeStarter(address starter) public onlyOwner {
        for (uint256 i = 0; i < starters.length; i++) {
            if (starters[i] == starter) {
                _removeStarterIndex(i);
                return;
            }
        }
    }

    function _removeStarterIndex(uint256 index) public onlyOwner {
        starters[index] = starters[starters.length - 1];
        starters.pop();
    }
}