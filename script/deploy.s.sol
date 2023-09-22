// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/VoteFactory.sol";

contract DeployVoteFactory is Script {

    function setUp() public {}

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        VoteFactory factory = new VoteFactory();

        vm.stopBroadcast();

        console.log("Factory deployed at: ", address(factory));
        console.log("Deployer Address: ", deployerAddress);
    }
}