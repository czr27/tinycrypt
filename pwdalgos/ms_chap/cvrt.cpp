
// compile linux: g++ -ocvrt cvrt.cpp -lcrypto
//

#ifdef _WIN32		// visual C++
    #define _CRT_SECURE_NO_DEPRECATE
    #pragma comment(lib, "c:\\openssl\\lib\\libeay32.lib")
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <openssl/sha.h>
#include <openssl/des.h>

bool hex2bin(unsigned char dst[],size_t dst_len,char src[])
{
	unsigned int value = 0;

	for(char *p = src;*p = tolower(*p);p++) {
		if(!((*p >= '0' && *p <= '9') || (*p >= 'a' && *p <= 'f')))
			return(false);
	}

	for(size_t i = 0;i < dst_len/2;i++) {
		sscanf(&src[i*2],"%2x",&value);
		dst[i] = value;
	}
	return(true);
}

void ChallengeHash(unsigned char PeerChallenge[], unsigned char AuthChallenge[],
		   char UserName[], unsigned char Challenge[])
{
	SHA_CTX ctx;
	unsigned char Digest[20];
	
	SHA1_Init(&ctx);
	SHA1_Update(&ctx,PeerChallenge,16);
	SHA1_Update(&ctx,AuthChallenge,16);
	
	SHA1_Update(&ctx,UserName,strlen(UserName));
	SHA1_Final(Digest,&ctx);
	memcpy(Challenge,Digest,8);
}

void DesEncrypt(unsigned char Clear[], unsigned char Key[], unsigned char Cypher[])
{
	unsigned char des_key[8]={0};
	DES_key_schedule ks;
	
	des_key[0] = ((Key[0] >> 1));
	des_key[1] = ((Key[0] & 0x01) << 6) | (Key[1] >> 2);
	des_key[2] = ((Key[1] & 0x03) << 5) | (Key[2] >> 3);
	des_key[3] = ((Key[2] & 0x07) << 4) | (Key[3] >> 4);
	des_key[4] = ((Key[3] & 0x0f) << 3) | (Key[4] >> 5);
	des_key[5] = ((Key[4] & 0x1f) << 2) | (Key[5] >> 6);
	des_key[6] = ((Key[5] & 0x3f) << 1) | (Key[6] >> 7);
	des_key[7] = ((Key[6] & 0x7f));
	
	for(int i = 0;i < 8;i++)
		des_key[i] = (des_key[i] << 1);
	
	DES_set_odd_parity((DES_cblock*)des_key);

	DES_set_key_unchecked((DES_cblock*)&des_key,&ks);
	DES_ecb_encrypt((DES_cblock*)Clear,(DES_cblock*)Cypher,&ks,DES_ENCRYPT);
}

// brute force the last 2 ntlm bytes from last 8 bytes of 24-byte client nt response
bool find_ntlm_bytes(unsigned char challenge[],unsigned char ciphertext[],unsigned char ntlm_bytes[])
{
	unsigned char des_key[8]={0};
	unsigned char result[8];

	for(int i = 0;i < 256;i++)
	{
		des_key[0] = i;

		for(int j = 0;j < 256;j++)
		{
			des_key[1] = j;

			DesEncrypt(challenge,des_key,result);

			if(memcmp(result,ciphertext,8) == 0)
			{
				memcpy(ntlm_bytes,des_key,2);
				return(true);
			}
		}
	}
	return(false);
}

int main(int argc, char *argv[])
{
	FILE *in,*out;
	char buffer[512];
	int line = 0;
	char *username,*hash,*salt,*comment;

	unsigned char salt_binary[128]={0};
	unsigned char hash_binary[128]={0};

	unsigned char challenge[8];
	unsigned char ntlm_bytes[4];

	char out_name[256];
	char in_name[256];

	if(argc != 2) {
		printf("\n\tUsage:%s <ntlmv1_format> <output_file>\n",argv[0]);
		return(0);
	}

	strncpy(in_name,argv[1],256);
	char *file_name = strtok(in_name,".");

	sprintf(out_name,"%s_new.txt",file_name);

	if((out = fopen(out_name,"wb")) == 0) {
		printf("\n[-] couldn't create %s for output",out_name);
		return(0);
	}

	if((in = fopen(argv[1],"rb")) != 0) {

		printf("\nReading from %s\n",argv[1]);

		while(fgets(buffer,sizeof(buffer)-1,in)) {
			
			line++;

			username = strtok(buffer,":");
			hash = strtok(0,":");
			salt = strtok(0,":");
			comment = strtok(0,":");

			if( !(username && hash && salt) ) {
				printf("\n[-] parse error on line %d",line);
				continue;
			}

			size_t hash_len = strlen(hash);

			if(hex2bin(hash_binary,48,hash) != true) {
				printf("\n[-] parse error of hash on line %d",line);
				continue;
			}

			size_t salt_len = strlen(salt);

                        if(hex2bin(salt_binary,64,salt) != true) {
				printf("\n[-] parse error of salt on line %d",line);
				continue;
			}

			if(salt_len == 64) {
				// ms-chap v2
				// derive challenge from the username/peer+auth challenges
				ChallengeHash(&salt_binary[0],&salt_binary[16],username,challenge);
			} else if(salt_len == 16) {
				// assume its ms-chapv1
				memcpy(challenge,salt_binary,8);
			} else {
				printf("\n[-] parse error of salt on line %d",line);
				continue;
			}

			// find last 2 bytes of users NTLM hash with brute force.
			// only requires 65,536 attempts
			if(!find_ntlm_bytes(challenge,&hash_binary[16],ntlm_bytes)) {
				printf("\n[-] couldn't recover last 2 bytes for response at line %d",line);
				continue;
			}

			fprintf(out,"%s:",username);

			// MS-CHAPv1+v2 use DES in ECB mode, encrypting the same
			// plaintext 3 times..
			//
			// so only print the first 8 byte DES ciphertext
			// since its highly unlikely we'd find a collision
			// using anything other than the correct password!


			for(int j = 0;j < 8;j++)
			    fprintf(out,"%02x",hash_binary[j]);

			fprintf(out,":");

			for(int j = 0;j < 8;j++)
			    fprintf(out,"%02x",salt_binary[j]);

			fprintf(out,"%02x%02x::",ntlm_bytes[0],ntlm_bytes[1]);

			if(comment != 0) fprintf(out,"%s",comment);
			
			printf("Processed %d entries\r",line);
		}
		fclose(in);

		printf("\n\nSaved to %s\n",out_name);
		fclose(out);

	} else printf("fopen(%s)",argv[1]);

	return(0);
}
