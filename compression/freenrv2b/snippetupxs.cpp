
// packing codes format:
// <1> <orig_byte:8>
// <0>
//  { # offset
//    <01>     # m_off == last_m_off
//    ||
//    < P4 & 1 ? ss11:ss12 ( 1+((m_off-P5)>>P2)  ) >
//    < ((m_off-P5)&((1<<P2)-1)) :P2 >
//  }
//  { # length
//    <m_len_low_bits:P1>
//    ||
//    <0:P1>
//    < P4 & 2 ? ss11:ss12 ( (m_len-(1<<P1))>>P3 ) >
//    < ((m_len-(1<<P1))&((1<<P3)-1)) :P3 >
//  }
//  # last_m_off <-- m_off

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <io.h>
#pragma hdrstop

int do_sfx = 1;

#define MIN(a,b)                ((a)<(b)?(a):(b))
#define MAX(a,b)                ((a)>(b)?(a):(b))

#include "my_assert.cpp"
#include "my_dict.cpp"
#include "my_graph.cpp"

#pragma optimize("g",on)

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

#define ADD_B(x)                       \
        {                              \
          x_value[x_count  ] = (x);    \
          x_type [x_count++] = 1;      \
        }
#define ADD_D(x)                       \
        {                              \
          ADD_B((x)&0xFF);             \
          ADD_B(((x)>>8)&0xFF);        \
          ADD_B(((x)>>16)&0xFF);       \
          ADD_B(((x)>>24)&0xFF);       \
        }
#define ADD_BB(x,y)                    \
        {                              \
          ADD_B(x);                    \
          ADD_B(y);                    \
        }
#define ADD_BBB(x,y,z)                 \
        {                              \
          ADD_B(x);                    \
          ADD_B(y);                    \
          ADD_B(z);                    \
        }
#define ADD_BBBB(x,y,z,w)              \
        {                              \
          ADD_B(x);                    \
          ADD_B(y);                    \
          ADD_B(z);                    \
          ADD_B(w);                    \
        }
#define ADD_BD(x,y)                    \
        {                              \
          ADD_B(x);                    \
          ADD_D(y);                    \
        }
#define ADD_BBD(x,y,z)                 \
        {                              \
          ADD_B(x);                    \
          ADD_B(y);                    \
          ADD_D(z);                    \
        }
#define ADD_L(x)                       \
        {                              \
          x_value[x_count  ] = (x);    \
          x_type [x_count++] = 2;      \
        }
#define ADD_BR4(x,y)                   \
        {                              \
          ADD_B(x);                    \
          ADD_R4(y);                   \
        }
#define ADD_BR1(x,y)                   \
        {                              \
          ADD_B(x);                    \
          ADD_R1(y);                   \
        }
#define ADD_R4(x)                      \
        {                              \
          x_value[x_count  ] = (x);    \
          x_type [x_count++] = 3;      \
        }
#define ADD_R1(x)                      \
        {                              \
          x_value[x_count  ] = (x);    \
          x_type [x_count++] = 5;      \
        }
#define ADD_P()                        \
        {                              \
          x_type [x_count++] = 4;      \
        }

DWORD* ss11_len;
DWORD* ss12_len;

void pack_init(BYTE* inptr, DWORD ilen)
{
  ss11_len = (DWORD*)malloc((ilen+1)*4);
  ss12_len = (DWORD*)malloc((ilen+1)*4);
  for(DWORD q=0; q<=ilen; q++)
  {
    //
    DWORD i = q;
    int r = 0;
    if (i >= 2)
    {
      DWORD t = 4;
      i += 2;
      do {
        t <<= 1;
      } while (i >= t);
      t >>= 1;
      do {
        t >>= 1;
        r += 2;
      } while (t > 2);
    }
    ss11_len[q] = r+2;
    //
    i = q;
    r = 0;
    if (i >= 2)
    {
      DWORD t = 2;
      do {
        i -= t;
        t <<= 2;
      } while (i >= t);
      do {
        t >>= 2;
        r += 3;
      } while (t > 2);
    }
    ss12_len[q] = r+2;
  }

  graph_init(ilen);

  build_tree(inptr,ilen);

} // pack_init

