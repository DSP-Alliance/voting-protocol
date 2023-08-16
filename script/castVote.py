#import web3 
from web3 import Web3

rpc = "https://api.node.glif.io"
calib = "https://api.calibration.node.glif.io/rpc/v1"

w3 = Web3(Web3.HTTPProvider(rpc))

myAddr = "0x3304a183aE4353CE57f062bcacc1CB2eDED5Ff2b"
import os
pk = input("Enter private key: ")

votetracker = "0xA6fF8b75c8e068d74a279DbacBcFaf4827272d1f"

castVoteSig = "0x3eb76b9c"

# yes
vote = 3

# encode length into hex
voteHex = hex(vote)
# pad to 32 bytes
voteHex = voteHex[2:].zfill(64)


# concatenate all hex values
data = castVoteSig + voteHex

nonce = w3.eth.get_transaction_count(myAddr)
tx = {
    "to": w3.toChecksumAddress(votetracker),
    "data": data,
    "gas": 10000000,
    "maxFeePerGas": w3.toWei('100', 'gwei'),
    "maxPriorityFeePerGas": w3.toWei('1', 'gwei'),
    "chainId": 314,
    "nonce": nonce,
}

signed = w3.eth.account.sign_transaction(tx, pk)
hash = w3.eth.send_raw_transaction(signed.rawTransaction)
print(hash.hex())
w3.eth.wait_for_transaction_receipt(hash)
print("confirmed")
# sign transaction


# # make a static call to resolve address
# resolve_address_call = w3.eth.call({
#     'to': factory,
#     'data': '0x040a61C527C83DF001F991C18765A058A178CC5A3A7E'
# })

