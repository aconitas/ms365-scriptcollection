import base64

base64_seed = ""

decoded_seed = base64.b64decode(base64_seed)
base32_seed = base64.b32encode(decoded_seed).decode('utf-8')

print(f"Seed in Base32: {base32_seed}")