void follow(int src, int i, int dst, int bitpaklen, int lmo, int off, int len)
{

  int n = g_lst[src][i]->c_pak + bitpaklen;

  struct g_entry* x = NULL;
  int skip = 0;

  for(int j=0; j<g_cnt[dst]; j++)
  {
    if (lmo == g_lst[dst][j]->c_lmo)
    {
      if (n >= g_lst[dst][j]->c_pak)
      {
        // dont add node
        skip = 1;
      }
      else
      {
        // override existing graph node
        x = g_lst[dst][j];
        break;
      }
    }
  }

  if (!skip)
  {

    if (x == NULL)
    {
      // add new node
      x = alloc_item( dst );
    }

    x->c_src  = src;
    x->c_dst  = dst;
    x->c_pak  = n;
    x->c_lmo  = lmo;
    x->c_off  = off;
    x->c_len  = len;
    x->c_prev = g_lst[src][i];
    x->c_next = NULL;  // to be calculated while building reverse path

    //printf("follow(%d-->%d, %d/%d, lmo=%d, pak=%d)\n",src,dst,off,len,lmo,n);

  }

} // follow

DWORD pack( BYTE* inptr,
            DWORD ilen,
            BYTE* outptr,
            int   build,
            int   P1,
            int   P2,
            int   P3,
            int   P4,
            int   P5 )
{
  printf("P(%d,%d,%d,%d,%d): ", P1,P2,P3,P4,P5);
  //

  BYTE*  t_outptr;
  DWORD* t_bitset;
  DWORD  t_bitcount;
  BYTE*  inptr_0 = inptr;

  alloc_item(0)->c_lmo = 1;

  //

  DWORD t0 = GetTickCount();

  // xxxxxxxxx

//#define NPASS 8
//  for(int npass=1; npass<=NPASS; npass++)
  {

    for(int i=0; i<ilen; i++)
    {

//      printf("g_nodes=%d g_total_mem_size=%d\n",g_nodes,g_total_mem_size);
//      printf("i=%d g_cnt=%d\n",i,g_cnt[i]);
//      for(int t=0; t<g_cnt[i]; t++)
//      {
//        printf(" %08x: %d-->, %d/%d, lmo=%d, pak=%d, prev=%08x\n",
//          g_lst[i][t],
//          g_lst[i][t]->c_src,
//          g_lst[i][t]->c_off,
//          g_lst[i][t]->c_len,
//          g_lst[i][t]->c_lmo,
//          g_lst[i][t]->c_pak,
//          g_lst[i][t]->c_prev );
//      }
//      printf("\n");

//      printf("\r%d x %d x %d (%d) \r",i,g_nodes,g_total_mem_size,g_cnt[i]);

      for(int ii=0; ii < g_cnt[i]; ii++)
        follow(i,ii,i+1,9,g_lst[i][ii]->c_lmo,0,0);

      for(DWORD n0=0; n0<h_cnt[i]; n0++)
      {
        DWORD n1 = h_str[i][n0];
        DWORD t_len1 = str_len[n1];

        for(DWORD n2=0; n2<str_o_cnt[n1]; n2++)
        {
          for(DWORD s_off=str_o_ptr1[n1][n2]; s_off<=str_o_ptr2[n1][n2]; s_off++)
          {
            if (s_off >= i) break;
            DWORD t_off = i - s_off;

            // process_string(t_off,t_len1)

            //printf("i=%d n0=%d n1=%d n2=%d s_off=%d\n", i,n0,n1,n2,s_off);
            //assert(memcmp(inptr+i, inptr+i-t_off, t_len1)==0);

            //DWORD t_len = t_len1;
            for(DWORD t_len=2; t_len <= t_len1; t_len++)
            {
              //assert(inptr[i+t_len-1]==inptr[i-t_off+t_len-1]);

              if ( (P1==0) ||
                   (t_len > 2) ||
                   ( (t_len == 2) && (t_off <= (P4&1?0xd00:0x500)) )
                 )
              {

                int l1,l2;
                l1 = 1;         // l1: lmo match
                l2 = 1;         // l2: new lmo
                //if (t_off == g_lst[i][0]->c_lmo)
                l1 += 2;
                if (P4&1)
                  l2 += ss11_len[1 + ((t_off - (P5?1:0)) >> P2)];
                else
                  l2 += ss12_len[1 + ((t_off - (P5?1:0)) >> P2)];
                l2 += P2;
                int t = t_len - 1 - (t_off > (P4&1?0xd00:0x500));
                int l;
                if ((P1 != 0)&&(t < (1<<P1)))
                  l = P1;
                else
                {
                  l = P1 + P3;
                  if (P4&2)
                    l += ss11_len[(t - (1<<P1)) >> P3];
                  else
                    l += ss12_len[(t - (1<<P1)) >> P3];
                }
                l1 += l;
                l2 += l;

                for(int ii=0; ii < g_cnt[i]; ii++)
                {
                  if (t_off == g_lst[i][ii]->c_lmo)
                  {
                    if (l1 <= (t_len << 3))
                      follow(i,ii,i+t_len,l1,t_off, t_off,t_len);
                  }
                  else
                  {
                    if (l2 <= (t_len << 3))
                      follow(i,ii,i+t_len,l2,t_off, t_off,t_len);
                  }
                }

              }

            }//for t_len

          } // for t_off

        } // for n2

      }//for n0

    }//for i

    // build path

    printf("nodes=%d ", g_nodes );

    int best_k = 0;
    for(int k=0; k<g_cnt[ilen]; k++)
    {
//      printf(" k=%d,pak=%d ",k,g_lst[ilen][k]->c_pak);
      if ((best_k == -1) || (g_lst[ilen][k]->c_pak < g_lst[ilen][best_k]->c_pak))
        best_k = k;
    }
    printf("end=%d bits=%d ",
      g_cnt[ilen],
      g_lst[ilen][best_k]->c_pak );

    struct g_entry* x = g_lst[ilen][best_k];
    while(1)
    {
      struct g_entry* y = x->c_prev;
      if (y == NULL) break;
      y->c_next = x;
      x = y;
    }

  } // for npass

  t_outptr   = outptr;

  *t_outptr++ = *inptr++;               // copy 1st byte as is (save 1 bit ;-)

  t_bitset   = (DWORD*)t_outptr;
  t_outptr   += 4;
  *t_bitset  = 0;
  t_bitcount = 0;

  int adc_used = 0;

  DWORD last_m_off = 1;

  struct g_entry* x = g_lst[0][0]->c_next;
  while(1)
  {
    struct g_entry* y = x->c_next;
    if (y == NULL) break;

    assert(y->c_src == x->c_dst);

    DWORD m_off = y->c_off;
    DWORD m_len = y->c_len;

//    printf("code: %d-->%d, ",y->c_src, y->c_dst);
//    if (m_len==0)
//      printf("<%02X>\n",*inptr);
//    else
//      printf("(%d,%d)\n",m_off,m_len);

    if (m_len == 0)
    {
      bbPutBit(1);
      *t_outptr++ = *inptr++;
      //ilen--;
    }
    else
    {
      inptr += m_len;
      //ilen  -= m_len;

      if (m_off > (P4&1?0xd00:0x500)) adc_used = 1;

      m_len = m_len - 1 - (m_off > (P4&1?0xd00:0x500));
      //

      bbPutBit(0);
      if (m_off == last_m_off)
      {
          bbPutBit(0);
          bbPutBit(1);
      }
      else
      {
          last_m_off = m_off;

          if (P5) m_off--;

          if (P4&1)
            code_prefix_ss11(1 + (m_off >> P2))
          else
            code_prefix_ss12(1 + (m_off >> P2));
          if (P2==8)
            *t_outptr++ = m_off;
          else
          for(int k=0; k<P2; k++)
            bbPutBit(m_off >> (P2-k-1));
      }
      if ((P1!=0)&&(m_len < (1<<P1)))
      {
          assert(m_len!=0);
          for(int k=0; k<P1; k++)
            bbPutBit(m_len >> (P1-k-1));
      }
      else
      {

          for(int k=0; k<P1; k++)
            bbPutBit(0);
          m_len -= 1<<P1;
          //
          if (P4&2)
            code_prefix_ss11(m_len >> P3)
          else
            code_prefix_ss12(m_len >> P3);

          for(k=0; k<P3; k++)
            bbPutBit(m_len >> (P3-k-1));
      }
      //

    }

    if (last_m_off != y->c_lmo)
    {
      printf("ERROR: last_m_off=%d y->c_lmo=%d y->c_src=%d   %d/%d\n",
        last_m_off,
        y->c_lmo,
        y->c_src,
        y->c_off,
        y->c_len
        );
      exit(0);
    }

    x = y;
  }

  bbPutBit(0);
  DWORD m_off=0;
  if (P5) m_off--;
  if (P4&1)
    code_prefix_ss11(1 + (m_off >> P2))
  else
    code_prefix_ss12(1 + (m_off >> P2));
  if (P2==8)
    *t_outptr++ = m_off;
  else
  for(int k=0; k<P2; k++)
    bbPutBit(m_off >> (P2-k-1));

  while(t_bitcount != 32)
    bbPutBit(0);

  //

  DWORD t1 = GetTickCount();
  int x_len = t_outptr - outptr;

  if (do_sfx)
  {
    int nosfx_len = x_len;

    // build unpacker

    DWORD*x_value = new DWORD[1024];
    DWORD*x_type  = new DWORD[1024];      // 1=byte 2=label 3=R4 4=packed 5=R1
    DWORD*x_offs  = new DWORD[1024];
    BYTE* x_data  = new BYTE[t_outptr-outptr+1024];
    DWORD x_count = 0;
    BYTE* temp = new BYTE[ ilen*2+1024 ];

    if (build)
    {
      ADD_BR4(0xE8, 0xFFFFFF01);        // call    pop_packed
      ADD_P ();
      ADD_L (0xFFFFFF01);                // pop_packed:
      ADD_B (0x5E);                      // pop     esi
      ADD_BBD(0x81,0xEC,(ilen+3)&(~3));  // sub     esp, (unpacked_size+3) & 0xfffffffc
      ADD_BB(0x89,0xE7);                 // mov     edi, esp
    }
    else
    {
      ADD_B(0x60);                       // pusha
      ADD_BR4(0xE8, 0xFFFFFF01);         // call    pop_packed
      ADD_P ();
      ADD_L (0xFFFFFF01);                // pop_packed:
      ADD_B (0x5E);                      // pop     esi
      ADD_BD(0xBF, (DWORD)temp);         // mov     edi, <temp>
    }

    ADD_BB(0x6A,0xFF);                   // push    -1
    ADD_B(0x5D);                         // pop     ebp

    ADD_BR4(0xE8,0xFFFFFF02);            // call    __pop_getbit
    ADD_BB(0x01,0xDB);                   // add     ebx, ebx
    ADD_BR1(0x75,0xFFFFFF03);            // jnz     __x1
    ADD_BB(0x8B,0x1E);                   // mov     ebx, [esi]
    ADD_BBB(0x83,0xee,0xfc);             // sub     esi, -4
    ADD_BB(0x13,0xDB);                   // adc     ebx, ebx
    ADD_L(0xFFFFFF03);                   // __x1:
    ADD_B(0xC3);                         // retn
    ADD_L(0xFFFFFF02);                   // __pop_getbit:

    ADD_BB(0x31,0xDB);                   // xor     ebx, ebx

    ADD_L(0xFFFFFF06);                   // __decompr_literals_n2b:
    ADD_B(0xA4);                         // movsb
    ADD_L(0xFFFFFF07);                   // __decompr_loop_n2b:
    ADD_BBB(0xFF,0x14,0x24);             // call    dword ptr [esp] ; getbit
    ADD_BR1(0x72,0xFFFFFF06);            // jc      __decompr_literals_n2b

    ADD_BB(0x33,0xC0);                   // xor     eax, eax
    ADD_B(0x40);                         // inc     eax
    ADD_L(0xFFFFFF0A);                   // __loop1_n2b:
    if (P4&1) // s11
    {
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC0);                 // adc     eax, eax
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BR1(0x73,0xFFFFFF0A);          // jnc     __loop1_n2b
    }
    else // s12
    {
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC0);                 // adc     eax, eax
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BR1(0x72,0xFFFFFF1A);          // jc      __loopend1_n2d
      ADD_B(0x48);                       // dec     eax
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC0);                 // adc     eax, eax
      ADD_BR1(0xEB,0xFFFFFF0A);          // jmp     __loop1_n2b
      ADD_L(0xFFFFFF1A);                 // __loopend1_n2d:
    }

    ADD_BB(0x31,0xC9);                   // xor     ecx, ecx

    ADD_BBB(0x83,0xE8,0x03);             // sub     eax, 3
    ADD_BR1(0x72,0xFFFFFF0B);            // jc     __decompr_ebpeax_n2b

    if (P2==0)
    {
    }
    else
    if (P2==1)
    {
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC0);                 // adc     eax, eax
    }
    else
    if (P2==8)
    {
      ADD_BBB(0xC1,0xE0,0x08);           // shl     eax, 8
      ADD_B(0xAC);                       // lodsb
    }
    else
    {
      ADD_BB(0xB1,P2);                   // mov     cl, P2
      ADD_L(0xFFFFFF0D);                 // __q1:
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC0);                 // adc     eax, eax
      ADD_BR1(0xE2,0xFFFFFF0D);          // loop    __q1
    }

    if (!P5)
    {
      ADD_B(0x48);                       // dec     eax
    }

    ADD_BBB(0x83,0xF0,0xFF);             // xor     eax, -1
    ADD_BR1(0x74,0xFFFFFF08);            // jz     __decompr_end_n2b

    ADD_B(0x95);                         // xchg    ebp, eax

    ADD_L(0xFFFFFF0B);                   // __decompr_ebpeax_n2b:

    if (P1==0)
    {
    }
    else
    if (P1==1)
    {
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC9);                 // adc     ecx, ecx
      ADD_BR1(0x75,0xFFFFFF09);          // jnz     __decompr_got_mlen_n2b
    }
    else
    if (P1==2)
    {
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC9);                 // adc     ecx, ecx
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC9);                 // adc     ecx, ecx
      ADD_BR1(0x75,0xFFFFFF09);          // jnz     __decompr_got_mlen_n2b
    }
    else
    {
      ADD_BB(0x33,0xC0);                 // xor     eax, eax
      ADD_BB(0xB1,P1);                   // mov     cl, P1
      ADD_L(0xFFFFFF0E);                 // __q2:
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC0);                 // adc     eax, eax
      ADD_BR1(0xE2,0xFFFFFF0E);          // loop    __q2
      ADD_BB(0x01,0xC1);                 // add     ecx, eax
      ADD_BR1(0x75,0xFFFFFF09);          // jnz     __decompr_got_mlen_n2b
    }

    ADD_B(0x41);                         // inc     ecx
    ADD_L(0xFFFFFF0C);                   // __loop2_n2b:
    if (P4&2) // s11
    {
      ADD_BBB(0xFF,0x14,0x24);             // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC9);                   // adc     ecx, ecx
      ADD_BBB(0xFF,0x14,0x24);             // call    dword ptr [esp] ; getbit
      ADD_BR1(0x73,0xFFFFFF0C);            // jnc     __loop2_n2b
    }
    else
    {
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC9);                 // adc     ecx, ecx
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BR1(0x72,0xFFFFFF1B);          // jc      __loop2end
      ADD_B(0x49);                       // dec     ecx
      ADD_BBB(0xFF,0x14,0x24);           // call    dword ptr [esp] ; getbit
      ADD_BB(0x11,0xC9);                 // adc     ecx, ecx
      ADD_BR1(0xEB,0xFFFFFF0C);          // jmp     __loop2_n2b
      ADD_L(0xFFFFFF1B);                 // __loop2end:
    }

    int adc_ecx = 1;

    if (P3)
    {
      ADD_B(0x49);                       // dec     ecx
      ADD_B(0x49);                       // dec     ecx

      if (P3==1)
      {
        ADD_BBB(0xFF,0x14,0x24);         // call    dword ptr [esp] ; getbit
        ADD_BB(0x11,0xC9);               // adc     ecx, ecx
      }
      else
      if (P3==2)
      {
        ADD_BBB(0xFF,0x14,0x24);         // call    dword ptr [esp] ; getbit
        ADD_BB(0x11,0xC9);               // adc     ecx, ecx
        ADD_BBB(0xFF,0x14,0x24);         // call    dword ptr [esp] ; getbit
        ADD_BB(0x11,0xC9);               // adc     ecx, ecx
      }
      else // P3 >= 3
      {
        ADD_BB(0x6A,P3);                 // push    P3
        ADD_B(0x58);                     // pop     eax
        ADD_L(0xFFFFFF0F);               // __q3:
        ADD_BBB(0xFF,0x14,0x24);         // call    dword ptr [esp] ; getbit
        ADD_BB(0x11,0xC9);               // adc     ecx, ecx
        ADD_B(0x48);                     // dec     eax
        ADD_BR1(0x75,0xFFFFFF0F);        // jnz     __q3
      }

      if (P1==0)
      {
        ADD_B(0x41);                     // inc     ecx
      }
      else
      if (P1==1)
      {
        ADD_B(0x41);                     // inc     ecx
        ADD_B(0x41);                     // inc     ecx
      }
      else // P1>=2
      if (P1<=6)
      {
        ADD_BBB(0x83,0xC1,(1<<P1));      // add     ecx, (1<<P1)
      }
      else // P1>=7
      {
        ADD_BBD(0x81,0xC1,(1<<P1));      // add     ecx, (1<<P1)
      }

    }
    else
    {
      if (P1==0)
      {
        adc_ecx = 0;
        // ADD_B(0x49);                   // dec     ecx
      }
      else
      if (P1==1)
      {
      }
      else
      if (P1==2)
      {
        ADD_B(0x41);                     // inc     ecx
        ADD_B(0x41);                     // inc     ecx
      }
      else // P1=3..7
      if (P1<=7)
      {
        ADD_BBB(0x83,0xC1,(1<<P1)-2);    // add     ecx, (1<<P1)
      }
      else // P1>=8
      {
        ADD_BBD(0x81,0xC1,(1<<P1)-2);      // add     ecx, (1<<P1)
      }
    }

    ADD_L(0xFFFFFF09);                   // __decompr_got_mlen_n2b:

    if (adc_used)
    {
      ADD_BBD(0x81,0xFD,((P4&1?-0xd00:-0x500)));   // cmp     ebp, -0?00h
      ADD_BBB(0x83,0xD1,adc_ecx);          // adc     ecx, <0|1>
    }
    else
    {
      if (adc_ecx == 1)
        ADD_B(0x41);                     // inc     ecx
    }

    ADD_B(0x56);                         // push    esi
    ADD_BBB(0x8d,0x34,0x2f);             // lea     esi, [edi+ebp]
    ADD_BB(0xf3,0xa4);                   // rep     movsb
    ADD_B(0x5E);                         // pop     esi
    ADD_BR1(0xEB,0xFFFFFF07);            // jmp     __decompr_loop_n2b

    ADD_L(0xFFFFFF08);                   // __decompr_end_n2b:

    ADD_B(0x59);                         // pop     ecx     ; free ptr to getbit

    if (build)
    {
      ADD_BB(0xFF,0xE4);                 // jmp     esp
    }
    else
    {
      ADD_BBBB(0x89,0x7c,0x24,0x1c);     // mov     [esp+28], edi
      ADD_B(0x61);                       // popa
      ADD_B(0xC3);                       // retn
    }

    // link -- pass 1/2 -- build code

    x_len = 0;
    for(int i=0; i<x_count; i++)
    {
      if (x_type[i]==4) // packed
      {
        memcpy(x_data+x_len,outptr,t_outptr-outptr);
        x_len += t_outptr-outptr;
      }
      else
      if ((x_type[i]==1)||(x_type[i]==5))  // BYTE or R1
      {
        x_offs[i] = x_len;
        x_data[x_len++] = x_value[i];
      }
      else
      if (x_type[i]==3)   // R4
      {
        x_offs[i] = x_len;
        x_len += 4;
      }
      else
      if (x_type[i]==2) // LABEL
      {
        x_offs[i] = x_len;
      }
    }

    // link -- pass 2/2 -- fix rel. jmps

    for(i=0; i<x_count; i++)
    {
      DWORD dst=0;
      if ((x_type[i]==5)||(x_type[i]==3)) // R1,R4
      {
        for(int j=0; j<x_count; j++)
          if (x_type[j]==2) // LABEL
          if (x_value[j]==x_value[i])
          {
            dst=x_offs[j];
            break;
          }
        assert(dst);
      }
      if (x_type[i]==5) // R1
        x_data[x_offs[i]] = dst - (x_offs[i]+1);
      else
      if (x_type[i]==3) // R4
        *(DWORD*)&x_data[x_offs[i]] = dst - (x_offs[i]+4);
    }

    if (!build)
    {
      // call generated unpacker && verify unpacked data
      typedef DWORD (__cdecl* functype)(void);
      memset(temp, 0x00, ilen);
      DWORD temp_len = ((functype)x_data)() - (DWORD)temp;
      if (temp_len != ilen)
      {
        printf("verify SIZE error (got %d,need %d)\n",temp_len,ilen);
        FILE*f=fopen("_verify.data","wb");
        fwrite(temp,1,temp_len,f);
        fclose(f);
        exit(0);
      }
      if (memcmp(inptr_0, temp, ilen) != 0)
      {
        printf("verify DATA error, g_nodes=%d\n", g_nodes);
        FILE*f=fopen("_verify.data","wb");
        fwrite(temp,1,temp_len,f);
        fclose(f);
        exit(0);
      }
    }

    memcpy(outptr, x_data, x_len);

    delete temp;
    delete x_value;
    delete x_type;
    delete x_offs;
    delete x_data;

    printf("sfx=%d ",x_len-nosfx_len);

  } // if (do_sfx)

  //

  printf("bytes=%d time=%d\n", x_len, t1-t0);

  graph_empty(ilen);

  return x_len;

} // pack

