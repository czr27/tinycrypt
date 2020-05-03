
// freenrv2[b,d,e] compression algo

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <io.h>
#pragma hdrstop

extern "C" int __cdecl unpack_nrv2b(BYTE*, BYTE*);
extern "C" int __cdecl unpack_nrv2d(BYTE*, BYTE*);
extern "C" int __cdecl unpack_nrv2e(BYTE*, BYTE*);

//#pragma optimize("g",on)

#define bbPutBit(x)                             \
{                                               \
  if (t_bitcount == 32)                         \
  {                                             \
    t_bitset   = (DWORD*)t_outptr;              \
    t_outptr += 4;                              \
    *t_bitset  = 0;                             \
    t_bitcount = 0;                             \
  }                                             \
  *t_bitset = ((*t_bitset) << 1) | ((x)&1);     \
  t_bitcount++;                                 \
}

#define code_prefix_ss11(a)                     \
{                                               \
    DWORD i = a;                                \
    if (i >= 2)                                 \
    {                                           \
        DWORD t = 4;                            \
        i += 2;                                 \
        do {                                    \
            t <<= 1;                            \
        } while (i >= t);                       \
        t >>= 1;                                \
        do {                                    \
            t >>= 1;                            \
            bbPutBit((i & t) ? 1 : 0);          \
            bbPutBit(0);                        \
        } while (t > 2);                        \
    }                                           \
    bbPutBit(i & 1);                            \
    bbPutBit(1);                                \
}

#define code_prefix_ss12(a)                     \
{                                               \
    DWORD i = a;                                \
    if (i >= 2)                                 \
    {                                           \
        DWORD t = 2;                            \
        do {                                    \
            i -= t;                             \
            t <<= 2;                            \
        } while (i >= t);                       \
        do {                                    \
            t >>= 1;                            \
            bbPutBit((i & t) ? 1 : 0);          \
            bbPutBit(0);                        \
            t >>= 1;                            \
            bbPutBit((i & t) ? 1 : 0);          \
        } while (t > 2);                        \
    }                                           \
    bbPutBit(i & 1);                            \
    bbPutBit(1);                                \
}

int __start_nrv2b() { return 1; }
#include "0_nrv2b.cpp"
int __end_nrv2b() { return 2; }

int __start_nrv2d() { return 3; }
#include "0_nrv2d.cpp"
int __end_nrv2d() { return 4; }

int __start_nrv2e() { return 5; }
#include "0_nrv2e.cpp"
int __end_nrv2e() { return 6; }

void main(int argc, char* argv[])
{

  if (argc == 2)
  if (!stricmp(argv[1],"--gimmeyourbrain"))
  {
    printf("nrv2b: code size = %d\n", (int)&__end_nrv2b - (int)&__start_nrv2b);
    printf("nrv2d: code size = %d\n", (int)&__end_nrv2d - (int)&__start_nrv2d);
    printf("nrv2e: code size = %d\n", (int)&__end_nrv2e - (int)&__start_nrv2e);
    FILE*f0=fopen("pack_nrv2b.bin","wb");
    fwrite((char*)&__start_nrv2b + 16, 1,(int)&__end_nrv2b - (int)&__start_nrv2b - 16, f0);
    fclose(f0);
    FILE*f1=fopen("pack_nrv2d.bin","wb");
    fwrite((char*)&__start_nrv2d + 16, 1,(int)&__end_nrv2d - (int)&__start_nrv2d - 16, f1);
    fclose(f1);
    FILE*f2=fopen("pack_nrv2e.bin","wb");
    fwrite((char*)&__start_nrv2e + 16, 1,(int)&__end_nrv2e - (int)&__start_nrv2e - 16, f2);
    fclose(f2);
    exit(0);
  }

  if (argc!=4)
  {
    printf("syntax: pack --<nrv2b|nrv2d|nrv2e> infile outfile\n");
    exit(0);
  }

  FILE*f1=fopen(argv[2],"rb");
  int ilen = filelength(fileno(f1));
  BYTE* ibuf = new BYTE[ ilen ];
  fread(ibuf,1,ilen,f1);
  fclose(f1);

  BYTE* obuf = new BYTE[ ilen+(ilen>>3)+1024 ];
  BYTE* xbuf = new BYTE[ ilen+1024 ];
  DWORD olen=0, xlen=0;

  DWORD t0 = GetTickCount();

  if (!stricmp(argv[1],"--nrv2b")) olen = pack_nrv2b(ibuf,ilen,obuf,&malloc,&free);
  if (!stricmp(argv[1],"--nrv2d")) olen = pack_nrv2d(ibuf,ilen,obuf,&malloc,&free);
  if (!stricmp(argv[1],"--nrv2e")) olen = pack_nrv2e(ibuf,ilen,obuf,&malloc,&free);

  DWORD t1 = GetTickCount();
  printf("packed: %d --> %d\n", ilen, olen);
  printf("time: %d ms\n",t1-t0);

  if (!stricmp(argv[1],"--nrv2b")) xlen = unpack_nrv2b(obuf,xbuf);
  if (!stricmp(argv[1],"--nrv2d")) xlen = unpack_nrv2d(obuf,xbuf);
  if (!stricmp(argv[1],"--nrv2e")) xlen = unpack_nrv2e(obuf,xbuf);
  printf("unpacked: %d --> %d\n", olen,xlen);

  fflush(stdout);
  assert(ilen==(int)xlen);
  assert(memcmp(ibuf,xbuf,xlen)==0);
  printf("verify OK\n");

  FILE*f2=fopen(argv[3],"wb");
  fwrite(obuf,1,olen,f2);
  fclose(f2);

  delete ibuf;
  delete obuf;
  delete xbuf;

} // main
