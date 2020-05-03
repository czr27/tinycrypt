/*
	Example of MS-CHAPv1 and MS-CHAPv2 generation.
	
	MS-CHAPv1 - RFC2433
	MS-CHAPv2 - RFC2759
	
	Note that i've omitted LM hash (DES variant) for simple reason you're probably
	not gonna see it used except from Windows 95/98 machines.

	The last line with username,hash and challenge is format to be used with mschap.dll module for
	PasswordsPro - http://www.insidepro.com/

	Usage: mschap_gen [ -a <authenticator challenge> ] [ -p <peer challenge> ] [ -k <password> ] [ -u <username> ]

             Username = "Administrator"
             Password = "12345678"
       Auth Challenge = 00000000000000000000000000000000
       Peer Challenge = 00000000000000000000000000000000



                -=[**** MS-CHAP v1 data ****]=-

            Challenge = 0000000000000000
          NT-Response = 942d21d73d250f8c6d9045247889e36628902055a8d97ef4

Administrator:942d21d73d250f8c:0000000000000000db52::Password is "12345678"



                -=[**** MS-CHAP v2 data ****]=-

            Challenge = 4178ca2607a252e3
         PasswordHash = 259745cb123a52aa2e693aaacca2db52
          NT-Response = 50091e25fdaf802b5d5c8904ecb6c33eb53eed41c52c1aeb
     PasswordHashHash = 6b2562426193337426d747e0e9f4ab18
AuthenticatorResponse = S=51f212588219b7bef6be92739bea062db28290e8

Administrator:50091e25fdaf802b:4178ca2607a252e3db52::Password is "12345678"

 */

#ifdef WIN32
    #define _CRT_SECURE_NO_DEPRECATE		// MS VC
    #pragma comment(lib,"libeay32.lib")
    //extern "C" int getopt(int argc, char **argv, char *optstring);
    //extern "C" char *optarg;
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <getopt.h>

#include <openssl/md4.h>
#include <openssl/md5.h>
#include <openssl/sha.h>
#include <openssl/des.h>

void NtPasswordHash(char Password[], unsigned char PasswordHash[])
{
	MD4_CTX ctx;
	size_t PassLen;
	unsigned short uni_pwd[256]={0};
	
	PassLen = strlen(Password);

	for(size_t i = 0;i < PassLen && i < 128;i++)
		uni_pwd[i] = Password[i];

	MD4_Init(&ctx);
	MD4_Update(&ctx,uni_pwd,PassLen*2);
	MD4_Final(PasswordHash,&ctx);
}

void HashNtPasswordHash(unsigned char PasswordHash[], unsigned char PasswordHashHash[])
{
	MD4_CTX ctx;
	
	MD4_Init(&ctx);
	MD4_Update(&ctx,PasswordHash,16);
	MD4_Final(PasswordHashHash,&ctx);
}

