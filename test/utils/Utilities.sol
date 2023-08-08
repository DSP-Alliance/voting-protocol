// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";

import {LibRLP} from "./LibRLP.sol";

contract Utilities is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address payable) {
        // bytes32 to address conversion
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    function warpMaxMintable(uint256 maxMintable) external {
        uint256 time = (86400 * maxMintable) / 10;
        vm.warp(block.timestamp + time);
    }


    function contractAddress(
        address user,
        uint256 distanceFromCurrentNonce
    ) external view returns (address) {
        return
            LibRLP.computeAddress(
                user,
                vm.getNonce(user) + distanceFromCurrentNonce
            );
    }

    function createUsers(
        uint256 userNum
    ) external returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);

        for (uint256 i = 0; i < userNum; i++) {
            address payable user = this.getNextUserAddress();
            vm.deal(user, 1000 ether);
            users[i] = user;
        }
        return users;
    }
}
