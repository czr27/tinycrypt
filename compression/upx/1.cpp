
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#pragma hdrstop

// common stuff

#undef assert
#define assert(p)   ((p) ? (void)0 : _assert(#p, __FILE__, __LINE__))
void _assert(char * __cond, char * __file, int __line)
{
  printf("ASSERT: %s, file %s, line %d\n", __cond, __file, __line);
  exit(0);
}

#define MIN(a,b)                ((a)<(b)?(a):(b))
#define MAX(a,b)                ((a)>(b)?(a):(b))

// include files

#include "CDict.cpp"
#include "CGraph.cpp"
#include "CModule.cpp"
#include "CSfx.cpp"
#include "CModUPX.cpp"
#include "CModLZ.cpp"

void help()
{
  printf("syntax:\n");
  printf("  snippetupxs infile outfile --<upx|lz> [options]\n");
  printf("upx options:\n");
  printf("  --nosfx                                   # disable adding sfx\n");
  printf("  minP1 maxP1 minP2 maxP2 ... minP5 maxP5   # specify compression options\n");
  printf("lz options:\n");
  printf("  --nosfx                                   # disable adding sfx\n");
  printf("  minP1 maxP1 minP2 maxP2 ... minP5 maxP5   # specify compression options\n");
  exit(0);
}

void main(int argc, char* argv[])
{
  printf("upx for code snippets (x86,32-bit)  v3.00s  (x) 2004\n");

  // init modules

  CModUPX* ModUPX = new CModUPX;
  assert(ModUPX);

  CModLZ* ModLZ = new CModLZ;
  assert(ModLZ);

  // get params

  char* infile  = 0;
  char* outfile = 0;
  char* compr   = 0;

  for(int i=1; i<argc; i++)
  {
    char*s = argv[i];
    if (infile  == 0) infile  = s; else
    if (outfile == 0) outfile = s; else
    if (compr   == 0) compr   = s; else
    {
      if (!stricmp(compr, "--upx"))
      {
        if (!ModUPX->ParseOption(s))
        {
          printf("invalid upx_option (%s)\n", s);
          help();
        }
      }
      else
      if (!stricmp(compr, "--lz"))
      {
        if (!ModLZ->ParseOption(s))
        {
          printf("invalid lz_option (%s)\n", s);
          help();
        }
      }
      else
      {
        printf("invalid compression type (%s)\n", compr);
        help();
      }
    }
  }
  if (!infile || !outfile || !compr) help();

  // load file/alloc input buf

  FILE*f1=fopen(infile,"rb");
  if (f1==NULL)
  {
    printf("ERROR: cant read: %s\n", infile);
    exit(0);
  }
  int ilen = filelength(fileno(f1));
  printf("+ reading: %s, %d bytes\n", infile, ilen);
  BYTE* ibuf = new BYTE[ ilen ];
  fread(ibuf,1,ilen,f1);
  fclose(f1);

  // alloc output buf

  BYTE* obuf = new BYTE[ ilen+(ilen>>3)+1024 ];
  DWORD olen=0;

  // pack

  if (!stricmp(compr, "--upx"))
  {
    printf("+ packing (upx)\n");

    ModUPX->Init(ibuf, ilen);
    olen = ModUPX->Pack(ibuf, ilen, obuf);
    ModUPX->Done();
  }
  else
  if (!stricmp(compr, "--lz"))
  {
    printf("+ packing (upx)\n");

    ModLZ->Init(ibuf, ilen);
    olen = ModLZ->Pack(ibuf, ilen, obuf);
    ModLZ->Done();
  }
  else
    help();

  // save file

  FILE*f2=fopen(outfile,"wb");
  if (f2==NULL)
  {
    printf("ERROR: cant write: %s\n", outfile);
    exit(0);
  }
  printf("+ writing: [%s], %d bytes\n", outfile, olen);
  fwrite(obuf,1,olen,f2);
  fclose(f2);

  // free buffers

  delete ibuf;
  delete obuf;

  // free modules

  delete ModUPX;
  delete ModLZ;

} // main
