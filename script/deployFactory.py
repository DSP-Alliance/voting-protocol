#import web3 
from web3 import Web3

rpc = "https://api.node.glif.io"
calib = "https://api.calibration.node.glif.io/rpc/v1"

w3 = Web3(Web3.HTTPProvider(rpc))

myAddr = "0x3304a183aE4353CE57f062bcacc1CB2eDED5Ff2b"
factory = "0xf109f754cdea239d2811d1f285471e0dc25d918e"

bytecode = "0x3c056dbe"
fip = "0"
fip = hex(int(fip, 16))
# pad to 32 bytes
fip = fip[2:].zfill(64)
#bytecode += fip
print(bytecode)

tx = {
    "to": w3.to_checksum_address(factory),
    "data": bytecode,
    "chainId": 314,
}

result = w3.eth.call(tx)


print(result.hex())
# 0x453815c00000000000000000000000000000000000000000000000000000000000000012