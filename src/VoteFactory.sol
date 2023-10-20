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
    error AlreadyRegistered();
    error NotOwner();
    error MinerAlreadyRegistered();
    error InvalidGlifPool();


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Public Storage                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address[] public deployedVotes;
    mapping(address => bool) public starters;
    mapping(address => uint64[]) public ownedMiners;
    mapping(uint64 => address) public registeredMiner;
    mapping(address => address) public ownedGlifPool;
    mapping(address => bool) public registered;

    mapping (uint32 => address) public FIPnumToAddress;

    address constant glifFactory = address(0x526Ab27Af261d28c2aC1fD24f63CcB3bd44D50e0);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Events                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event VoteStarted(address vote, uint32 fipNum, uint32 length);
    event VoterRegistered(address voter, address glif, uint64[] minerIds);

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
    /// @param yesOptions The two options after voting yes to present, if length > 0
    /// @param lsdTokens The LSD tokens to use for the vote
    /// @return vote The address of the newly deployed VoteTracker contract
    function startVote(uint32 length, uint32 fipNum, string[2] memory yesOptions, address[] memory lsdTokens, string memory question) public onlyStarter returns (address vote) {
        if (FIPnumToAddress[fipNum] != address(0)) revert VoteAlreadyExists(fipNum);

        vote = address(new VoteTracker(address(this), length, yesOptions, lsdTokens, fipNum, owner, question));

        FIPnumToAddress[fipNum] = vote;
        deployedVotes.push(vote);
        
        emit VoteStarted(vote, fipNum, length);
    }

    function register(address glifpool, uint64[] calldata minerIds) public {
        // Do not let user register twice
        if (
            registered[msg.sender]
        ) {
            revert AlreadyRegistered();
        }

        bool glif = false;
        if (glifpool != address(0)) {
            glif = (GlifFactory(glifFactory).isAgent(glifpool) &&
                Owned(glifpool).owner() == msg.sender);

            if (!glif) {
                revert InvalidGlifPool();
            }
        }

        // Collect RBP voting weight
        uint length = minerIds.length;
        for (uint i = 0; i < length; ++i) {
            uint64 minerId = minerIds[i];

            if (registeredMiner[minerId] != address(0)) revert MinerAlreadyRegistered();

            // Add their RBP voting weight
            address minerOwner = glif ? glifpool : msg.sender;
            uint rbp = voterRBP(minerId, minerOwner);
            if (rbp == 0) continue;

            registeredMiner[minerId] = msg.sender;
            ownedMiners[msg.sender].push(minerId);
        }

        if (glif) {
            ownedGlifPool[msg.sender] = glifpool;
        }

        registered[msg.sender] = true;

        // Finalize state changes
        emit VoterRegistered(msg.sender, glifpool, minerIds);
    }

    function addMiner(address voter, uint64 minerId) public {
        if (!isMiner(minerId, msg.sender)) {
            revert NotOwner();
        }

        if (!registered[voter]) {
            revert NotRegistered();
        }

        if (registeredMiner[minerId] != address(0)) revert MinerAlreadyRegistered();

        registeredMiner[minerId] = voter;
        ownedMiners[voter].push(minerId);
    }

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

    function toFilAddr(
        address addr
    ) public pure returns (CommonTypes.FilAddress memory filAddr) {
        bytes memory delegatedAddr = abi.encodePacked(hex"040a", addr);
        filAddr = CommonTypes.FilAddress(delegatedAddr);
    }

    /// @notice Calculates the voting power of a voter for a single miner
    /// @notice If voting power is zero, voting power is calculated off of FIL balance and LSD token balances
    /// @param minerId The miner to calculate voting power for
    /// @param voter The address of the voter
    /// @return power The voting power of the voter
    function voterRBP(
        uint64 minerId,
        address voter
    ) public view returns (uint256 power) {
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

    function getOwnedMinerLength(address owner) external view returns (uint256 length) {
        return ownedMiners[owner].length;
    }

    function addStarter(address starter) public onlyOwner {
        starters[starter] = true;
    }

    function removeStarter(address starter) public onlyOwner {
        starters[starter] = false;
    }

    function deployedVotesLength() public view returns (uint256 len) {
        return deployedVotes.length;
    }
}