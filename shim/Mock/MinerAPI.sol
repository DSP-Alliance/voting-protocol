// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {CommonTypes} from "filecoin-solidity/types/CommonTypes.sol";

library MinerAPI {
    function isControllingAddress(CommonTypes.FilActorId target, CommonTypes.FilAddress memory _addr) public pure returns (bool) {
        uint64 id = CommonTypes.FilActorId.unwrap(target);
        if (id == 0 || id == type(uint64).max) {
            return false;
        }
        bytes memory delegatedAddr = _addr.data;
        address addr;
        assembly {
            let _bytes := mload(add(delegatedAddr, 0x20))
            addr := shr(0x50, _bytes)
        }

        if (addr == address(0x3d9B87FA76f37e12748162348C86D5294c469c4D)) {
            return id == 1847751 || id == 1858235 || id == 1872811 || id == 1882569 || id == 1889910 || id == 1909616 || id == 1917539 || id == 2251151;
        } else {
        
            // Since the actorId is a random uint64 the chances that we accidentally reject on of these is 8/2^64 * 1024 fuzz runs
            return id != 1847751 && id != 1858235 && id != 1872811 && id != 1882569 && id != 1889910 && id != 1909616 && id != 1917539 && id != 2251151;
        }
    }
}
