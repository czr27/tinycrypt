
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <io.h>
#pragma hdrstop

#define MIN(a,b)                ((a)<(b)?(a):(b))
#define MAX(a,b)                ((a)>(b)?(a):(b))

#include "my_assert.cpp"
#include "my_dict.cpp"

void main(int argc, char* argv[])
{
  assert(argc==2);

  char* infile  = argv[1];

  FILE*f1=fopen(infile,"rb");
  if (f1==NULL)
  {
    printf("ERROR: cant read: %s\n", infile);
    exit(0);
  }
  int ilen = filelength(fileno(f1));
  printf("+ reading: %s, %d bytes\n", infile, ilen);
  BYTE* ibuf = new BYTE[ ilen+1 ];
  assert(ibuf);
  assert(fread(ibuf,1,ilen,f1)==ilen);
  fclose(f1);

  build_tree(ibuf,ilen);

  // dump strings
  for(DWORD i=0; i<str_cnt; i++)
  {
    printf("str_n=%d len=%d  (%3d)   ", i,str_len[i],str_o_cnt[i]);
    for(DWORD j=0; j<str_o_cnt[i]; j++)
      printf(" %d..%d",str_o_ptr1[i][j], str_o_ptr2[i][j]);
    printf("\n");
  }

  // dump ptrs to strings
  for(i=0; i<ilen; i++)
  {
    printf("%08x: (%d) ",i,h_cnt[i]);
    for(DWORD j=0; j<h_cnt[i]; j++)
    {
      DWORD str_n = h_str[i][j];
      printf(" %d ", str_n);

      DWORD s_len = str_len[str_n];
      for(DWORD ni = 0; ni < str_o_cnt[str_n]; ni++)
      {
        for(DWORD o = str_o_ptr1[str_n][ni]; o <= str_o_ptr2[str_n][ni]; o++)
        {
          if (memcmp(ibuf+i,ibuf+o,s_len)!=0)
          {
            printf("{i=%d,o=%d,l=%d}\n",i,o,s_len);
            exit(0);
          }
        }
      }
    }
    printf("\n");
  }

  done_tree(ilen);

} // main
