// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {GlifFactory} from "interfaces/GlifFactory.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "./utils/Console.sol";
import {VoteTracker} from "../src/VoteTracker.sol";
import {Utilities} from "./utils/Utilities.sol";
import {ERC20} from "../src/interfaces/ERC20.sol";
import {CommonTypes} from "filecoin-solidity/types/CommonTypes.sol";
import {PowerTypes} from "filecoin-solidity/types/PowerTypes.sol";
import {MinerTypes} from "filecoin-solidity/types/MinerTypes.sol";

/* solhint-prettier-ignore */
contract VoteTrackerTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    address[] internal lsdTokens;

    VoteTracker internal tracker;

    address constant GLIFOWNER = address(0x674Aaf6777D9783accdF9DBb45cbFe87E308Fc73);
    address constant GLIFPOOL = address(0x3d9B87FA76f37e12748162348C86D5294c469c4D);
    address constant GLIFFACTORY = address(0x526Ab27Af261d28c2aC1fD24f63CcB3bd44D50e0);
    address constant STFIL = address(0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8);

    uint256 constant YESVOTE = uint256(0);
    uint256 constant YES2VOTE = uint256(3);
    uint256 constant NOVOTE = uint256(1);
    uint256 constant ABSTAINVOTE = uint256(2);

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        lsdTokens = new address[](1);
        lsdTokens[0] = STFIL;
        tracker = new VoteTracker(1 days, true, lsdTokens, 0, users[0], "What sandwich should i eat");
    }

    function testSetUp() public view {
        assert(GlifFactory(GLIFFACTORY).isAgent(GLIFPOOL));
        assert(Owned(GLIFPOOL).owner() == GLIFOWNER);
    }

    /************************* Registration *************************/

    function testRegisterNotMiner() public {
        address user = users[0];

        uint64[] memory minerIds = emptyMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, 0);
        assertEq(powerToken, user.balance);
    }

    function testRegisterNotYourMiner() public {
        address user = users[0];

        // invalid minerIds represent miners that are not yours
        // the MinerAPI.controllingAddress() call will fail
        uint64[] memory minerIds = invalidMinerIds();

        vm.prank(user);
        vm.expectRevert(VoteTracker.InvalidMiner.selector);
        tracker.registerVoter(address(0), minerIds);
    }

    function testRegisterNotYourGlifPool() public {
        address user = users[0];

        uint64[] memory minerIds = glifPoolMinerIds();

        assert(user != Owned(GLIFPOOL).owner());

        vm.prank(user);
        vm.expectRevert(VoteTracker.InvalidGlifPool.selector);
        tracker.registerVoter(GLIFPOOL, minerIds);
    }

    function testRegisterTwiceNotMiner() public {
        address user = users[0];

        uint64[] memory minerIds = emptyMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, 0);
        assertEq(powerToken, user.balance);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);
        tracker.registerVoter(address(0), minerIds);
    }

    function testRegisterPersonalMiner() public {
        address user = users[0];

        uint64[] memory minerIds = new uint64[](1);
        minerIds[0] = 1889470;

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertGt(powerRBP, 0);
        assertEq(powerToken, user.balance);
    }

    function testRegisterTwicePersonalMiner() public {
        address user = users[0];

        uint64[] memory minerIds = new uint64[](1);
        minerIds[0] = 1889470;

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertGt(powerRBP, 0);
        assertEq(powerToken, user.balance);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);
        tracker.registerVoter(address(0), minerIds);
    }

    function testRegisterMultiplePersonalMiners() public {
        address user = users[0];

        uint64[] memory minerIds = new uint64[](2);
        minerIds[0] = 1889470;
        minerIds[1] = 1889471;

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertGt(powerRBP, 0);
        assertEq(powerToken, user.balance);
    }

    function testRegisterGlifPoolMiners() public {
        address user = GLIFOWNER;

        uint64[] memory minerIds = glifPoolMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(GLIFPOOL, minerIds);
        assertGt(powerRBP, 0);
        assertEq(powerToken, user.balance);
    }

    // This should fail because the user is not the owner of the glifPool
    function testRegisterTwiceGlifPoolMiners() public {
        address user = GLIFOWNER;

        uint64[] memory minerIds = glifPoolMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(GLIFPOOL, minerIds);
        assertGt(powerRBP, 0);
        assertEq(powerToken, user.balance);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);
        tracker.registerVoter(GLIFPOOL, minerIds);
    }


    /**************************** Voting ****************************/

    function testVoteNormal(uint256 vote) public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(yesVote(vote));
    }

    function testVoteGlif(uint256 vote) public {
        address user = GLIFOWNER;

        registerGlif(user);

        vm.prank(user);
        tracker.castVote(yesVote(vote));
    }

    function testVotePersonalMiner(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerPersonalMiner(user, randomRBP);

        vm.prank(user);
        tracker.castVote(yesVote(vote));
    }

    function testVoteTwice(uint256 vote) public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(yesVote(vote));

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(yesVote(vote));
    }

    function testVoteTwiceGlif(uint256 vote) public {
        address user = GLIFOWNER;

        registerGlif(user);

        vm.prank(user);
        tracker.castVote(yesVote(vote));

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(yesVote(vote));
    }

    function testVoteTwicePersonalMiner(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerPersonalMiner(user, randomRBP);

        vm.prank(user);
        tracker.castVote(yesVote(vote));

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(yesVote(vote));
    }

    function testVoteTwiceDifferent(uint256 vote) public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(yesVote(vote));

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(noVote(vote));
    }

    function testVoteTwiceDifferentGlif(uint256 vote) public {
        address user = GLIFOWNER;

        registerGlif(user);

        vm.prank(user);
        tracker.castVote(yesVote(vote));

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(noVote(vote));
    }

    function testVoteTwiceDifferentPersonalMiner(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerPersonalMiner(user, randomRBP);

        vm.prank(user);
        tracker.castVote(yesVote(vote));

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(noVote(vote));
    }

    function testVoteResultsTooEarly(uint256 vote) public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(yesVote(vote));

        vm.expectRevert(VoteTracker.VoteNotConcluded.selector);
        tracker.getVoteResultsToken();

        vm.expectRevert(VoteTracker.VoteNotConcluded.selector);
        tracker.getVoteResultsRBP();

        vm.expectRevert(VoteTracker.VoteNotConcluded.selector);
        tracker.getVoteResultsMinerToken();
    }

    /************************ Checking Results ******************************/

    function testVoteYesToken(uint256 vote) public {
        address user = users[0];

        registerVoteNormal(user, yes1Vote(vote));
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, user.balance + 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteYes2Token(uint256 vote) public {
        address user = users[0];

        registerVoteNormal(user, yes2Vote(vote));
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, 1);
        assertEq(yes2, user.balance + 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteNoToken(uint256 vote) public {
        address user = users[0];

        registerVoteNormal(user, noVote(vote));
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, user.balance + 1);
        assertEq(abstain, 1);
    }

    function testVoteAbstainToken(uint256 vote) public {
        address user = users[0];

        registerVoteNormal(user, abstainVote(vote));
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, user.balance + 1);
    }

    function testVoteYesRBP(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerVotePersonalMiner(user, yes1Vote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertGt(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteYes2RBP(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerVotePersonalMiner(user, yes2Vote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertEq(yes, 1);
        assertGt(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteNoRBP(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerVotePersonalMiner(user, noVote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertGt(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteAbstainRBP(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerVotePersonalMiner(user, abstainVote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertGt(abstain, 1);
    }

    function testVoteYesMinerToken(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerVotePersonalMiner(user, yes1Vote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days);

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsMinerToken();
        assertEq(yes, user.balance + 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteYes2MinerToken(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerVotePersonalMiner(user, yes2Vote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days);

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsMinerToken();
        assertEq(yes, 1);
        assertEq(yes2, user.balance + 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteNoMinerToken(uint256 vote, uint256 randomRBP) public {
        address user = users[0];

        registerVotePersonalMiner(user, noVote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days);

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsMinerToken();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, user.balance + 1);
        assertEq(abstain, 1);
    }

    function testYesWinningVote(uint256 vote, uint256 randomRBP) public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, yes1Vote(vote));
        registerVotePersonalMiner(user2, yes1Vote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.Yes);
    }

    function testYes2WinningVote(uint256 vote, uint256 randomRBP) public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, yes2Vote(vote));
        registerVotePersonalMiner(user2, yes2Vote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.Yes2);
    }

    function testNoWinningVote(uint256 vote, uint256 randomRBP) public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, noVote(vote));
        registerVotePersonalMiner(user2, noVote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.No);
    }

    function testAbstainWinningVote(uint256 vote, uint256 randomRBP) public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, abstainVote(vote));
        registerVotePersonalMiner(user2, abstainVote(vote), randomRBP);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.Abstain);
    }

    /****************************************************************/
    /*                           Helpers                            */
    /****************************************************************/

    /************************ Vote Generators ***********************/

    function yesVote(uint256 vote) internal view returns (uint256) {
        vm.assume(vote < type(uint256).max - 3);
        return (vote - (vote % 3));
    }

    /// @notice This should be used when 2 Yes options are available but you want to vote for the first option
    function yes1Vote(uint256 vote) internal view returns (uint256 num1) {
        vm.assume(vote < type(uint256).max - 3);
        uint three = vote - (vote % 3);
        return (three - (three % 6));
    }

    function yes2Vote(uint256 vote) internal view returns (uint256 num) {
        vm.assume(vote < type(uint256).max - 3);
        uint three = vote - (vote % 3);
        num = three - (three % 6) + 3;
    }

    function noVote(uint256 vote) internal view returns (uint256 num) {
        vm.assume(vote < type(uint256).max - 3);
        num = vote - (vote % 3) + 1;
    }

    function abstainVote(uint256 vote) internal view returns (uint256 num) {
        vm.assume(vote < type(uint256).max - 3);
        num = vote - (vote % 3) + 2;
    }

    function testYesVote(uint256 vote) public view {
        uint num = yesVote(vote);
        assert(num % 3 == 0);
    }

    function testYes1Vote(uint256 vote) public view {
        uint num = yes1Vote(vote);
        assert(num % 3 == 0 && num % 6 == 0);
    }

    function testYes2Vote(uint256 vote) public view {
        uint num = yes2Vote(vote);
        assert(num % 3 == 0 && num % 6 == 3);
    }

    function testNoVote(uint256 vote) public view {
        uint num = noVote(vote);
        assert(num % 3 == 1);
    }

    function testAbstainVote(uint256 vote) public view {
        uint num = abstainVote(vote);
        assert(num % 3 == 2);
    }

    function registerVoteNormal(address user, uint256 vote) internal {
        registerNormal(user);

        vm.prank(user);
        tracker.castVote(vote);
    }

    function registerVoteGlif(address user, uint256 vote) internal {
        registerGlif(user);

        vm.prank(user);
        tracker.castVote(vote);
    }

    function registerVotePersonalMiner(address user, uint256 vote, uint256 randomRBP) internal {
        registerPersonalMiner(user, randomRBP);

        vm.prank(user);
        tracker.castVote(vote);
    }

    function registerNormal(address user) internal {
        uint64[] memory minerIds = emptyMinerIds();
        register(address(0), minerIds, user);
    }

    function registerGlif(address user) internal {
        uint64[] memory minerIds = glifPoolMinerIds();
        register(GLIFPOOL, minerIds, user);
    }

    function registerPersonalMiner(address user, uint256 randomRBP) internal {
        vm.assume(randomRBP < type(uint256).max - 3);
        vm.assume(randomRBP > 10000);
        register(address(0), validMinerIds(randomRBP), user);
    }

    function register(address glifPool, uint64[] memory minerIds, address user) internal {
        vm.prank(user);
        tracker.registerVoter(glifPool, minerIds);
    }

    function testToAddress() public returns (address) {
        address addr = GLIFOWNER;
        CommonTypes.FilAddress memory filAddr = CommonTypes.FilAddress(abi.encodePacked(hex"040a", addr));
        address addr2 = toAddress(filAddr);
        assertEq(addr, addr2);
        return addr2;
    }

    function toAddress(CommonTypes.FilAddress memory _addr) internal pure returns (address addr) {
        bytes memory delegatedAddr = _addr.data;
        assembly {
            let _bytes := mload(add(delegatedAddr, 0x20))
            addr := shr(0x50, _bytes)
        }
    }

    function validMinerIds(uint256 randonRBP) internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](4);

        (uint64 a, uint64 b, uint64 c, uint64 d) = split(randonRBP);
        minerIds[0] = a;
        minerIds[1] = b;
        minerIds[2] = c;
        minerIds[3] = d;
        return minerIds;
    }

    function glifPoolMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](8);
        minerIds[0] = 1847751;
        minerIds[1] = 1858235;
        minerIds[2] = 1872811;
        minerIds[3] = 1882569;
        minerIds[4] = 1889910;
        minerIds[5] = 1909616;
        minerIds[6] = 1917539;
        minerIds[7] = 2251151;
        return minerIds;
    }

    function invalidMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](8);
        minerIds[0] = 0;
        minerIds[1] = 0;
        minerIds[2] = 0;
        minerIds[3] = 0;
        minerIds[4] = 0;
        minerIds[5] = 0;
        minerIds[6] = 0;
        minerIds[7] = 0;
        return minerIds;
    }

    function emptyMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](0);
        return minerIds;
    }

    function split(uint256 num) internal pure returns (uint64 a, uint64 b, uint64 c, uint64 d) {
        bytes32 value = keccak256(abi.encodePacked(num));
        assembly {
            a := shr(192, value)
            b := and(shr(128, value), 0xFFFFFFFFFFFFFFFF)
            c := and(shr(64, value), 0xFFFFFFFFFFFFFFFF)
            d := and(value, 0xFFFFFFFFFFFFFFFF)
        }
        if (a == 0) {
            a = 1;
        }
        if (b == 0) {
            b = 1;
        }
        if (c == 0) {
            c = 1;
        }
        if (d == 0) {
            d = 1;
        }
        if (a == type(uint64).max) {
            a = type(uint64).max - 1;
        }
        if (b == type(uint64).max) {
            b = type(uint64).max - 1;
        }
        if (c == type(uint64).max) {
            c = type(uint64).max - 1;
        }
        if (d == type(uint64).max) {
            d = type(uint64).max - 1;
        }
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

    function testUint64toBytes(uint64 num) public returns (uint64) {
        bytes memory input = uint64ToBytes(num);

        uint64 value = 0;
        for (uint i = 0; i < input.length; i++) {
            value = value << 8 | uint64(uint8(input[i]));
        }
        assertEq(value, num);
        
        return value;
    }
}
