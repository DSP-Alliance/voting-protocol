from web3 import Web3
from Crypto.Util.number import getRandomRange

rpc = "https://api.calibration.node.glif.io/rpc/v1"

# get provider
w3 = Web3(Web3.HTTPProvider(rpc))

contract = "0xA6fF8b75c8e068d74a279DbacBcFaf4827272d1f"

castVoteSig = "0x3eb76b9c"
getVoteResultsSig = "0x86a66dc3"

# prompt user for vote
votechoice = input("Enter your vote (yes/no/abstain): ")

# generate a random 256 bit number
num = getRandomRange(2**255, 2**256)
mod = num % 3

if votechoice == "yes":
    adjusted = 3 - mod
elif votechoice == "no":
    adjusted = 1 - mod
elif votechoice == "abstain":
    adjusted = 2 - mod

vote = adjusted + num

print("Encoded vote: ", hex(vote))

data = castVoteSig + hex(vote)[2:].zfill(64)
print("Data: ", data)

pk = "58c54560eacbc4b3ee136767b100ee55bede3396e619caa164ba4c71182ee4fc"
# get the public key
myAddr = "0x3304a183aE4353CE57f062bcacc1CB2eDED5Ff2b"

# make the transaction
nonce = w3.eth.get_transaction_count(myAddr)
gasPrice = w3.toWei(4, 'gwei')

tx = {
    "to": w3.toChecksumAddress(contract),
    "data": data,
    "nonce": nonce,
    "chainId": 314159,
    "maxFeePerGas": gasPrice,
    "maxPriorityFeePerGas": gasPrice,
    "gas": 100000000,
}
signed = w3.eth.account.sign_transaction(tx, pk)
hash = w3.eth.send_raw_transaction(signed.rawTransaction)
w3.eth.wait_for_transaction_receipt(hash)
print("voted at ", hash.hex())

# get the vote results
data = getVoteResultsSig

tx = {
    "to": w3.toChecksumAddress(contract),
    "data": data,
}
result = w3.eth.call(tx)
print("Vote results: ", result.hex())
