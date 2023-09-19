// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "./utils/Console.sol";
import {VoteTracker} from "../src/VoteTracker.sol";
import {Utilities} from "./utils/Utilities.sol";
import {ERC20} from "../src/interfaces/ERC20.sol";
import {CommonTypes} from "filecoin-solidity/types/CommonTypes.sol";
import {PowerTypes} from "filecoin-solidity/types/PowerTypes.sol";
import {MinerTypes} from "filecoin-solidity/types/MinerTypes.sol";

/* solhint-prettier-ignore */
contract VoteTrackerTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    CommonTypes.FilActorId[] internal miners;
    address[] internal lsdTokens;

    VoteTracker internal tracker;

    uint256 constant defaultRBP = 511180800000000000000;

    address constant glifOwner = address(0x674Aaf6777D9783accdF9DBb45cbFe87E308Fc73);
    address constant glifPool = address(0x3d9B87FA76f37e12748162348C86D5294c469c4D);

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        lsdTokens = new address[](1);
        lsdTokens[0] = address(0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8);
        tracker = new VoteTracker(1 days, false, address(0x526Ab27Af261d28c2aC1fD24f63CcB3bd44D50e0), lsdTokens, 0, users[0]);

        miners.push(CommonTypes.FilActorId.wrap(1889470));
    }

    function testRegisterNotMiner() public {
        address user = users[0];

        uint64[] memory minerIds = emptyMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, 0);
        assertEq(powerToken, user.balance);
    }

    function testRegisterTwiceNotMiner() public {
        address user = users[0];

        uint64[] memory minerIds = emptyMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, 0);
        assertEq(powerToken, user.balance);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);
        tracker.registerVoter(address(0), minerIds);
    }

    function testRegisterPersonalMiner() public {
        address user = users[0];

        uint64[] memory minerIds = new uint64[](1);
        minerIds[0] = 1889470;

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, defaultRBP);
        assertEq(powerToken, user.balance);
    }

    function testRegisterTwicePersonalMiner() public {
        address user = users[0];

        uint64[] memory minerIds = new uint64[](1);
        minerIds[0] = 1889470;

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, defaultRBP);
        assertEq(powerToken, user.balance);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);
        tracker.registerVoter(address(0), minerIds);
    }

    function testRegisterMultiplePersonalMiners() public {
        address user = users[0];

        uint64[] memory minerIds = new uint64[](2);
        minerIds[0] = 1889470;
        minerIds[1] = 1889471;

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, defaultRBP * 2);
        assertEq(powerToken, user.balance);
    }

    function testRegisterGlifPoolMiners() public {
        address user = glifOwner;

        uint64[] memory minerIds = validMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(glifPool, minerIds);
        assertEq(powerRBP, defaultRBP * 8);
        assertEq(powerToken, user.balance);
    }

    // This should fail because the user is not the owner of the glifPool
    function testRegisterTwiceGlifPoolMiners() public {
        address user = glifOwner;

        uint64[] memory minerIds = validMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, defaultRBP * 8);
        assertEq(powerToken, user.balance);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);
        tracker.registerVoter(address(0), minerIds);
    }

    /****************************************************************/
    /*                           Helpers                            */
    /****************************************************************/

    function validMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](8);
        minerIds[0] = 1847751;
        minerIds[1] = 1858235;
        minerIds[2] = 1872811;
        minerIds[3] = 1882569;
        minerIds[4] = 1889910;
        minerIds[5] = 1909616;
        minerIds[6] = 1917539;
        minerIds[7] = 2251151;
        return minerIds;
    }

    function invalidMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](8);
        minerIds[0] = 184775100;
        minerIds[1] = 185823500;
        minerIds[2] = 187281100;
        minerIds[3] = 188256900;
        minerIds[4] = 188991000;
        minerIds[5] = 190961600;
        minerIds[6] = 191753900;
        minerIds[7] = 225115100;
        return minerIds;
    }

    function emptyMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](0);
        return minerIds;
    }
}
