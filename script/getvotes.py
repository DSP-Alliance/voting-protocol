from web3 import Web3
from Crypto.Util.number import getRandomRange

rpc = "https://api.calibration.node.glif.io/rpc/v1"

# get provider
w3 = Web3(Web3.HTTPProvider(rpc))

contract = "0xA6fF8b75c8e068d74a279DbacBcFaf4827272d1f"

getVoteResultsSig = "0x86a66dc3"

# get the vote results
data = getVoteResultsSig

tx = {
    "to": w3.toChecksumAddress(contract),
    "data": data,
}
result = w3.eth.call(tx)
print("Vote results: ", result.hex())
