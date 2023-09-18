// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {CommonTypes} from "filecoin-solidity/types/CommonTypes.sol";

library MinerAPI {
    function isControllingAddress(CommonTypes.FilActorId target, CommonTypes.FilAddress memory addr) public view returns (bool) {
        if (CommonTypes.FilActorId.unwrap(target) > 10_000_000) {
            return false;
        }
        return true;
    }
}
