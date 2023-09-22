# Filecoin Voting Protocol

## Registration

To be able to cast votes a user must first register with the registration function.

```C
function registerVoter(address glifpool, uint64[] calldata minerIds) public returns (uint256 powerRBP, uint256 powerToken)
```

To register with a glif pool, supply your glif pool agent address and the minerIds that the glifpool owns. To register your glif pool you must be the owner() of the glif pool and the glif pool address must be an agent registered from the glif pool agent factory. If you are not the owner or it is not from the factory and the glifpool address is not the zero address then this function will revert.

To register a personal miner, register from a controlling address of your miners. Supply every minerId. Your address that you register from must be a controlling address for every miner, or it will not register the raw byte power (RBP) for that miner.

Vote weights are set after registering and to prevent misconduct re-registering is prevented.

## Weights

There are three different weight categories. Raw byte power, miner's tokens, normal user's tokens. RBP is weighed against RBP and tokens are weighed against tokens. 

There is seperation between miner tokens and normal user tokens, however this is just to differentiate between opinions of miners and all else.

## Vote casting

After a user has registered then they can cast a vote. There are three voting choices

1. Yes
2. No
3. Abstain
4. Yes Option 2 (Optional)

By default there are three different voting choices. If the variable `doubleYesVote` is set in the vote tracker then there is a fourth voting option represented as two different types of yes options.

Users cannot vote twice.

## Results

After the voting period is over, no more votes can be cast and 4 new functions are exposed to retrieve the votes.

```C
function getVoteResultsRBP() public view returns (uint256, uint256, uint256, uint256)
```

This function returns the weights voted by raw byte power as yes, yes option 2, no, and abstain votes respectively

```C
function getVoteResultsMinerToken() public view returns (uint256, uint256, uint256, uint256)
```

This function returns the weights voted by miner tokens as yes, yes option 2, no, and abstain votes respectively

```C
function getVoteResultsToken() public view returns (uint256, uint256, uint256, uint256)
```

This function returns the weights voted by normal user tokens as yes, yes option 2, no, and abstain votes respectively

```C
function winningVote() public view returns (Vote)
```

This function is what determines what was the winning vote. `Vote` is an enum where when converting from an integer, 0 is Yes, 1 is No, 2 is abstain, and 3 is Yes option 2

Miner tokens and normal user token voting weights are added together then compared against the RBP consensus. So we have two categories of voting to decide with, RBP and tokens.

If RBP and tokens vote yes, pass
If RBP is yes, and tokens is no, don't pass
If RBP is no, and tokens is yes, don't pass
If RBP is no, and tokens is no, don't pass
