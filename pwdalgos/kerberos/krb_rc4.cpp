
/*
	Kerberos V5 for Windows - Password Cracking Approach

	Let's consider the following elements.

		* KRB_AS_REQ: the Kerberos Authentication Service Request Message
		* ENC_PA_ENC_TIMESTAMP: the value of message field

		KRB_AS_REQ.padata.PA-ENC-TIMESTAMP.Value.encPA_ENC_TIMESTAMP
		
		* checksum = first 16 bytes of ENC_PA_ENC_TIMESTAMP
		* encrypted_data = ENC_PA_ENC_TIMESTAMP starting at byte 17 (i.e. ENC_PA_ENC_TIMESTAMP without the checksum)
		* pwd: the round password being tried
	
	compile on linux with openssl: g++ krb_rc4.cpp -okrb_rc4 -lcrypto
	
	This is just simple example of how you would decrypt the timestamp message using a password
	
	December 2008 - info/pcap data supplied by dragonii / forum.insidepro.com

    compile: g++ krb_aes.cpp -okrb_aes -lcrypto
    
    See the following RFC for more details about the crypto & algorithms used:
    
        RFC4757 - The RC4-HMAC Kerberos Encryption Types Used by Microsoft Windows
    
*/

#include
#include <openssl/md5.h>
#include <openssl/md4.h>
#include <openssl/rc4.h>

static
void hmac_md5(unsigned char text[], size_t text_len, 
    unsigned char key[], size_t key_len, unsigned char digest[])
{
	MD5_CTX ctx;
	unsigned char k_ipad[65];
	unsigned char k_opad[65];
	unsigned char tk[16];
	
	if(key_len > 64) {
		
		MD5_Init(&ctx);
		MD5_Update(&ctx,key,key_len);
		MD5_Final(tk,&ctx);
		
		key = tk;
		key_len = 16;
	}
	
	memset(k_ipad,0x36,sizeof(k_ipad));
	memset(k_opad,0x5c,sizeof(k_opad));
	
	for(size_t i = 0;i < key_len;i++) {
		k_ipad[i] ^= key[i];
		k_opad[i] ^= key[i];
	}
	
	MD5_Init(&ctx);
	MD5_Update(&ctx,k_ipad,64);
	MD5_Update(&ctx,text,text_len);
	MD5_Final(digest,&ctx);
	
	MD5_Init(&ctx);
	MD5_Update(&ctx,k_opad,64);
	MD5_Update(&ctx,digest,16);
	MD5_Final(digest,&ctx);
}

static
void ntlm1_hash(char password[], unsigned char digest[])
{
	unsigned short uni_pwd[128]={0};
	size_t pass_len = strlen(password);
	MD4_CTX ctx;
	
	for(size_t i = 0;i < pass_len;i++)
		uni_pwd[i] = password[i];

	MD4_Init(&ctx);
	MD4_Update(&ctx,uni_pwd,pass_len*2);
	MD4_Final(digest,&ctx);
}

/*
	PA_ENC_TIMESTAMP

	00004648h: 02 E8 37 D0 6B 2A C7 68 91 F3 88 D9 CC 36 C6 7A ; è7Ðk*Çh‘óˆÙÌ6Æz
	00004658h: 2A 97 85 BF 50 36 C4 5D 38 43 49 0B F9 C2 28 E8 ; *—…¿P6Ä]8CI.ùÂ(è
	00004668h: C1 86 53 E1 0C E5 8D 7F 8E F1 19 D2 EF 4F 92 B1 ; Á†Sá.åŽñ.ÒïO’±
	00004678h: 80 3B 14 51                                     ; €;.Q

*/

// checksum of timestamp
unsigned char ts_checksum[16] = { 0x02, 0xE8, 0x37, 0xD0, 0x6B, 0x2A, 0xC7, 0x68, 0x91, 0xF3, 0x88, 0xD9, 0xCC, 0x36, 0xC6, 0x7A };

// encrypted timestamp
unsigned char pa_enc_timestamp[36] = {  0x2A, 0x97, 0x85, 0xBF, 0x50, 0x36, 0xC4, 0x5D, 0x38, 0x43, 0x49, 0x0B, 0xF9, 0xC2, 0x28, 0xE8,
                                        0xC1, 0x86, 0x53, 0xE1, 0x0C, 0xE5, 0x8D, 0x7F, 0x8E, 0xF1, 0x19, 0xD2, 0xEF, 0x4F, 0x92, 0xB1,
                                        0x80, 0x3B, 0x14, 0x51 };

void dump_hex(char str[], unsigned char hex[], size_t len)
{
    printf("\n\n[%s]",str);
        
    for (size_t i(0);i < len;i++) {
        if (!(i % 16))
            printf("\n%08x: ",i);
               
        printf(" %02x",hex[i]);
    }
}

unsigned char clear_data[64];

int main(int argc, char *argv[])
{
    if (argc != 2) {
        printf("\nUsage:%s <password>\n",argv[0]);
        return 0;
    }
    
    unsigned char K[16];
    
    /*
        String2Key(password)
        K = MD4(UNICODE(password))
     */
    ntlm1_hash(argv[1],K);
    dump_hex("NTLM - K",K,sizeof(K));
    
    unsigned char K1[16];
    unsigned int T = 1;
    
    // 2. K1 = MD5_HMAC(K,1); // with 1 encoded as little endian on 4 bytes (01000000 in hexa);
    hmac_md5((unsigned char*)&T,sizeof(T),K,sizeof(K),K1);
    dump_hex("HMAC - K1",K1,sizeof(K1));
    
    unsigned char K3[16];
    
    // 3. K3 = MD5_HMAC(K1,checksum);
    hmac_md5(ts_checksum,sizeof(ts_checksum),K1,sizeof(K1),K3);
    dump_hex("Encryption key",K3,sizeof(K3));
    
    // decrypt the timestamp
    // 4. plaintext = RC4(K3,pa_enc_timestamp);
    RC4_KEY key;
    unsigned char plaintext[sizeof(pa_enc_timestamp)];
    
    RC4_set_key(&key,sizeof(K3),K3);
    RC4(&key,sizeof(pa_enc_timestamp),pa_enc_timestamp,plaintext);
    dump_hex("Plaintext",plaintext,sizeof(plaintext));
    
    // 5. If plaintext contains a UTC timestamp starting at byte 15 (in the format YYYYMMDDHHMMSSZ), you've got it.

    // calculate the checksum
    unsigned char K2[16];
    
    hmac_md5(plaintext,sizeof(plaintext),K1,sizeof(K1),K2);
    dump_hex("HMAC",K2,sizeof(K2));

    printf("\n\n");

    // verify successful decryption
    if(!memcmp(K2,ts_checksum,sizeof(ts_checksum))) {
        printf(" - checksum valid.\n");
        printf(" - Timestamp = ");

        for(int i = 14;i < 29;i++)
            printf("%c",plaintext[i]);
        printf("\n");
    }
    else {
        printf(" - checksum invalid.\n");
    }    
    return(0);
}
