/*
        Simple example showing AES-256 encryption & decryption of AS-REQ timestamp in Kerberos v5
        
        to get "valid checksum" result, supply domain of "AD.CORP.COM", username of "Administrator"
        and password of "Password1234"
        
            - All input is case sensitive
        
        compile: g++ krb_aes.cpp -okrb_aes -lcrypto
        
        See the following RFC for more details about the crypto & algorithms used:
        
            RFC3961 - Encryption and Checksum Specifications for Kerberos 5
            RFC3962 - Advanced Encryption Standard (AES) Encryption for Kerberos 5
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <openssl/aes.h>
#include <openssl/sha.h>

#define MIN(X, Y)  ((X) < (Y) ? (X) : (Y))

/*
n-fold(k-bits):
  l = lcm(n,k)
  r = l/k
  s = k-bits | k-bits rot 13 | k-bits rot 13*2 | ... | k-bits rot 13*(r-1)
  compute the 1's complement sum:
	n-fold = s[0..n-1]+s[n..2n-1]+s[2n..3n-1]+..+s[(k-1)*n..k*n-1]
*/

/* representation: msb first, assume n and k are multiples of 8, and
   that k>=16.  this is the case of all the cryptosystems which are
   likely to be used.  this function can be replaced if that
   assumption ever fails.  */

/* input length is in bits */

void
nfold(unsigned int inbits, const unsigned char *in, 
    unsigned int outbits,unsigned char *out)
{
    int a,b,c,lcm;
    int byte, i, msbit;

    /* the code below is more readable if I make these bytes
       instead of bits */

    inbits >>= 3;
    outbits >>= 3;

    /* first compute lcm(n,k) */

    a = outbits;
    b = inbits;

    while (b != 0) {
        c = b;
        b = a % b;
        a = c;
    }

    lcm = outbits*inbits/a;

    /* now do the real work */

    memset(out, 0, outbits);
    byte = 0;

    /* this will end up cycling through k lcm(k,n)/k times, which
       is correct */
    for (i = lcm - 1; i >= 0; i--) {
        /* compute the msbit in k which gets added into this byte */
        msbit = (/* first, start with the msbit in the first, unrotated byte */
		((inbits << 3) - 1)
		
        /* then, for each byte, shift to the right for each
		    repetition */
		 +(((inbits << 3) + 13) * (i / inbits))
		 /* last, pick out the correct byte within that
		    shifted repetition */
		 +((inbits - (i % inbits)) << 3)
		 ) % (inbits << 3);

        /* pull out the byte value itself */
        byte += (((in[((inbits  - 1) - (msbit >> 3)) % inbits] << 8)|
		  (in[((inbits) - (msbit>>3)) % inbits]))
		 >>((msbit & 7) + 1)) & 0xff;

        /* do the addition */
        byte += out[i % outbits];
        out[i % outbits] = byte & 0xff;

        /* keep around the carry bit, if any */
        byte >>= 8;
    }

    /* if there's a carry bit left over, add it back in */
    if (byte) {
        
        for (i = outbits - 1; i >= 0; i--) {
            /* do the addition */
            byte += out[i];
            out[i] = byte & 0xff;

            /* keep around the carry bit, if any */
            byte >>= 8;
        }
    }
}

