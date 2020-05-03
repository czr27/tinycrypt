Designers	Helena Handschuh, David Naccache
Derived from	SHA-1, SHA-256
Related to	Crab
Certification	NESSIE (SHACAL-2)
Cipher detail
Key sizes	128 to 512 bits
Block sizes	160 bits (SHACAL-1),
256 bits (SHACAL-2)
Structure	Cryptographic hash function

in:
Block ciphers	
SHACAL
Edit
Share

Template:About Template:Infobox block cipher

In cryptography, SHACAL-1 and SHACAL-2 are block ciphers based on the SHA-1 and SHA-2 cryptographic hash functions respectively. They were designed by Helena Handschuh and David Naccache of the smart card manufacturer Gemplus.

SHACAL-1 (originally simply SHACAL) is a 160-bit block cipher based on SHA-1, and supports keys from 128-bit to 512-bit. SHACAL-2 is a 256-bit block cipher based upon the larger hash function SHA-256.

Both SHACAL-1 and SHACAL-2 were selected for the second phase of the NESSIE project. However, in 2003, SHACAL-1 was not recommended for the NESSIE portfolio because of concerns about its key schedule, while SHACAL-2 was finally selected as one of the 17 NESSIE finalists. Rounds	80

HACAL-1 is based on the following observation of SHA-1:

The hash function SHA-1 is designed around a compression function. This function takes as input a 160-bit state and a 512-bit data word and outputs a new 160-bit state after 80 rounds. The hash function works by repeatedly calling this compression function with successive 512-bit data blocks and each time updating the state accordingly. This compression function is easily invertible if the data block is known, i.e. given the data block on which it acted and the output of the compression function, one can compute that state that went in.

SHACAL-1 turns the SHA-1 compression function into a block cipher by using the state input as the data block and using the data input as the key input. In other words SHACAL-1 views the SHA-1 compression function as an 80-round, 160-bit block cipher with a 512-bit key. Keys shorter than 512 bits are supported by padding them with zero up to 512. SHACAL-1 is not intended to be used with keys shorter than 128-bit. 
