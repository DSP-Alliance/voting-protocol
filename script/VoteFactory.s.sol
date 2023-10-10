// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/VoteFactory.sol";
import "../src/VoteTracker.sol";

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

contract CreateVote is Script {
    VoteFactory immutable factory = VoteFactory(vm.envAddress("VOTE_FACTORY"));
    address[] internal lsdTokens;
    address constant STFIL = address(0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8);

    function setUp() public {
        lsdTokens = new address[](1);
        lsdTokens[0] = STFIL;
    }

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        VoteTracker vote = VoteTracker(factory.startVote(1 days, 1, ["Ham", "Salami"], lsdTokens, "Do we make a sandwich?"));
        vm.stopBroadcast();

        console.log("Vote deployed at: ", address(vote));
        console.log("Deployer Address: ", deployerAddress);
    }
}