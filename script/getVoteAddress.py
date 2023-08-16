#import web3 
from web3 import Web3

rpc = "https://api.node.glif.io"
calib = "https://api.calibration.node.glif.io/rpc/v1"

w3 = Web3(Web3.HTTPProvider(calib))

myAddr = "0x3304a183aE4353CE57f062bcacc1CB2eDED5Ff2b"
import os
pk = os.environ.get('PRIVATE_KEY')

factory = "0xe60e7f575b48f1ca6f3ca7d3f0848066fca87958"

startVoteSig     = "0x453815c0"
deployedVotesSig = "0x3c056dbe"

fipNum = int(input("Enter FIP number: "))
# encode fipNum into hex
fipNumHex = hex(fipNum)
# pad to 32 bytes
fipNumHex = fipNumHex[2:].zfill(64)

# concatenate all hex values
data = startVoteSig + fipNumHex

nonce = w3.eth.get_transaction_count(myAddr)
tx = {
    "to": w3.toChecksumAddress(factory),
    "data": data,
}

result = w3.eth.call(tx)
print(result.hex())

tx = {
    "to": w3.toChecksumAddress(factory),
    "data": deployedVotesSig,
}

result = w3.eth.call(tx)
print(result.hex())
# sign transaction


# # make a static call to resolve address
# resolve_address_call = w3.eth.call({
#     'to': factory,
#     'data': '0x040a61C527C83DF001F991C18765A058A178CC5A3A7E'
# })

