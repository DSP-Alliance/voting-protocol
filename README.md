# Filecoin Voting Protocol

## Registration

To be able to cast votes a user must first register with the registration function.

```C
function registerVoter(CommonTypes.FilActorId miner) public returns (uint256 power)
```

If you are not a miner then you should pass a zero as the actor Id. If you are a miner then pass your miner Id from a controlling address (owner, worker). The contract will verify that you indeed control that miner.

## Weights

Each voter is assigned a weight to their votes to ensure people with more stake in the protocol get an appropriate amount of power.

1. Miners - Weight proportional to the amount of raw byte power supplied to the network

2. Non-miners - A weight of 10 (subject to change) or the equivalent of 10 bytes of raw byte power

## Vote casting

After a user has registered then they can cast a vote. There are three voting choices

1. Yes
2. No
3. Abstain

To encode your vote you can submit any 256 bit unsigned integer. To determine the vote modulo 3 is taken of the number. So yes would be 0, no would be 1, abstain would be 2, yes would be 3, and so on.

Users cannot vote twice.

## Results

After the voting period is over, no more votes can be cast and a new function is exposed to retrieve the votes.

```C
function getVoteResults() public view returns (uint256, uint256, uint256)
```

The numbers returned are the weighted amounts of yes, no, and abstain respectively.

## Demo

![Demo Video](./assets/demo.gif)

## Not Working

Currently the testing for the tracker fails in some aspects that involves Filecoin's address look up precompiles, the Miner API, and Power API from [filecoin solidity](https://github.com/filecoin-project/filecoin-solidity).

This is used to verify that a supplied miner Id is controlled by the vote registration transaction sender.

The API modules are also currently not working, which is used for looking up a miner's raw byte power supplied to the network.

```C
function isMiner(uint64 minerId, address sender) internal view returns (bool)
```

This should return a proper true/false when determining if ``sender`` is a controlling address for ``minerId``

Embedded in this function is some calls to precompiles for address lookups which are returning null bytes, even on valid Id's.

```C
function voterPower(uint64 minerId, address voter) internal view returns (uint256 power)
```

This function should return the miner's raw byte power or 10 if the minerId is 0.

Instead of proper byte power being returned the values returned are zero even for minerId's which have storage allocated to the network.
