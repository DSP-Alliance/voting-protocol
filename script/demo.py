from web3 import Web3
from Crypto.Util.number import getRandomRange

rpc = "https://api.calibration.node.glif.io/rpc/v1"

# get provider
w3 = Web3(Web3.HTTPProvider(rpc))

pk = "9fae980ce85d8ce2a813552436fa86c8fe5f7fe3641c345e5d6ff8f309535817"
# get the public key
myAddr = "0x1a260b2FbccDF49A27dbF15881dDD7172e936CA7"
contract = "0xA6fF8b75c8e068d74a279DbacBcFaf4827272d1f"
print("Contract address: ", contract)
print("Network: Calibration (314159)")

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

# Get contract bytecode
bytecode = w3.eth.get_code(contract)
print("Contract bytecode: ", bytecode.hex())
input()

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
print("Vote transaction hash: ", hash.hex())
w3.eth.wait_for_transaction_receipt(hash)
print("Transaction confirmed")

# get the vote results
data = getVoteResultsSig

tx = {
    "to": w3.toChecksumAddress(contract),
    "data": data,
}
print("Getting vote results...")
try:
    result = w3.eth.call(tx)
except Exception as e:
    print("Error getting vote results: ", e)
    print("Vote results are not available until the vote is over")

print("")