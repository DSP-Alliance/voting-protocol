// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "./utils/Console.sol";
import {VoteTracker} from "../src/VoteTracker.sol";
import {Utilities} from "./utils/Utilities.sol";
import {CommonTypes} from "filecoin-solidity/types/CommonTypes.sol";
import {PowerTypes} from "filecoin-solidity/types/PowerTypes.sol";
import {MinerTypes} from "filecoin-solidity/types/MinerTypes.sol";
import {MinerAPI} from "filecoin-solidity/MinerAPI.sol";
import {PowerAPI} from "filecoin-solidity/PowerAPI.sol";
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

        tracker = new VoteTracker(1 days, false, address(0));

        miners.push(CommonTypes.FilActorId.wrap(1889470));
    }

    function testRegisterNotMiner() public {
        address user = users[0];
        vm.prank(user);

        uint64[] memory minerIds;
        minerIds[0] = uint64(1378);
        uint power = tracker.registerVoter(address(0), minerIds);
        assertEq(power, 10);
    }

    function testRegisterTwice() public {
        address user = users[0];
        vm.prank(user);

        uint64[] memory minerIds;
        minerIds[0] = uint64(1378);
        tracker.registerVoter(address(0), minerIds);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);

        vm.prank(user);
        tracker.registerVoter(address(0), minerIds);
    }

    function testRegisterNotYourMiner() public {
        address user = users[0];
        vm.prank(user);

        //vm.expectRevert();
        //tracker.registerVoter(CommonTypes.FilActorId.wrap(2081040));
    }

    function testToFilActorId() public view returns (bytes memory) {
        // this is f410fmhcspsb56aa7teobq5s2awfbpdgfuot6zngijra encoded to hex
        bytes memory addr = hex"6D686373707362353661613774656F62713573326177666270646766756F74367A6E67696A726120";

        // static call to the precompile resolve address
        (bool success, bytes memory raw_response) = address(0xFE00000000000000000000000000000000000001).staticcall(addr);
        require(success, "failed to call precompile");

        return raw_response;
    }

    function testMinerPowerAPI() public view returns (uint256 power) {
        // Vote weight as a miner
        PowerTypes.MinerRawPowerReturn memory pow = PowerAPI.minerRawPower(uint64(1889512));
        CommonTypes.BigInt memory p = pow.raw_byte_power;
        if (p.neg) {
            power = 10;
        } else {
            assembly {
                power := mload(add(p, 32))
            }
        }
    }

    function testPrecompileCode() public view returns (bytes32) {
        address CALL_ACTOR_ADDRESS = 0xfe00000000000000000000000000000000000005;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(CALL_ACTOR_ADDRESS)
        }
        return codehash;
    }

    function testMinerCount() public view returns (uint256) {
        return PowerAPI.minerCount();
    }

    function testBytes(bytes32 _example) public pure returns (uint256) {
        bytes memory example = hex"1712B9E147AE141260";
        uint256 received;

        assembly {
            // length := 0x07
            let length := mload(example)

            let _bytes := mload(add(example, 0x20))
            let shift := mul(sub(0x40, mul(length, 2)), 0x04)
            //mstore(add(location, 0x20), shr(shift, _bytes))

            //return (add(location, 0x20), 0x20)

            received := shr(shift, _bytes)
        }
        return received;
    }
}
// 7800000000000000
// 1BB60F053F800000000000000000000000000000000000000000000000000000
// 1BB60F053F80000000000000000000000000000000000000000000000000
// 1BB60F053F800000000000000000000000000000000000000000000 - 0x24