void
hmac_sha1(unsigned char text[], size_t text_len, unsigned char key[],
    size_t key_len, unsigned char digest[SHA1_DIGEST_LENGTH])
{
	SHA_CTX ctx;
	unsigned char k_ipad[SHA1_BLOCK_LENGTH],k_opad[SHA1_BLOCK_LENGTH];
	unsigned char tk[SHA1_DIGEST_LENGTH];

	if (key_len > SHA1_BLOCK_LENGTH) {
		SHA1_Init(&ctx);
		SHA1_Update(&ctx, key, key_len);
		SHA1_Final(tk, &ctx);

		key = tk;
		key_len = SHA1_DIGEST_LENGTH;
	}

    memset(k_ipad,0x36,sizeof(k_ipad));
    memset(k_opad,0x5c,sizeof(k_opad));
    
	for(size_t i(0);i < key_len;i++)
    {
		k_ipad[i] ^= key[i];
        k_opad[i] ^= key[i];
    }
    
	SHA1_Init(&ctx);
	SHA1_Update(&ctx, k_ipad, SHA1_BLOCK_LENGTH);
	SHA1_Update(&ctx, text, text_len);
	SHA1_Final(digest, &ctx);

	SHA1_Init(&ctx);
	SHA1_Update(&ctx, k_opad, SHA1_BLOCK_LENGTH);
	SHA1_Update(&ctx, digest, SHA1_DIGEST_LENGTH);
	SHA1_Final(digest, &ctx);
}

/*
 * Password-Based Key Derivation Function 2 (PKCS #5 v2.0).
 * Code based on IEEE Std 802.11-2007, Annex H.4.2.
 */
int
pkcs5_pbkdf2(unsigned char pass[], size_t pass_len, unsigned char salt[], size_t salt_len,
    unsigned char key[], size_t key_len, size_t rounds)
{
	unsigned char *asalt, obuf[SHA_DIGEST_LENGTH];
	unsigned char d1[SHA_DIGEST_LENGTH], d2[SHA_DIGEST_LENGTH];
	size_t r;

	if ((asalt = (unsigned char*)malloc(salt_len + 4)) == NULL)
		return -1;

	memcpy(asalt, salt, salt_len);

	for (size_t count = 1; key_len > 0; count++) {
		
        asalt[salt_len + 0] = (count >> 24) & 0xff;
		asalt[salt_len + 1] = (count >> 16) & 0xff;
		asalt[salt_len + 2] = (count >> 8) & 0xff;
		asalt[salt_len + 3] = count & 0xff;

		hmac_sha1(asalt, salt_len + 4, pass, pass_len, d1);
		memcpy(obuf, d1, sizeof(obuf));

		for (unsigned int i = 1; i < rounds; i++) {
			hmac_sha1(d1, sizeof(d1), (unsigned char*)pass, pass_len, d2);
			memcpy(d1, d2, sizeof(d1));

			for (unsigned int j = 0; j < sizeof(obuf); j++)
				obuf[j] ^= d1[j];
		}

		r = MIN(key_len, SHA1_DIGEST_LENGTH);
		memcpy(key, obuf, r);
		key += r;
		key_len -= r;
	}
	free(asalt);

	return 0;
}

static void
AES_cts_encrypt(const unsigned char *in, unsigned char *out,
                     size_t len, const AES_KEY *key,
                     unsigned char *ivec, const int encryptp)
{
    unsigned char tmp[AES_BLOCK_SIZE];
    unsigned int i;

    if (encryptp) {

        while(len > AES_BLOCK_SIZE) {
            for (i = 0; i < AES_BLOCK_SIZE; i++)
                tmp[i] = in[i] ^ ivec[i];
                
            AES_encrypt(tmp, out, key);
            memcpy(ivec, out, AES_BLOCK_SIZE);
            len -= AES_BLOCK_SIZE;
            in += AES_BLOCK_SIZE;
            out += AES_BLOCK_SIZE;
        }

        for (i = 0; i < len; i++)
            tmp[i] = in[i] ^ ivec[i];
            
        for (; i < AES_BLOCK_SIZE; i++)
            tmp[i] = 0 ^ ivec[i];

       AES_encrypt(tmp, out - AES_BLOCK_SIZE, key);

       memcpy(out, ivec, len);
       memcpy(ivec, out - AES_BLOCK_SIZE, AES_BLOCK_SIZE);

    } else {
        unsigned char tmp2[AES_BLOCK_SIZE];
        unsigned char tmp3[AES_BLOCK_SIZE];

        while(len > AES_BLOCK_SIZE * 2) {
            memcpy(tmp, in, AES_BLOCK_SIZE);
            AES_decrypt(in, out, key);
            
            for (i = 0; i < AES_BLOCK_SIZE; i++)
               out[i] ^= ivec[i];
               
            memcpy(ivec, tmp, AES_BLOCK_SIZE);
            len -= AES_BLOCK_SIZE;
            in += AES_BLOCK_SIZE;
            out += AES_BLOCK_SIZE;
        }

        len -= AES_BLOCK_SIZE;

        memcpy(tmp, in, AES_BLOCK_SIZE); /* save last iv */
        AES_decrypt(in, tmp2, key);

        memcpy(tmp3, in + AES_BLOCK_SIZE, len);
        memcpy(tmp3 + len, tmp2 + len, AES_BLOCK_SIZE - len); /* xor 0 */

        for (i = 0; i < len; i++)
            out[i + AES_BLOCK_SIZE] = tmp2[i] ^ tmp3[i];

        AES_decrypt(tmp3, out, key);
        
        for (i = 0; i < AES_BLOCK_SIZE; i++)
            out[i] ^= ivec[i];
        memcpy(ivec, tmp, AES_BLOCK_SIZE);
    }
}

