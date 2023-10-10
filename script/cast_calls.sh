## Deploy factory
FOUNDRY_PROFILE=fevm forge create src/VoteFactory.sol:VoteFactory --rpc-url filecoin -i

## Add to starters
cast send --rpc-url filecoin -i "0x69f1Da01E8BbCc75403040af0971c31600cb3E36" "addStarter(address)" "0x8c0D6D6975a5D63c7996c3d668b654e33FE9Ad14"

## Check if an address is a starter
cast call --rpc-url filecoin "0x677C8c333cc0989fdBfcAD51f0f0588d240635a8" "starters(address) returns (bool)" "0x8c0D6D6975a5D63c7996c3d668b654e33FE9Ad14"

## Get VoteTracker address from index
cast call --rpc-url filecoin "0x677C8c333cc0989fdBfcAD51f0f0588d240635a8" "deployedVotes(uint256) returns (address)" "0"