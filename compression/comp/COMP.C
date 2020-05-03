
// programmed in 1999 by Z0MBiE/29A <zloebuchij_zasrakomondohooy@usa.net>

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

typedef unsigned char   byte;
typedef unsigned short  word;
typedef unsigned long   dword;

#ifdef engine0
#include "engine0.c"
#endif
#ifdef engine1
#include "engine1.c"
#endif
#ifdef engine2
#include "engine2.c"
#endif
#ifdef engine3
#include "engine3.c"
#endif

void compressfile(const char* ifile,
                  const char* ofile)
  {
    FILE* i = fopen(ifile,"rb");
    FILE* o = fopen(ofile,"wb");

    dword code = 0;
    dword len  = 0;

    engine_init();

    for (;;)
      {
        byte c = fgetc(i);

        if (feof(i))
         {
           if (len != 0)
             fputc(code&255, o);
           break;
         }

        if (engine_next() != c)
          {
            code |= 0 << len;
            len  ++;
            code |= c << len;
            len  += 8;
          }
        else
          {
            code |= 1 << len;
            len  ++;
          }

        while (len >= 8)
          {
            fputc(code&255, o);
            code >>= 8;
            len  -= 8;
          }

        engine_update(c);
      }

    fclose(i);
    fclose(o);
  }

void decompressfile(const char* ifile,
                    const char* ofile)
  {
    FILE* i = fopen(ifile,"rb");
    FILE* o = fopen(ofile,"wb");

    dword code = 0;
    dword len  = 0;

    engine_init();

    for (;;)
      {
        byte c;

        if (len==0)
          {
            code = fgetc(i);
            len  = 8;
          }

        if (feof(i)) break;

        if ((code&1)==0)
          {
            code >>= 1;
            len  --;
            if (len < 8)
              {
                code |= fgetc(i) << len;
                if (feof(i)) break;
                len += 8;
              }
            c = code&255;
            code >>= 8;
            len  -= 8;
          }
        else
          {
            code >>= 1;
            len  --;
            c = engine_next();
          }

        fputc(c, o);

        engine_update(c);
      }

    fclose(i);
    fclose(o);
  }

void main(int argc, char *argv[])
  {
    if (argc != 4)
      {
        printf("syntax: %s c|d infile outfile\n", argv[0]);
        exit(0);
      }

    if (stricmp(argv[1],"c")==0) compressfile  (argv[2],argv[3]); else
    if (stricmp(argv[1],"d")==0) decompressfile(argv[2],argv[3]); else
      printf("unknown command\n");
  }
