// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "filecoin-solidity/MinerAPI.sol";
import "filecoin-solidity/PowerAPI.sol";
import "filecoin-solidity/PrecompilesAPI.sol";
import "filecoin-solidity/types/CommonTypes.sol";
import "filecoin-solidity/types/PowerTypes.sol";

contract VoteTester {
    function minerPower(uint64 minerId) public returns (uint256 power) {
        PowerTypes.MinerRawPowerReturn memory pow = PowerAPI.minerRawPower(minerId);
        CommonTypes.BigInt memory p = pow.raw_byte_power;
        assembly {
            power := mload(add(p, 32))
        }
    }

    function controllingAddress(uint64 minerId, CommonTypes.FilAddress memory controller) public returns (bool) {
        return MinerAPI.isControllingAddress(CommonTypes.FilActorId.wrap(minerId), controller);
    }

    function resolveEthAddress(address addr) public returns (uint64 minerId) {
        minerId = PrecompilesAPI.resolveEthAddress(addr);
    }

    function lookupDelegatedAddress(uint64 actorId) public returns (bytes memory) {
        return PrecompilesAPI.lookupDelegatedAddress(actorId);
    }
}