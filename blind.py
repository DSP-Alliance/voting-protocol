from Crypto.Util.number import bytes_to_long, long_to_bytes, inverse, getRandomRange
from Crypto.Hash import SHA256
from Crypto.PublicKey import RSA

# Key generation
key = RSA.generate(2048)  # generate RSA key pair
public_key = key.publickey()  # extract public key

#print("Public key (n, e):", (public_key.n, public_key.e))
#print("Private key (n, d):", (key.n, key.d))

# The message to be signed
message = b'This is a test message.'

# Hash the message
hash_obj = SHA256.new(message)
hashed_message = bytes_to_long(hash_obj.digest())

# Step 2: Blinding
r = getRandomRange(2, public_key.n - 1)  # a random number between 2 and n-1
blinded_message = (hashed_message * pow(r, public_key.e, public_key.n)) % public_key.n
print("Blinded message:", hex(blinded_message))

# Step 3: Signing
blinded_signature = pow(blinded_message, key.d, key.n)
print("Blinded signature:", hex(blinded_signature))

# Step 4: Unblinding
signature = (blinded_signature * inverse(r, public_key.n)) % public_key.n
print("Signature:", hex(signature))

# Step 5: Verification
verified_message = pow(signature, public_key.e, public_key.n)
print("Verified message:", hex(verified_message))

# Check if the verified message matches the original hashed message
if verified_message == hashed_message:
    print("The signature is valid.")
else:
    print("The signature is NOT valid.")
