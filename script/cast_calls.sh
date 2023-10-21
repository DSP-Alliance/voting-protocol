## Deploy factory
FOUNDRY_PROFILE=fevm forge create src/VoteFactory.sol:VoteFactory --rpc-url filecoin -i

## Add to starters
cast send --rpc-url filecoin -i "0x671FEF3C5b7c7564536583d53942f71F11185DD4" "addStarter(address)" "0xBa93D5Db0ACA723008D6BA0008dd3E659289cE7e"

## Check if an address is a starter
cast call --rpc-url filecoin "0xD485131d659dFaE1D8B3aEc8d28aDff8D178B0E0" "starters(address) returns (bool)" "0x238BaA9a12Ea1B604440C9e7dDE8B8AEE0Ba2203"

## See associated data with registered address
cast call --rpc-url filecoin "0xD485131d659dFaE1D8B3aEc8d28aDff8D178B0E0" "registered(address voter) external view returns (bool)" "0x674Aaf6777D9783accdF9DBb45cbFe87E308Fc73"
cast call --rpc-url filecoin "0xD485131d659dFaE1D8B3aEc8d28aDff8D178B0E0" "ownedGlifPool(address voter) external view returns (address)" "0x674Aaf6777D9783accdF9DBb45cbFe87E308Fc73"
cast call --rpc-url filecoin "0xD485131d659dFaE1D8B3aEc8d28aDff8D178B0E0" "getOwnedMinerLength(address owner) external view returns (uint256 length)" "0x674Aaf6777D9783accdF9DBb45cbFe87E308Fc73"
cast call --rpc-url filecoin "0xD485131d659dFaE1D8B3aEc8d28aDff8D178B0E0" "ownedMiners(address voter, uint256 index) external view returns (uint64)" "0x674Aaf6777D9783accdF9DBb45cbFe87E308Fc73" "0"

## Get VoteTracker address from index
cast call --rpc-url filecoin "0x671FEF3C5b7c7564536583d53942f71F11185DD4" "deployedVotes(uint256) returns (address)" "0"

## Get voting power for an address
cast call --rpc-url filecoin "0xe2d3F369AE39614806E8a433d001e3f09c9a9591" "getVotingPower(address voter) public view returns (uint256 tokenPower, uint256 bytePower, uint256 minerTokenPower)" "0x4a2144Cb109b6aa439e7Eb370fCC8fE9E50A21f8"
