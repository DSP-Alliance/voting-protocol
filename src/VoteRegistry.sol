// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract VoteRegistry {
    mapping (address => bytes32) public identifier;
    mapping (bytes32 => bool) public registered;


    function register(bytes32 identifierHash) public {
        if (registered[identifierHash]) {
            revert("Already registered");
        }
        registered[identifierHash] = true;
        identifier[msg.sender] = identifierHash;
    }

    function deregister() public {
        bytes32 hash = identifier[msg.sender];
        delete identifier[msg.sender];
        delete registered[hash];
    }

    function voteWeight(address voter) public pure returns (uint weight) {
        if (voter == address(0)) {
            revert("Invalid address");
        }
        weight = 1;
    }
}