void dump_hex(char str[], unsigned char hex[], size_t len)
{
        printf("\n\n[%s]",str);
        
        for (size_t i(0);i < len;i++) {
            if (!(i % 16))
               printf("\n%08x: ",i);
               
            printf(" %02x",hex[i]);
        }
}

// keysize = 32 for 256 bits, 16 for 128 bits
void dk(unsigned char key_out[], unsigned char key_in[], 
    size_t key_size, unsigned char ptext[], size_t ptext_size)
{
    unsigned char iv[32];
    unsigned char plaintext[32];
    AES_KEY ekey;
    
    memset(iv,0,sizeof(iv));
    memset(plaintext,0,sizeof(plaintext));
    memcpy(plaintext,ptext,16);
    
    AES_set_encrypt_key(key_in,key_size*8,&ekey);
    AES_cbc_encrypt(plaintext,key_out,key_size,&ekey,iv,AES_ENCRYPT);
}

void krb_decrypt(const unsigned char ciphertext[], size_t ctext_size,
    unsigned char plaintext[], const unsigned char key[], size_t key_size)
{
    unsigned char iv[32];
    AES_KEY ekey;
    
    memset(iv,0,sizeof(iv));
    
    AES_set_decrypt_key(key,key_size*8,&ekey);   
    AES_cts_encrypt(ciphertext,plaintext,ctext_size,&ekey,iv,AES_DECRYPT);
}

void krb_encrypt(const unsigned char ciphertext[], size_t ctext_size,
    unsigned char plaintext[], const unsigned char key[], size_t key_size)
{
    unsigned char iv[32];
    AES_KEY ekey;
    
    memset(iv,0,sizeof(iv));
    
    AES_set_encrypt_key(key,key_size*8,&ekey);   
    AES_cts_encrypt(ciphertext,plaintext,ctext_size,&ekey,iv,AES_ENCRYPT);
}

// the following timestamp was captured with wireshark, Vista user authenticating with Windows 2008 controller
// Domain = AD.CORP.COM, username = Administrator, password = "Password1234"
// 256-bit AES, time is 10th of march, 2009
unsigned char pa_enc_timestamp[] = { 0x85,0x47,0xC1,0x77,0xCB,0x8E,0xB1,0xFD,0x80,0x7B,0x3A,0x3C,0x88,0x92,0x5C,0x0B,
                                     0xB0,0x28,0x80,0x56,0x6D,0x7A,0xD2,0x25,0x5A,0x3F,0x7D,0xC6,0x73,0x07,0x3C,0xE1,
                                     0x4B,0x9C,0x6E,0xEB,0x86,0x92,0xB4,0xBC,0x91,0x01,0x4E,0x3F };
                                    
