// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./VoteTracker.sol";
import "solmate/auth/Owned.sol";

/*
 _______  __   __       _______   ______   ______    __  .__   __.                     
|   ____||  | |  |     |   ____| /      | /  __  \  |  | |  \ |  |                     
|  |__   |  | |  |     |  |__   |  ,----'|  |  |  | |  | |   \|  |                     
|   __|  |  | |  |     |   __|  |  |     |  |  |  | |  | |  . `  |                     
|  |     |  | |  `----.|  |____ |  `----.|  `--'  | |  | |  |\   |                     
|__|     |__| |_______||_______| \______| \______/  |__| |__| \__|                     
                                                                                       
____    ____  ______   .___________. __  .__   __.   _______                           
\   \  /   / /  __  \  |           ||  | |  \ |  |  /  _____|                          
 \   \/   / |  |  |  | `---|  |----`|  | |   \|  | |  |  __                            
  \      /  |  |  |  |     |  |     |  | |  . `  | |  | |_ |                           
   \    /   |  `--'  |     |  |     |  | |  |\   | |  |__| |                           
    \__/     \______/      |__|     |__| |__| \__|  \______|                           
                                                                                       
.______   .______        ______   .___________.  ______     ______   ______    __      
|   _  \  |   _  \      /  __  \  |           | /  __  \   /      | /  __  \  |  |     
|  |_)  | |  |_)  |    |  |  |  | `---|  |----`|  |  |  | |  ,----'|  |  |  | |  |     
|   ___/  |      /     |  |  |  |     |  |     |  |  |  | |  |     |  |  |  | |  |     
|  |      |  |\  \---. |  `--'  |     |  |     |  `--'  | |  `----.|  `--'  | |  `----.
| _|      | _| `.____|  \______/      |__|      \______/   \______| \______/  |_______|

*/

contract VoteFactory is Owned {



    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Public Storage                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address[] public deployedVotes;
    mapping(address => bool) public starters;

    mapping (uint32 => address) public FIPnumToAddress;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Events                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event VoteStarted(address vote, uint32 fipNum, uint32 length);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          Modifers                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier onlyStarter() {
        if (!starters[msg.sender]) revert NotAStarter(msg.sender);
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

    constructor() Owned(msg.sender) {
        starters[msg.sender] = true;
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
    function startVote(uint32 length, uint32 fipNum, bool doubleYesOption, address[] memory lsdTokens, string memory question) public onlyStarter returns (address vote) {
        if (FIPnumToAddress[fipNum] != address(0)) revert VoteAlreadyExists(fipNum);

        vote = address(new VoteTracker(length, doubleYesOption, lsdTokens, fipNum, owner, question));

        FIPnumToAddress[fipNum] = vote;
        deployedVotes.push(vote);
        
        emit VoteStarted(vote, fipNum, length);
    }

    function addStarter(address starter) public onlyOwner {
        starters[starter] = true;
    }

    function removeStarter(address starter) public onlyOwner {
        starters[starter] = false;
    }
}