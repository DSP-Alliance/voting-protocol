#import web3 
from web3 import Web3

rpc = "https://api.node.glif.io"
calib = "https://api.calibration.node.glif.io/rpc/v1"

w3 = Web3(Web3.HTTPProvider(calib))

myAddr = "0x3304a183aE4353CE57f062bcacc1CB2eDED5Ff2b"
pk = "58c54560eacbc4b3ee136767b100ee55bede3396e619caa164ba4c71182ee4fc"

factory = "0x46d3f7d2ea08f0114a2f3c50b6ad0fe0c8e3cdf2"

startVoteSig = "0x13657cc8"

length = 1800
fipNum = 30
doubleYesBool = False

# encode length into hex
lengthHex = hex(length)
# pad to 32 bytes
lengthHex = lengthHex[2:].zfill(64)

# encode fipNum into hex
fipNumHex = hex(fipNum)
# pad to 32 bytes
fipNumHex = fipNumHex[2:].zfill(64)

# encode doubleYesBool into hex
doubleYesBoolHex = hex(doubleYesBool)
# pad to 32 bytes
doubleYesBoolHex = doubleYesBoolHex[2:].zfill(64)

# concatenate all hex values
data = startVoteSig + lengthHex + fipNumHex + doubleYesBoolHex

nonce = w3.eth.get_transaction_count(myAddr)
tx = {
    "to": w3.toChecksumAddress(factory),
    "data": data,
    "gas": 100000000,
    "maxFeePerGas": w3.toWei('100', 'gwei'),
    "maxPriorityFeePerGas": w3.toWei('1', 'gwei'),
    "chainId": 314159,
    "nonce": nonce,
}

signed = w3.eth.account.sign_transaction(tx, pk)
hash = w3.eth.send_raw_transaction(signed.rawTransaction)
print(hash.hex())
w3.eth.wait_for_transaction_receipt(hash)
print("confirmed")