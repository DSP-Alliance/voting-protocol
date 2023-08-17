// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/VoteTracker.sol";

contract DeployVoteTracker is Script {
    
    function setUp() public {}

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        VoteTracker tracker = new VoteTracker(
            7 days,
            false
        );

        vm.stopBroadcast();

        console.log("HustleBot deployed at: ", address(tracker));
        console.log("Deployer Address: ", deployerAddress);
    }
}