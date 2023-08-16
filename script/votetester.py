#import web3 
from web3 import Web3

rpc = "https://api.node.glif.io"
calib = "https://api.calibration.node.glif.io/rpc/v1"

w3 = Web3(Web3.HTTPProvider(calib))

myAddr = "0x3304a183aE4353CE57f062bcacc1CB2eDED5Ff2b"
import os
pk = os.environ.get('PRIVATE_KEY')

tester = "0x15fb69e2f7eecf117eb859e16b32e4e411865a36"

def resolveEthAddress(address):
    # pad address to 32 bytes

    # pad to 32 bytes
    paddAddr = address[2:].zfill(64)

    return "0xee3e36fc" + paddAddr

def lookupDelegatedAddress(actorId):
    # actorId is an integer, convert it to hex
    hexId = hex(actorId)[2:].zfill(64)

    return "0xff0d65a1" + hexId

def minerPower(minerId):
    # minerId is an integer, convert it to hex
    hexId = hex(minerId)[2:].zfill(64)

    return "0x96c9ed20" + hexId

def controllingAddress():
    minerhex = hex(1491)[2:].zfill(64)

    return "0x7e7963bf" + minerhex + "0000000000000000000000000000000000000000000000000000000000000040" + "0000000000000000000000000000000000000000000000000000000000000016" + "040a35bae6df0e62ad86eb53c8683812dc332a5ffbc400000000000000000000"

data = resolveEthAddress(myAddr)
print("Resolve Eth Address")
print(data)

tx = {
    "to": w3.toChecksumAddress(tester),
    "data": data,
}

result = w3.eth.call(tx)

#convert result into an integer
myId = int(result.hex(), 16)
print(myId)

data = lookupDelegatedAddress(18209)
print("Lookup Delegated Address")
print(data)

tx = {
    "to": w3.toChecksumAddress(tester),
    "data": data,
}

result = w3.eth.call(tx)

print(result.hex())

data = minerPower(1037)
print("Miner Power")
print(data)

tx = {
    "to": w3.toChecksumAddress(tester),
    "data": data,
}

result = w3.eth.call(tx)
print(result.hex())

data = controllingAddress()
print("Controlling Address")
print(data)

tx = {
    "to": w3.toChecksumAddress(tester),
    "data": data,
}

result = w3.eth.call(tx)
print(result.hex())

# 0x
# 
# 0000000000000000000000000000000000000000000000000000000000000016
# 040a3304a183ae4353ce57f062bcacc1cb2eded5ff2b00000000000000000000