void pack_done(DWORD ilen)
{

  done_tree(ilen);

  graph_done(ilen);

  printf("+ releasing allocated memory (main)\n");

  free(ss11_len);
  free(ss12_len);

} // pack_done

void help()
{
  printf("syntax:\n");
  printf("  snippetupxs [options] infile outfile\n");
  printf("options:\n");
  printf("  minP1 maxP1 minP2 maxP2 ... minP5 maxP5   # specify bruteforce ranges\n");
  printf("  --nosfx   # disable adding sfx\n");
  exit(0);
}

void main(int argc, char* argv[])
{
  printf("upx for code snippets (x86,32-bit)  v2.00s  (x) 2004\n");

  char* infile  = 0;
  char* outfile = 0;

  int a_P1=0, b_P1=3,
      a_P2=0, b_P2=8,
      a_P3=0, b_P3=4,
      a_P4=0, b_P4=3,
      a_P5=0, b_P5=1;
  int n = 0;

  for(int i=1; i<argc; i++)
  {
    char*s = argv[i];
    int v = atoi(s);
    if (!stricmp(s, "--nosfx")) do_sfx = 0; else
    if (!strcmp(s,"0") || v)
    {
      if (n == 0) { a_P1=v; n++; } else
      if (n == 1) { b_P1=v; n++; } else
      if (n == 2) { a_P2=v; n++; } else
      if (n == 3) { b_P2=v; n++; } else
      if (n == 4) { a_P3=v; n++; } else
      if (n == 5) { b_P3=v; n++; } else
      if (n == 6) { a_P4=v; n++; } else
      if (n == 7) { b_P4=v; n++; } else
      if (n == 8) { a_P5=v; n++; } else
      if (n == 9) { b_P5=v; n++; } else help();
    } else
    if (infile  == 0) infile  = s; else
    if (outfile == 0) outfile = s; else
      help();
  }
  if (!infile || !outfile) help();

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

  BYTE* obuf = new BYTE[ ilen+(ilen>>3)+1024 ];
  BYTE* xbuf = new BYTE[ ilen+1024 ];
  DWORD olen=0, xlen=0;

  pack_init(ibuf,ilen);

  int min_olen = -1;
  int min_P1;
  int min_P2;
  int min_P3;
  int min_P4;
  int min_P5;

  printf("+ trying: (%d..%d, %d..%d, %d..%d, %d..%d, %d..%d)\n",
    a_P1,b_P1,
    a_P2,b_P2,
    a_P3,b_P3,
    a_P4,b_P4,
    a_P5,b_P5 );

  for(int P1=a_P1; P1<=b_P1; P1++)
  for(int P2=a_P2; P2<=b_P2; P2++)
  for(int P3=a_P3; P3<=b_P3; P3++)
  for(int P4=a_P4; P4<=b_P4; P4++)
  for(int P5=a_P5; P5<=b_P5; P5++)
  {
    if (P5 && (P2<=1)) continue;

    printf("(%d) ",min_olen);

    olen = pack(ibuf,ilen,obuf,0,P1,P2,P3,P4,P5);

    if ((min_olen == -1) || (min_olen > olen))
    {
      min_olen = olen;
      min_P1   = P1;
      min_P2   = P2;
      min_P3   = P3;
      min_P4   = P4;
      min_P5   = P5;
      //printf(".best\n");
    }
  }

  printf("+ packing best\n");

  olen = pack(ibuf,ilen,obuf,1,min_P1,min_P2,min_P3,min_P4,min_P5);

  pack_done(ilen);

  FILE*f2=fopen(outfile,"wb");
  if (f2==NULL)
  {
    printf("ERROR: cant write: %s\n", outfile);
    exit(0);
  }
  printf("+ writing: [%s], %d bytes\n", outfile, olen);
  fwrite(obuf,1,olen,f2);
  fclose(f2);

  delete ibuf;
  delete obuf;
  delete xbuf;

} // main
