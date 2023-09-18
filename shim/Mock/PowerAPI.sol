// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "filecoin-solidity/types/PowerTypes.sol";
import "filecoin-solidity/types/CommonTypes.sol";

library PowerAPI {
    bytes32 constant RANDOMNESS_SEED = keccak256("Voting Tool Randomness Seed");

    function minerRawPower(uint64 minerId) public view returns (PowerTypes.MinerRawPowerReturn memory power) {
        bytes memory val = hex"1BB60F053F80000000";
        bool neg = false;
        CommonTypes.BigInt memory p = CommonTypes.BigInt(val, neg);
        power.raw_byte_power = p;
        power.meets_consensus_minimum = true;
    }
}