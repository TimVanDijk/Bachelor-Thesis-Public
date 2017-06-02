import random
import operator as op

#This is a modified version of BaseKing.
#This version uses 32-bit words, which allows for a more efficient implementation on an ARM architecture.
#Joan Daemen provided the adjusted rotation constants.

ROUND_CONSTANTS_TEMPLATE = [0, 0, -1, -1, 0, 0, 0, 0, -1, -1, 0, 0] #The -1's are later replaced with the round constant.
ROUND_CONSTANTS = [11, 22, 44, 88, 176, 113, 226, 213, 187, 103, 206, 141] #Precomputed.
ROTATION_CONSTANTS = [0, 1, 3, 6, 10, 15, 21, 28, 4, 13, 23, 2]
DIFFUSION_CONSTANTS = [0, 2, 6, 7, 9, 10, 11]

ROUNDS = 11 #BaseKing is designed to have 11 rounds and one final output transformation.
MAX_BITS = 32 #Each word is 32 bits.
MASK = 2**MAX_BITS-1 #The maximum value each word can have (= all ones).

#Circular rotate left.
def rol(val, r_bits=1):
	return (val << r_bits%MAX_BITS) & MASK | (val & MASK) >> (MAX_BITS - (r_bits%MAX_BITS))

#Circular rotate right.
def ror(val, r_bits=1):
	return ((val & MASK) >> r_bits%MAX_BITS) | (val << (MAX_BITS - (r_bits%MAX_BITS)) & MASK)

#Add cipher key and round constant to the state.
def key_addition(mode, block, key, r):
	if mode == 'enc':
		return [block[i] ^ key[i] ^ [v if v != -1 else ROUND_CONSTANTS[r] for v in ROUND_CONSTANTS_TEMPLATE][i] for i in range(len(block))]
	if mode == 'dec':
		return [block[i] ^ key[i] ^ diffusion(([v if v != -1 else ROUND_CONSTANTS[ROUNDS-r] for v in ROUND_CONSTANTS_TEMPLATE])[::-1])[i] for i in range(len(block))]
	
#Transform the words with a linear transformation of high diffusion (branch number 8).
def diffusion(block):
	return [reduce(op.xor, [block[(i+offset)%len(block)] for offset in DIFFUSION_CONSTANTS]) for i in range(len(block))]

#Shift each 16-bit word in the state the amount of bits specified in ROTATION_CONSTANTS to the left.
def early_shift(block):
	return [rol(a, ROTATION_CONSTANTS[i]) for i, a in enumerate(block)]

#Nonlinear transformation of words.
def s_box(block):
	return [block[i] ^ (block[(i+4)%len(block)] | ~block[(i+8)%len(block)]) for i in range(len(block))]

#Shift each word in the state the amount of bits specified in ROTATION_CONSTANTS to the right.
def late_shift(block):
	return [ror(a, ROTATION_CONSTANTS[ROUNDS-i]) for i, a in enumerate(block)]

#Encrypts the block with the key if mode is 'enc'. Decrypts instead if mode is 'dec'.
def baseking(block, key, mode):
	#BaseKing has 11 rounds...
	for r in range(ROUNDS):
		block = key_addition(mode, block, key, r)
		block = diffusion(block)
		block = early_shift(block)
		block = s_box(block)
		block = late_shift(block)
	#... and 1 final output transformation.
	block = key_addition(mode, block, key, ROUNDS)
	block = diffusion(block)
	block = block[::-1] #Invert the order of the words.
	return block

#Wrapper that uses baseking to encrypt the block with the key.
def baseking_encrypt(block, key):
	#No further preparations are necessary.
	return baseking(block, key, 'enc')

#Wrapper that uses baseking to decrypt the block with the key.
def baseking_decrypt(block, key):
	#Compute the inverse key first.
	key = diffusion(key)
	key = key[::-1]
	return baseking(block, key, 'dec')

def main():
	formatter = "{:08x}".format #Print as hex.

	key = [random.randint(0, MASK) for i in range(12)] #Generate random 384-bits key split in parts of 32 bits.
	block = [random.randint(0, MASK) for i in range(12)] # Generate random 384-bits plaintext split in parts of 32 bits.
	print("Key:\t\t{}\nPlaintext:\t{}".format(map(formatter, key), map(formatter, block)))

	ciphertext = baseking_encrypt(block, key)
	print("Ciphertext:\t{}".format(map(formatter, ciphertext)))

	decrypted = baseking_decrypt(ciphertext, key)
	print("Decrypted:\t{}".format(map(formatter, decrypted)))

if __name__ == "__main__":
	main()