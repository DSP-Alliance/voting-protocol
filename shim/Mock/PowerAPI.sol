// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "filecoin-solidity/types/PowerTypes.sol";
import "filecoin-solidity/types/CommonTypes.sol";

library PowerAPI {
    bytes32 constant RANDOMNESS_SEED = keccak256("Voting Tool Randomness Seed");

    function minerRawPower(uint64 minerId) public pure returns (PowerTypes.MinerRawPowerReturn memory power) {
        bytes memory val = uint64ToBytes(minerId);
        if (minerId == 0 || minerId == type(uint64).max) {
            val = hex"00";
        }
        bool neg = false;
        CommonTypes.BigInt memory p = CommonTypes.BigInt(val, neg);
        power.raw_byte_power = p;
        power.meets_consensus_minimum = true;
    }

    function uint64ToBytes(uint64 num) internal pure returns (bytes memory b) {
        b = new bytes(8);
        assembly {
            let mask := 0xFF
            let bStart := add(b, 32)
            for { let i := 0 } lt(i, 8) { i := add(i, 1) } {
                mstore8(add(bStart, sub(7, i)), and(mask, num))
                num := shr(8, num)
            }
        }
    }
}