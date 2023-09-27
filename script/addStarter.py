from web3 import Web3
import os
from dotenv import load_dotenv

dotenv_path = ".env"
load_dotenv(dotenv_path)

rpc = "https://api.node.glif.io"

w3 = Web3(Web3.HTTPProvider(rpc))

pk = os.environ.get("PRIVATE_KEY")

myAddr = w3.eth.account.from_key(pk).address

factory = "0x5f1917aa186d1b28015692ae1ee7f2b6ba788edd"

starters = []
startersSig = "0x446a8ba2"

i = 0
while True:

    data = startersSig + str(i).zfill(64)
    print(data)
    tx = {
        "to": w3.to_checksum_address(factory),
        "data": data,
    }
    try:
        result = w3.eth.call(tx)
        #print(result.hex())
        # remove the first 12 bytes from result
        result = "0x" + result.hex()[26:]
        starters.append(result)
        i += 1
    except:
        #print("Done")
        break

print("Starters: ")
print(starters)

nonce = w3.eth.get_transaction_count(myAddr)

addStarterSig = "0x207a62c8"
address = input("Address: ")
data = addStarterSig + address[2:].zfill(64)

tx = {
    "to": w3.to_checksum_address(factory),
    "data": data,
    "gas": 10000000,
    "chainId": 314,
    "nonce": nonce,
    "maxFeePerGas": w3.to_wei('100', 'gwei'),
    "maxPriorityFeePerGas": w3.to_wei('1', 'gwei'),
}

print(tx)
print()

input("Confirm?")

signed = w3.eth.account.sign_transaction(tx, pk)
hash = w3.eth.send_raw_transaction(signed.rawTransaction)
print(hash.hex())
w3.eth.wait_for_transaction_receipt(hash)
print("confirmed")