void ChallengeHash(unsigned char PeerChallenge[], unsigned char AuthChallenge[],
		   char UserName[], unsigned char Challenge[])
{
	SHA_CTX ctx;
	unsigned char Digest[20];
	
	SHA1_Init(&ctx);
	SHA1_Update(&ctx,PeerChallenge,16);
	SHA1_Update(&ctx,AuthChallenge,16);
	
	// iluha tells me to skip the DOMAIN part if we have DOMAIN\username format
	// will update later.

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

void ChallengeResponse(unsigned char Challenge[], unsigned char PasswordHash[], unsigned char Response[])
{
	unsigned char ZPasswordHash[21]={0};

	memcpy(&ZPasswordHash,PasswordHash,16);
	
	DesEncrypt(Challenge,&ZPasswordHash[0],&Response[0]);
	DesEncrypt(Challenge,&ZPasswordHash[7],&Response[8]);
	DesEncrypt(Challenge,&ZPasswordHash[14],&Response[16]);
}

void dump(char *text,unsigned char *data,int len)
{
	printf("\n%24s",text);

	if(len == 0) {
		printf("\"%s\"",data);
		return;
	}

	for(int i = 0;i < len;i++)
		printf("%.2x",data[i]);
}

void mschapv2_GenerateNTResponse(unsigned char AuthChallenge[], unsigned char PeerChallenge[],
			char UserName[], char Password[], unsigned char Response[])
{
	unsigned char Challenge[8];
	unsigned char PasswordHash[16];

	ChallengeHash(PeerChallenge,AuthChallenge,UserName,Challenge);
	dump("Challenge = ",Challenge,8);

	NtPasswordHash(Password,PasswordHash);	
	dump("PasswordHash = ",PasswordHash,16);

	ChallengeResponse(Challenge,PasswordHash,Response);
	dump("NT-Response = ",Response,24);
}

void mschapv2_GenerateAuthResponse(char Password[],unsigned char nt_response[],
				   unsigned char PeerChallenge[],unsigned char AuthChallenge[],
				   char UserName[],unsigned char auth_response[])
{
	unsigned char PasswordHash[16];
	unsigned char PasswordHashHash[16];
	unsigned char Challenge[16];
	unsigned char Digest[20];
	
	unsigned char Magic1[39] = { 0x4D, 0x61, 0x67, 0x69, 0x63, 0x20, 0x73, 0x65, 0x72, 0x76,
                                     0x65, 0x72, 0x20, 0x74, 0x6F, 0x20, 0x63, 0x6C, 0x69, 0x65,
                                     0x6E, 0x74, 0x20, 0x73, 0x69, 0x67, 0x6E, 0x69, 0x6E, 0x67,
                                     0x20, 0x63, 0x6F, 0x6E, 0x73, 0x74, 0x61, 0x6E, 0x74 };

	unsigned char Magic2[41] = { 0x50, 0x61, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x6D, 0x61, 0x6B,
                                     0x65, 0x20, 0x69, 0x74, 0x20, 0x64, 0x6F, 0x20, 0x6D, 0x6F,
                                     0x72, 0x65, 0x20, 0x74, 0x68, 0x61, 0x6E, 0x20, 0x6F, 0x6E,
                                     0x65, 0x20, 0x69, 0x74, 0x65, 0x72, 0x61, 0x74, 0x69, 0x6F,
                                     0x6E };
	SHA_CTX ctx;
	
	NtPasswordHash(Password,PasswordHash);
	HashNtPasswordHash(PasswordHash,PasswordHashHash);
	
	dump("PasswordHashHash = ",PasswordHashHash,16);

	SHA1_Init(&ctx);
	SHA1_Update(&ctx,PasswordHashHash,16);
	SHA1_Update(&ctx,nt_response,24);
	SHA1_Update(&ctx,Magic1,39);
	SHA1_Final(Digest,&ctx);
	
	ChallengeHash(PeerChallenge,AuthChallenge,UserName,Challenge);
	
	SHA1_Init(&ctx);
	SHA1_Update(&ctx,Digest,20);
	SHA1_Update(&ctx,Challenge,8);
	SHA1_Update(&ctx,Magic2,41);
	SHA1_Final(Digest,&ctx);
	
	dump("AuthenticatorResponse = S=",Digest,20);
}

void NtChallengeResponse(unsigned char Challenge[], char Password[], unsigned char Response[])
{
	unsigned char PasswordHash[16];
	
	NtPasswordHash(Password,PasswordHash);
	ChallengeResponse(Challenge,PasswordHash,Response);	
}
void mschapv1_GenerateNTResponse(unsigned char Challenge[], char Password[], unsigned char Response[])
{
	unsigned char PasswordHash[48]={0};
	
	dump("Challenge = ",Challenge,8);

	NtChallengeResponse(Challenge,Password,&PasswordHash[24]);
	dump("NT-Response = ",&PasswordHash[24],24);
	memcpy(Response,&PasswordHash[24],24);
}

void hex2bin(unsigned char dst[],size_t dst_len,char src[])
{
	unsigned int value = 0;
	char *p;

	for(p = src;*p = tolower(*p);p++) {
		if(!((*p >= '0' && *p <= '9') || (*p >= 'a' && *p <= 'f')))
			return;
	}

	dst_len = (dst_len > 32) ? 32 : dst_len;

	for(size_t i = 0;i < dst_len/2;i++) {
		sscanf(&src[i*2],"%2x",&value);
		dst[i] = value;
	}
}

void usage(char *module) {

        printf("\n\n\tMS-CHAP v1/v2 Hash Generator\n");
	    printf("\n\tUsage: %s [ -a <authenticator challenge> ] [ -p <peer challenge> ] [ -k <password> ] [ -u <username> ]\n\n",module);
        exit(0);
}

int main(int argc, char *argv[])
{
	char username[128]="Administrator";
	char password[ 64]="password";
	
	unsigned char auth[16]={ 0 };
	unsigned char peer[16]={ 0 };

	unsigned char nt_response[24];
	unsigned char auth_response[42];
	int opt;
	unsigned char challenge[8];
	unsigned char nt_hash[16];

	if(argc > 1) 
	{
		while( (opt = getopt(argc, argv,"a:p:u:k:")) != -1) 
		{     
			switch(opt) 
			{
				case 'a' :
					hex2bin(auth,strlen(optarg),optarg);
					break;

				case 'p' :
					hex2bin(peer,strlen(optarg),optarg);
					break;

				case 'u' :
					strncpy(username,optarg,sizeof(username)-1);
					break;

				case 'k' :
					strncpy(password,optarg,sizeof(password)-1);
					break;

				case '?' :
					usage(argv[0]);
			}
        }
	}

	dump("Username = ",(unsigned char*)username,0);
	dump("Password = ",(unsigned char*)password,0);
	dump("Auth Challenge = ",auth,16);
	dump("Peer Challenge = ",peer,16);

	NtPasswordHash(password,nt_hash);

	printf("\n\n\n\n\t\t-=[**** MS-CHAP v1 data ****]=-\n");
	mschapv1_GenerateNTResponse(auth,password,nt_response);

	printf("\n\n");
	printf("%s:",username);
	
	for(int i = 0;i < 8;i++)
		printf("%02x",nt_response[i]);
	
	printf(":");
	
	for(int i = 0;i < 8;i++)
		printf("%02x",auth[i]);

	printf("%02x%02x",nt_hash[14],nt_hash[15]);

	printf("::Password is ");

	if(!strlen(password))
		printf("empty\n\n");
	else
		printf("\"%s\"\n\n",password);

	printf("\n\n\t\t-=[**** MS-CHAP v2 data ****]=-\n");
	mschapv2_GenerateNTResponse(auth,peer,username,password,nt_response);
	mschapv2_GenerateAuthResponse(password,nt_response,peer,auth,username,auth_response);

	printf("\n\n");
	printf("%s:",username);
	
	for(int i = 0;i < 8;i++)
		printf("%02x",nt_response[i]);
	
	printf(":");
	
	ChallengeHash(peer,auth,username,challenge);

	for(int i = 0;i < 8;i++)
		printf("%02x",challenge[i]);

	printf("%02x%02x",nt_hash[14],nt_hash[15]);

	printf("::Password is ");
	
	if(!strlen(password))
		printf("empty\n\n");
	else
		printf("\"%s\"\n\n",password);

	return(0);	
}
