
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <io.h>
#pragma hdrstop

extern "C" DWORD __cdecl pack1_nrv2b(BYTE*,DWORD,BYTE*,void*(__cdecl*)(unsigned int),void (__cdecl*)(void*));
extern "C" DWORD __cdecl pack1_nrv2d(BYTE*,DWORD,BYTE*,void*(__cdecl*)(unsigned int),void (__cdecl*)(void*));
extern "C" DWORD __cdecl pack1_nrv2e(BYTE*,DWORD,BYTE*,void*(__cdecl*)(unsigned int),void (__cdecl*)(void*));
extern "C" DWORD __cdecl pack2_nrv2b(BYTE*,DWORD,BYTE*,void*(__cdecl*)(unsigned int),void (__cdecl*)(void*));
extern "C" DWORD __cdecl pack2_nrv2d(BYTE*,DWORD,BYTE*,void*(__cdecl*)(unsigned int),void (__cdecl*)(void*));
extern "C" DWORD __cdecl pack2_nrv2e(BYTE*,DWORD,BYTE*,void*(__cdecl*)(unsigned int),void (__cdecl*)(void*));
extern "C" DWORD __cdecl unpack_nrv2b(BYTE*, BYTE*);
extern "C" DWORD __cdecl unpack_nrv2d(BYTE*, BYTE*);
extern "C" DWORD __cdecl unpack_nrv2e(BYTE*, BYTE*);

extern "C" void __cdecl u_nrv2b_start(void);
extern "C" void __cdecl u_nrv2b_end  (void);
extern "C" void __cdecl u_nrv2d_start(void);
extern "C" void __cdecl u_nrv2d_end  (void);
extern "C" void __cdecl u_nrv2e_start(void);
extern "C" void __cdecl u_nrv2e_end  (void);

