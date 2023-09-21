#import web3 
from web3 import Web3
import json

rpc = "https://api.node.glif.io"

w3 = Web3(Web3.HTTPProvider(rpc))

pk = input("Enter your private key: ")

myAddr = w3.eth.account.from_key(pk).address

# open the file ./out-fevm/VoteFactory.sol/VoteFactory.json
with open("./out-fevm/VoteFactory.sol/VoteFactory.json") as f:
    # parse the json
    contract_json = json.load(f)
    bytecode = contract_json["deployedBytecode"]["object"]

nonce = w3.eth.get_transaction_count(myAddr)

tx = {
    "data": bytecode,
    "gas": 10000000000,
    "chainId": 314,
    "nonce": nonce,
    "maxFeePerGas": w3.to_wei('100', 'gwei'),
    "maxPriorityFeePerGas": w3.to_wei('1', 'gwei'),
}

signed = w3.eth.account.sign_transaction(tx, pk)
hash = w3.eth.send_raw_transaction(signed.rawTransaction)
print(hash.hex())
w3.eth.wait_for_transaction_receipt(hash)
print("confirmed")


