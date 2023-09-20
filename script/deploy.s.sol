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
        // This is the STFIL token
        //address[1] memory lsdTokens = [address(0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8)];

        VoteFactory factory = new VoteFactory(address(0x526Ab27Af261d28c2aC1fD24f63CcB3bd44D50e0));

        vm.stopBroadcast();

        console.log("Factory deployed at: ", address(factory));
        console.log("Deployer Address: ", deployerAddress);
    }
}