void main(int argc, char* argv[])
{
  printf("upx for code snippets (x86,32-bit)  v1.00  (x) 2004\n");

  if ((argc == 5) && (!stricmp(argv[1], "c")))
  {
    char* method  = argv[2];
    char* infile  = argv[3];
    char* outfile = argv[4];

    printf("+ reading: %s\n", infile);
    FILE*f1=fopen(infile,"rb");
    int ilen = filelength(fileno(f1));
    BYTE* ibuf = new BYTE[ ilen ];
    fread(ibuf,1,ilen,f1);
    fclose(f1);

    BYTE* obuf = new BYTE[ ilen+(ilen>>3)+1024 ];
    DWORD olen = 0;

    printf("+ packing with method: %s\n", method);
    DWORD t0 = GetTickCount();
    if (!stricmp(method,"2b")) olen = pack2_nrv2b(ibuf,ilen,obuf,&malloc,&free);
    if (!stricmp(method,"2d")) olen = pack2_nrv2d(ibuf,ilen,obuf,&malloc,&free);
    if (!stricmp(method,"2e")) olen = pack2_nrv2e(ibuf,ilen,obuf,&malloc,&free);
    DWORD t1 = GetTickCount();
    printf("+ packed: %d --> %d, used %d ms\n", ilen, olen, t1-t0);

    printf("+ writing: %s\n", outfile);
    FILE*f2=fopen(outfile,"wb");
    fwrite(obuf,1,olen,f2);
    fclose(f2);

    delete ibuf;
    delete obuf;
  }
  else
  if ((argc == 5) && (!stricmp(argv[1], "d")))
  {
    char* method  = argv[2];
    char* infile  = argv[3];
    char* outfile = argv[4];

    printf("+ reading: %s\n", infile);
    FILE*f1=fopen(infile,"rb");
    int ilen = filelength(fileno(f1));
    BYTE* ibuf = new BYTE[ ilen ];
    fread(ibuf,1,ilen,f1);
    fclose(f1);

    BYTE* obuf = new BYTE[ 1048576 ];
    DWORD olen = 0;

    printf("+ unpacking with method: %s\n", method);
    if (!stricmp(method,"2b")) olen = unpack_nrv2b(ibuf,obuf);
    if (!stricmp(method,"2d")) olen = unpack_nrv2d(ibuf,obuf);
    if (!stricmp(method,"2e")) olen = unpack_nrv2e(ibuf,obuf);
    printf("+ unpacked: %d --> %d\n", ilen, olen);

    printf("+ writing: %s\n", outfile);
    FILE*f2=fopen(outfile,"wb");
    fwrite(obuf,1,olen,f2);
    fclose(f2);

    delete ibuf;
    delete obuf;

  }
  else
  if ( (argc == 4) &&
       ( (!stricmp(argv[1], "p")) ||
         (!stricmp(argv[1], "x")) ||
         (!stricmp(argv[1], "px")) )
     )
  {
    char* infile  = argv[2];
    char* outfile = argv[3];

    printf("+ reading: %s\n", infile);
    FILE*f1=fopen(infile,"rb");
    int ilen = filelength(fileno(f1));
    BYTE* ibuf = new BYTE[ 1048576 ];
    fread(ibuf,1,ilen,f1);
    fclose(f1);

    BYTE* obuf = new BYTE[ 1048576 ];
    DWORD olen = 0;

    BYTE* obuf_2b = new BYTE[ 1048576 ];
    DWORD olen_2b = 0;
    BYTE* obuf_2d = new BYTE[ 1048576 ];
    DWORD olen_2d = 0;
    BYTE* obuf_2e = new BYTE[ 1048576 ];
    DWORD olen_2e = 0;

    if (strchr(argv[1],'p') || strchr(argv[1],'P'))
    {

      DWORD t0,t1;

      printf("+ packing with method: 2b\n");
      t0 = GetTickCount();
      olen_2b = pack2_nrv2b(ibuf,ilen,obuf_2b,&malloc,&free);
      t1 = GetTickCount();
      printf("+ packed: %d --> %d, used %d ms\n", ilen, olen_2b, t1-t0);

      printf("+ packing with method: 2d\n");
      t0 = GetTickCount();
      olen_2d = pack2_nrv2d(ibuf,ilen,obuf_2d,&malloc,&free);
      t1 = GetTickCount();
      printf("+ packed: %d --> %d, used %d ms\n", ilen, olen_2d, t1-t0);

      printf("+ packing with method: 2e\n");
      t0 = GetTickCount();
      olen_2e = pack2_nrv2e(ibuf,ilen,obuf_2e,&malloc,&free);
      t1 = GetTickCount();
      printf("+ packed: %d --> %d, used %d ms\n", ilen, olen_2e, t1-t0);

      BYTE* pbuf;
      DWORD plen, m;

      int sz_2b = (int)&u_nrv2b_end-(int)&u_nrv2b_start;
      int sz_2d = (int)&u_nrv2d_end-(int)&u_nrv2d_start;
      int sz_2e = (int)&u_nrv2e_end-(int)&u_nrv2e_start;

      if ((olen_2b+sz_2b <= olen_2d+sz_2d) && (olen_2b+sz_2b <= olen_2e+sz_2e))
      {
        printf("+ selected method: 2b, raw decryptor size %d\n", sz_2b);
        pbuf = obuf_2b;
        plen = olen_2b;
        m = 0x2b;
      }
      else
      if ((olen_2d+sz_2d <= olen_2b+sz_2b) && (olen_2d+sz_2d <= olen_2e+sz_2e))
      {
        printf("+ selected method: 2d, raw decryptor size %d\n", sz_2d);
        pbuf = obuf_2d;
        plen = olen_2d;
        m = 0x2d;
      }
      else
      {
        printf("+ selected method: 2e, raw decryptor size %d\n", sz_2e);
        pbuf = obuf_2e;
        plen = olen_2e;
        m = 0x2e;
      }

      printf("+ building sfx code\n");

      olen = 0;
      // call pop_packed_data
      obuf[olen++] = 0xE8;
      *(DWORD*)&obuf[olen] = plen; olen += 4;
      // packed data
      memcpy(obuf+olen, pbuf, plen); olen += plen;
      obuf[olen++] = 0x5E;  // pop esi
      obuf[olen++] = 0x81;  // sub esp, (unpacked_size+3) & 0xfffffffc
      obuf[olen++] = 0xEC;  //
      *(DWORD*)&obuf[olen] = (ilen+3)&(~3); olen += 4;
      obuf[olen++] = 0x89;  // mov edi, esp
      obuf[olen++] = 0xE7;  //

      if (m == 0x2b) { memcpy(obuf+olen, (char*)&u_nrv2b_start, sz_2b); olen += sz_2b; };
      if (m == 0x2d) { memcpy(obuf+olen, (char*)&u_nrv2d_start, sz_2d); olen += sz_2d; };
      if (m == 0x2e) { memcpy(obuf+olen, (char*)&u_nrv2e_start, sz_2e); olen += sz_2e; };

      obuf[olen++] = 0xFF;  // jmp esp
      obuf[olen++] = 0xE4;

      printf("+ total size %d bytes\n", olen);

      memcpy(ibuf, obuf, olen);
      ilen = olen;

    } // 'p'

    if (strchr(argv[1],'x') || strchr(argv[1],'X'))
    {

      int ilen0 = ilen;
      while(ilen%4) ibuf[ilen++] = 0x90;
      if (ilen != ilen0)
        printf("+ nop-padded: %d-->%d (+%d bytes)\n",ilen0,ilen,ilen-ilen0);

      unsigned xordword = 0;
      for(unsigned k=0; k<=3; k++)
      {
        unsigned q = 0;
    #define IS_OK(x)   (strchr("\x0D\x0A\x2F\x5C",(x))==NULL)
        for(unsigned i=255; i!=0; i--)
        if (IS_OK(i))
        {
          int c = 0;
          for(int j=0; j<ilen; j+=4)
            if (!IS_OK(ibuf[j+k] ^ i))
            {
              c++;
              break;
            }
          if (c==0)
          {
            q = i;
            break;
          }
        }
        if (q==0)
        {
          printf("ERROR: cant find xordword, xd=%08X, k=%d\n", xordword, k);
          exit(0);
        }
        xordword |= q << (k<<3);
      }

      printf("+ xordword is %08X, building unxor code\n", xordword);

      olen = 0;
      obuf[olen++] = 0x68;                         // push {
      *(DWORD*)&obuf[olen] = 0x90E6FF5E; olen+=4;  //   pop esi, jmp esi }
      *(DWORD*)&obuf[olen] = 0xd4ff; olen += 2;    // call esp
      *(DWORD*)&obuf[olen] = 0x13c683; olen += 3;  // add esi, 0x13
      obuf[olen++] = 0xb9;                         // mov ecx,
      *(DWORD*)&obuf[olen] = ~(ilen/4); olen+=4;     //   ~(size/4)
      *(DWORD*)&obuf[olen] = 0xd1f7; olen += 2;    // not ecx
      *(DWORD*)&obuf[olen] = 0x3681; olen += 2;    // xor dword ptr [esi],
      *(DWORD*)&obuf[olen] = xordword; olen+=4;    //   xordword
      obuf[olen++] = 0xad;                         // lodsd
      *(DWORD*)&obuf[olen] = 0xf7e2; olen += 2;    // loop cycle
      // xored data
      for(int j=0; j<ilen; j+=4)
        *(unsigned long*)&obuf[olen+j] = *(unsigned long*)&ibuf[j] ^ xordword;
      olen += ilen;

      printf("+ total size %d bytes\n", olen);

      memcpy(ibuf, obuf, olen);
      ilen = olen;
    }

    printf("+ writing: %s\n", outfile);
    FILE*f2=fopen(outfile,"wb");
    fwrite(ibuf,1,ilen,f2);
    fclose(f2);

    delete ibuf;
    delete obuf;
    delete obuf_2b;
    delete obuf_2d;
    delete obuf_2e;

  }
  else
  {
    printf("syntax:\n");
    printf("  snippetupx c <2b|2d|2e> infile outfile  # pack file\n");
    printf("  snippetupx d <2b|2d|2e> infile outfile  # unpack file\n");
    printf("  snippetupx p  infile outfile            # pack snippet\n");
    printf("  snippetupx x  infile outfile            # xor snippet\n");
    printf("  snippetupx px infile outfile            # pack+xor snippet\n");
    exit(0);
  }

} // main
