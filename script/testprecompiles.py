#import web3 
from web3 import Web3

rpc = "https://api.node.glif.io"

w3 = Web3(Web3.HTTPProvider(rpc))

resolve_address = "0xFE00000000000000000000000000000000000001"
lookup_delegated = "0xfE00000000000000000000000000000000000002"

# make a static call to resolve address
resolve_address_call = w3.eth.call({
    'to': resolve_address,
    'data': '0x040a61C527C83DF001F991C18765A058A178CC5A3A7E'
})

print("Resolve address call: ", resolve_address_call)

# make a static call to lookup delegated

lookup_delegated_call = w3.eth.call({
    'to': lookup_delegated,
    'data': '0x215441'
})

print("Lookup delegated call: ", lookup_delegated_call)

# 0x61C527C83DF001F991C18765A058A178CC5A3A7E
# f410fmhcspsb56aa7teobq5s2awfbpdgfuot6zngijra
# f02361681 