// AES protocol uses 1st 96-bits of 160-bit HMAC-SHA1                                    
unsigned char ts_checksum[] = { 0xA8,0x58,0x43,0xC9,0x66,0x3B,0x59,0xC2,0xAC,0xB2,0x8F,0xBE };
                                     
int main(int argc, char* argv[])
{   
    string domain,username,password;
    
    if (argc != 4) {
        printf("\nUsage:%s <domain> <username> <password>\n",argv[0]);
        return 0;
    }
    
    domain   = argv[1];
    username = argv[2];
    password = argv[3];
    
    string salt = domain + username;
    
    /*
        tkey = random2key(PBKDF2(passphrase, salt, iter_count, keylength))
        key = DK(tkey, "kerberos")
    */
    
    unsigned char tkey[32];
    unsigned char base_key[32];
    unsigned char constant[16];
    string krb_str = "kerberos";
    
    pkcs5_pbkdf2((unsigned char*)password.c_str(),password.length(),
        (unsigned char*)salt.c_str(),salt.length(),tkey,32,4096);   
    dump_hex("PBKDF2 Key",tkey,32);
    
    // generate 128 bits from 40 bits of "kerberos" string
    nfold(krb_str.length()*8,(const unsigned char*)krb_str.c_str(),128,constant);   // precompute
    dk(base_key,tkey,32,constant,32);
    dump_hex("Base Key",base_key,32);
    
    /*
        The "well-known constant" used for the DK function is the key usage number, 
        expressed as four octets in big-endian order, followed by one octet indicated below.

        Kc = DK(base-key, usage | 0x99);
        Ke = DK(base-key, usage | 0xAA);
        Ki = DK(base-key, usage | 0x55);
    */
    
    unsigned char usage[5];
    unsigned char ke_input[16];
    unsigned char Ke[32];
    
    // derive Ke for decryption/encryption
    memset(usage,0,sizeof(usage));
    
    usage[3] = 0x01;        // key number in big-endian format
    usage[4] = 0xAA;        // used to derive Ke
    
    nfold(sizeof(usage)*8,usage,sizeof(ke_input)*8,ke_input);   // precompute
    dk(Ke,base_key,32,ke_input,32);
    dump_hex("Ke Key",Ke,32);    
    
    unsigned char plaintext[44];
    
    // decrypt the AS-REQ timestamp encrypted with 256-bit AES
    // here is enough to check the string, further computation below is required
    // to fully verify the checksum
    krb_decrypt(pa_enc_timestamp,44,plaintext,Ke,sizeof(Ke));
    dump_hex("Decrypted Timestamp",plaintext,44);
    
    // derive the checksum key
    unsigned char ki_input[16];
    unsigned char Ki[32];
    unsigned char checksum[20];
    
    // derive Ki used in HMAC-SHA-1 checksum
    memset(usage,0,sizeof(usage));
    
    usage[3] = 0x01;        // key number in big-endian format
    usage[4] = 0x55;        // used to derive Ki
    
    nfold(sizeof(usage)*8,usage,sizeof(ki_input)*8,ki_input);    // precompute
    dk(Ki,base_key,32,ki_input,32);
    dump_hex("Ki Key",Ki,32);
    
    // derive checksum of plaintext
    hmac_sha1(plaintext,44,Ki,32,checksum);
    dump_hex("HMAC",checksum,12);

    printf("\n\n");
    
    // verify successful decryption
    if(!memcmp(checksum,ts_checksum,sizeof(ts_checksum))) {
        printf(" - checksum valid.\n");
        printf(" - Timestamp = ");

        for(int i = 22;i < 37;i++)
            printf("%c",plaintext[i]);
        printf("\n");
    }
    else {
        printf(" - checksum invalid.\n");
    }  

    return(0);
}

