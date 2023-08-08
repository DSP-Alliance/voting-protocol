// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "./utils/Console.sol";
import {VoteTracker} from "../src/VoteTracker.sol";
import {Utilities} from "./utils/Utilities.sol";
import {CommonTypes} from "filecoin-solidity/types/CommonTypes.sol";
import {MinerTypes} from "filecoin-solidity/types/MinerTypes.sol";
import {MinerAPI} from "filecoin-solidity/MinerAPI.sol";
import {PrecompilesAPI} from "filecoin-solidity/PrecompilesAPI.sol";

/* solhint-prettier-ignore */
contract VoteTrackerTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    CommonTypes.FilActorId[] internal miners;

    VoteTracker internal tracker;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        tracker = new VoteTracker(1 days);

        miners.push(CommonTypes.FilActorId.wrap(1889470));
    }

    function testRegisterNotMiner() public {
        address user = users[0];
        vm.prank(user);

        uint power = tracker.registerVoter(CommonTypes.FilActorId.wrap(0));
        assertEq(power, 10);
    }

    function testRegisterTwice() public {
        address user = users[0];
        vm.prank(user);

        tracker.registerVoter(CommonTypes.FilActorId.wrap(0));
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);

        vm.prank(user);
        tracker.registerVoter(CommonTypes.FilActorId.wrap(0));
    }

    function testRegisterNotYourMiner() public {
        address user = users[0];
        vm.prank(user);

        //vm.expectRevert();
        //tracker.registerVoter(CommonTypes.FilActorId.wrap(2081040));
    }

    function testToFilActorId() public returns (bytes memory) {
        // this is f410fmhcspsb56aa7teobq5s2awfbpdgfuot6zngijra encoded to hex
        bytes memory addr = hex"66343130666D686373707362353661613774656F62713573326177666270646766756F74367A6E67696A726120";

        // this is actor Id of the above account
        bytes memory delegatedAddr = abi.encodePacked(uint256(2361681));

        // static call to the precompile resolve address
        (bool success, bytes memory raw_response) = address(0xFE00000000000000000000000000000000000001).staticcall(addr);
        require(success, "failed to call precompile");

        return raw_response;
    }
}
