// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "ds-test/test.sol";

import "../src/VoteTracker.sol";
import "../src/VoteFactory.sol";

import {Vm} from "forge-std/Vm.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import "./utils/Utilities.sol";

contract VoteFactoryTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    address[] internal lsdTokens;

    address constant STFIL = address(0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8);

    VoteFactory internal factory;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        lsdTokens = new address[](1);
        lsdTokens[0] = STFIL;
        factory = new VoteFactory();
    }

    function testStartVote() public {
        address user = users[0];

        address vote = factory.startVote(1 days, 0, false, lsdTokens);
        assertEq(vote, factory.deployedVotes(0));
        assertEq(factory.FIPnumToAddress(0), vote);
    }
}