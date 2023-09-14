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
import {MinerAPI} from "filecoin-solidity/MinerAPI.sol";
import {PowerAPI} from "filecoin-solidity/PowerAPI.sol";
import {PrecompilesAPI} from "filecoin-solidity/PrecompilesAPI.sol";

/* solhint-prettier-ignore */
contract VoteTrackerTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    CommonTypes.FilActorId[] internal miners;
    address[] internal lsdTokens;

    VoteTracker internal tracker;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        lsdTokens = new address[](1);
        lsdTokens[0] = address(0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8);
        tracker = new VoteTracker(1 days, false, address(0), lsdTokens, users[0]);

        miners.push(CommonTypes.FilActorId.wrap(1889470));
    }

    function testRegisterNotMiner() public {
        address user = users[0];
        vm.prank(user);

        uint64[] memory minerIds;
        minerIds[0] = uint64(1378);
        (uint power, uint powerToken) = tracker.registerVoter(address(0), minerIds);
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
    
    function testVoterPower() public view returns (uint256) {
        return voterPower(0, users[0]);
    }

    function voterPower(uint64 minerId, address voter) public view returns (uint256 power) {
        bool isminer = isMiner(minerId);

        if (isminer) {
            // Vote weight as a miner
            CommonTypes.BigInt memory p = CommonTypes.BigInt(hex"1BB60F053F80000000", false);
            if (p.neg) {
                power = voter.balance / 1 ether;
            } else {
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
        } else {
            // 1 undenominated filecoin would be equal to 1,000 PiB raw byte power
            // Vote weight as a non-miner
            assembly {
                let ptr := lsdTokens.slot
                let len := sload(ptr)
                for {let i := 0 } lt(i, len) { i := add(i, 1) } {

                }
                let m := mload(0x40)
                mstore(m, sload(add(ptr, 0x02)))
                return (m, 0x20)
            }
        }
    }
    function isMiner(uint64 minerId) internal pure returns (bool) {
        if (minerId == 0) {
            return false;
        } else {
            return true;
        }
    }
}
// 7800000000000000
// 1BB60F053F800000000000000000000000000000000000000000000000000000
// 1BB60F053F80000000000000000000000000000000000000000000000000
// 1BB60F053F800000000000000000000000000000000000000000000 - 0x24
