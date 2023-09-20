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

    uint256 constant defaultRBP = 511180800000000000000;

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
        tracker = new VoteTracker(1 days, true, GLIFFACTORY, lsdTokens, 0, users[0]);
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
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, 0);
        assertEq(powerToken, user.balance);
    }

    function testRegisterNotYourGlifPool() public {
        address user = users[0];

        uint64[] memory minerIds = glifPoolMinerIds();

        assert(user != Owned(GLIFPOOL).owner());

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(GLIFPOOL, minerIds);
        assertEq(powerRBP, 0);
        assertEq(powerToken, user.balance);
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
        assertEq(powerRBP, defaultRBP);
        assertEq(powerToken, user.balance);
    }

    function testRegisterTwicePersonalMiner() public {
        address user = users[0];

        uint64[] memory minerIds = new uint64[](1);
        minerIds[0] = 1889470;

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(address(0), minerIds);
        assertEq(powerRBP, defaultRBP);
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
        assertEq(powerRBP, defaultRBP * 2);
        assertEq(powerToken, user.balance);
    }

    function testRegisterGlifPoolMiners() public {
        address user = GLIFOWNER;

        uint64[] memory minerIds = glifPoolMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(GLIFPOOL, minerIds);
        assertEq(powerRBP, defaultRBP * 8);
        assertEq(powerToken, user.balance);
    }

    // This should fail because the user is not the owner of the glifPool
    function testRegisterTwiceGlifPoolMiners() public {
        address user = GLIFOWNER;

        uint64[] memory minerIds = glifPoolMinerIds();

        vm.prank(user);
        (uint powerRBP, uint powerToken) = tracker.registerVoter(GLIFPOOL, minerIds);
        assertEq(powerRBP, defaultRBP * 8);
        assertEq(powerToken, user.balance);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyRegistered.selector);
        tracker.registerVoter(GLIFPOOL, minerIds);
    }


    /**************************** Voting ****************************/

    function testVoteNormal() public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);
    }

    function testVoteGlif() public {
        address user = GLIFOWNER;

        registerGlif(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);
    }

    function testVotePersonalMiner() public {
        address user = users[0];

        registerPersonalMiner(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);
    }

    function testVoteTwice() public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(YESVOTE);
    }

    function testVoteTwiceGlif() public {
        address user = GLIFOWNER;

        registerGlif(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(YESVOTE);
    }

    function testVoteTwicePersonalMiner() public {
        address user = users[0];

        registerPersonalMiner(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(YESVOTE);
    }

    function testVoteTwiceDifferent() public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(NOVOTE);
    }

    function testVoteTwiceDifferentGlif() public {
        address user = GLIFOWNER;

        registerGlif(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(NOVOTE);
    }

    function testVoteTwiceDifferentPersonalMiner() public {
        address user = users[0];

        registerPersonalMiner(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);

        vm.prank(user);
        vm.expectRevert(VoteTracker.AlreadyVoted.selector);
        tracker.castVote(NOVOTE);
    }

    function testVoteResultsTooEarly() public {
        address user = users[0];

        registerNormal(user);

        vm.prank(user);
        tracker.castVote(YESVOTE);

        vm.expectRevert(VoteTracker.VoteNotConcluded.selector);
        tracker.getVoteResultsToken();

        vm.expectRevert(VoteTracker.VoteNotConcluded.selector);
        tracker.getVoteResultsRBP();

        vm.expectRevert(VoteTracker.VoteNotConcluded.selector);
        tracker.getVoteResultsMinerToken();
    }

    /************************ Checking Results ******************************/

    function testVoteYesToken() public {
        address user = users[0];

        registerVoteNormal(user, YESVOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, user.balance + 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteYes2Token() public {
        address user = users[0];

        registerVoteNormal(user, YES2VOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, 1);
        assertEq(yes2, user.balance + 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteNoToken() public {
        address user = users[0];

        registerVoteNormal(user, NOVOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, user.balance + 1);
        assertEq(abstain, 1);
    }

    function testVoteAbstainToken() public {
        address user = users[0];

        registerVoteNormal(user, ABSTAINVOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsToken();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, user.balance + 1);
    }

    function testVoteYesRBP() public {
        address user = users[0];

        registerVotePersonalMiner(user, YESVOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertEq(yes, defaultRBP + 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteYes2RBP() public {
        address user = users[0];

        registerVotePersonalMiner(user, YES2VOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertEq(yes, 1);
        assertEq(yes2, defaultRBP + 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteNoRBP() public {
        address user = users[0];

        registerVotePersonalMiner(user, NOVOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, defaultRBP + 1);
        assertEq(abstain, 1);
    }

    function testVoteAbstainRBP() public {
        address user = users[0];

        registerVotePersonalMiner(user, ABSTAINVOTE);
        vm.warp(block.timestamp + 1 days); 

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsRBP();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, defaultRBP + 1);
    }

    function testVoteYesMinerToken() public {
        address user = users[0];

        registerVotePersonalMiner(user, YESVOTE);
        vm.warp(block.timestamp + 1 days);

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsMinerToken();
        assertEq(yes, user.balance + 1);
        assertEq(yes2, 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteYes2MinerToken() public {
        address user = users[0];

        registerVotePersonalMiner(user, YES2VOTE);
        vm.warp(block.timestamp + 1 days);

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsMinerToken();
        assertEq(yes, 1);
        assertEq(yes2, user.balance + 1);
        assertEq(no, 1);
        assertEq(abstain, 1);
    }

    function testVoteNoMinerToken() public {
        address user = users[0];

        registerVotePersonalMiner(user, NOVOTE);
        vm.warp(block.timestamp + 1 days);

        (uint256 yes, uint256 yes2, uint256 no, uint256 abstain) = tracker.getVoteResultsMinerToken();
        assertEq(yes, 1);
        assertEq(yes2, 1);
        assertEq(no, user.balance + 1);
        assertEq(abstain, 1);
    }

    function testYesWinningVote() public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, YESVOTE);
        registerVotePersonalMiner(user2, YESVOTE);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.Yes);
    }

    function testYes2WinningVote() public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, YES2VOTE);
        registerVotePersonalMiner(user2, YES2VOTE);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.Yes2);
    }

    function testNoWinningVote() public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, NOVOTE);
        registerVotePersonalMiner(user2, NOVOTE);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.No);
    }

    function testAbstainWinningVote() public {
        address user = users[0];
        address user2 = users[1];

        registerVoteNormal(user, ABSTAINVOTE);
        registerVotePersonalMiner(user2, ABSTAINVOTE);
        vm.warp(block.timestamp + 1 days);

        VoteTracker.Vote winner = tracker.winningVote();

        assert(winner == VoteTracker.Vote.Abstain);
    }

    /****************************************************************/
    /*                           Helpers                            */
    /****************************************************************/

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

    function registerVotePersonalMiner(address user, uint256 vote) internal {
        registerPersonalMiner(user);

        vm.prank(user);
        tracker.castVote(vote);
    }

    function registerNormal(address user) internal {
        uint64[] memory minerIds = emptyMinerIds();
        register(address(0), minerIds, user);
    }

    function registerGlif(address user) internal {
        uint64[] memory minerIds = validMinerIds();
        register(GLIFPOOL, minerIds, user);
    }

    function registerPersonalMiner(address user) internal {
        uint64[] memory minerIds = new uint64[](1);
        minerIds[0] = 1889470;
        register(address(0), minerIds, user);
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

    function validMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](8);
        minerIds[0] = 1847752;
        minerIds[1] = 1858233;
        minerIds[2] = 1872812;
        minerIds[3] = 1882568;
        minerIds[4] = 1889911;
        minerIds[5] = 1909617;
        minerIds[6] = 1917538;
        minerIds[7] = 2251152;
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
        minerIds[0] = 184775100;
        minerIds[1] = 185823500;
        minerIds[2] = 187281100;
        minerIds[3] = 188256900;
        minerIds[4] = 188991000;
        minerIds[5] = 190961600;
        minerIds[6] = 191753900;
        minerIds[7] = 225115100;
        return minerIds;
    }

    function emptyMinerIds() internal pure returns (uint64[] memory) {
        uint64[] memory minerIds = new uint64[](0);
        return minerIds;
    }
}
