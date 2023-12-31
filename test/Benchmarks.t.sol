// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "./utils/Console.sol";
import {VoteTracker} from "../src/VoteTracker.sol";
import {VoteFactory} from "../src/VoteFactory.sol";
import {Utilities} from "./utils/Utilities.sol";
import {ERC20} from "../src/interfaces/ERC20.sol";
import {CommonTypes} from "filecoin-solidity/types/CommonTypes.sol";
import {PowerTypes} from "filecoin-solidity/types/PowerTypes.sol";
import {MinerTypes} from "filecoin-solidity/types/MinerTypes.sol";

contract VoteTrackerTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    CommonTypes.FilActorId[] internal miners;
    address[] internal lsdTokens;

    VoteTracker internal tracker;
    VoteFactory internal factory;

    uint256 constant defaultRBP = 511180800000000000000;


    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        string[2] memory yesOptions;

        lsdTokens = new address[](1);
        lsdTokens[0] = address(0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8);
        factory = new VoteFactory();
        tracker = new VoteTracker(address(factory), 1 days, yesOptions, lsdTokens, 0, users[0], "What sandwich should i eat");

        miners.push(CommonTypes.FilActorId.wrap(1889470));
    }
}