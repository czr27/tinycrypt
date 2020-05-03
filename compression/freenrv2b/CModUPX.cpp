
// CModUPX class,
// UPX-like compression

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

typedef struct upx_entry : GRAPH_ENTRY
{
  DWORD c_off;
  DWORD c_len;
  DWORD c_lmo;
} UPX_ENTRY;

#define UPX_GRAPH_ENTRY(x,y)  ((UPX_ENTRY*)((void*)Graph->g_lst[x][y]))
#define UPX_GRAPH_ALLOC(idx)  ((UPX_ENTRY*)((void*)Graph->alloc_item(idx)))

class CModUPX : public CModule
{
  public:

  CModUPX();
  ~CModUPX() {};

  virtual void ModInit();
  virtual void ModDone();
  virtual DWORD Pack(BYTE* inptr, DWORD ilen, BYTE* outptr);
  virtual int ParseOption(char* s);

  private:

  DWORD* ss11_len;
  DWORD* ss12_len;

  void follow(int src, int i, int dst, int bitpaklen, int lmo, int off, int len);
  DWORD PackReal(BYTE* inptr, DWORD ilen, BYTE* outptr, int dosfx, int build,
                 int P1, int P2, int P3, int P4, int P5);

  int opt_dosfx,
      a_n,
      a_P1, b_P1,
      a_P2, b_P2,
      a_P3, b_P3,
      a_P4, b_P4,
      a_P5, b_P5;

}; // class CModUPX

CModUPX::CModUPX() : CModule( sizeof(UPX_ENTRY) )
{
  opt_dosfx = 1;
  a_n = 0;
  a_P1=0; b_P1=3;
  a_P2=0; b_P2=8;
  a_P3=0; b_P3=4;
  a_P4=0; b_P4=3;
  a_P5=0; b_P5=1;
}

void CModUPX::ModInit()
{

  //

  ss11_len = (DWORD*)malloc((Dict->ilen+1)*4);
  ss12_len = (DWORD*)malloc((Dict->ilen+1)*4);

  for(DWORD q=0; q<=Dict->ilen; q++)
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

} // CModUPX::ModInit

void CModUPX::ModDone()
{

  free(ss11_len);
  free(ss12_len);

} // CModUPX::ModDone

void CModUPX::follow(int src, int i, int dst, int bitpaklen, int lmo, int off, int len)
{

  int n = UPX_GRAPH_ENTRY(src,i)->c_pak + bitpaklen;

  UPX_ENTRY* x = NULL;
  int skip = 0;

  for(int j=0; j<Graph->g_cnt[dst]; j++)
  {
    if (lmo == UPX_GRAPH_ENTRY(dst,j)->c_lmo)
    {
      if (n >= UPX_GRAPH_ENTRY(dst,j)->c_pak)
      {
        // dont add node
        skip = 1;
      }
      else
      {
        // override existing graph node
        x = UPX_GRAPH_ENTRY(dst,j);
        break;
      }
    }
  }

  if (!skip)
  {

    if (x == NULL)
    {
      // add new node
      x = UPX_GRAPH_ALLOC(dst);
    }

    x->c_src  = src;
    x->c_dst  = dst;
    x->c_prev = UPX_GRAPH_ENTRY(src,i);
    x->c_next = NULL;  // to be calculated while building reverse path

    x->c_pak  = n;
    x->c_lmo  = lmo;
    x->c_off  = off;
    x->c_len  = len;

    //printf("follow(%d-->%d, %d/%d, lmo=%d, pak=%d)\n",src,dst,off,len,lmo,n);

  }

} // CModUPX::follow

DWORD CModUPX::Pack( BYTE* inptr,
                     DWORD ilen,
                     BYTE* outptr)
{

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

    DWORD olen = PackReal(inptr,ilen,outptr,1,0,P1,P2,P3,P4,P5);

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

  return PackReal(inptr,ilen,outptr,opt_dosfx,1,min_P1,min_P2,min_P3,min_P4,min_P5);

} // CModUPX::Pack

DWORD CModUPX::PackReal( BYTE* inptr,
                         DWORD ilen,
                         BYTE* outptr,
                         int   dosfx,
                         int   build,
                         int   P1,
                         int   P2,
                         int   P3,
                         int   P4,
                         int   P5)
{
  printf("P(%d,%d,%d,%d,%d): ", P1,P2,P3,P4,P5);
  //

  BYTE*  t_outptr;
  DWORD* t_bitset;
  DWORD  t_bitcount;
  BYTE*  inptr_0 = inptr;

  UPX_GRAPH_ALLOC(0)->c_lmo = 1;

  DWORD t0 = GetTickCount();

  for(int i=0; i<ilen; i++)
  {

    for(int ii=0; ii < Graph->g_cnt[i]; ii++)
      follow(i,ii,i+1,9,UPX_GRAPH_ENTRY(i,ii)->c_lmo,0,0);

    FOR_EACH_MATCH_BEGIN(Dict,i,s_off,t_len1)
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

              for(int ii=0; ii < Graph->g_cnt[i]; ii++)
              {
                if (t_off == UPX_GRAPH_ENTRY(i,ii)->c_lmo)
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

    }
    FOR_EACH_MATCH_END;

  }//for i

  // build reverse path

  DWORD best_k = Graph->ReversePath(NULL);

  printf("nodes=%d end=%d bits=%d ",
    Graph->nodes,
    Graph->g_cnt[ilen],
    UPX_GRAPH_ENTRY(ilen,best_k)->c_pak );

  t_outptr   = outptr;

  *t_outptr++ = *inptr++;               // copy 1st byte as is (save 1 bit ;-)

  t_bitset   = (DWORD*)t_outptr;
  t_outptr   += 4;
  *t_bitset  = 0;
  t_bitcount = 0;

  int adc_used = 0;

  DWORD last_m_off = 1;

  UPX_ENTRY* x = (UPX_ENTRY*) UPX_GRAPH_ENTRY(0,0)->c_next;
  while(1)
  {
    UPX_ENTRY* y = (UPX_ENTRY*) x->c_next;
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
  DWORD out_len = t_outptr - outptr;

  if (dosfx)
  {

    CSfx* Sfx = new CSfx;
    assert(Sfx);

    Sfx->Init(outptr,out_len,2048);

    // build sfx decryptor

    //ADD_B(0xcc);

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
      ADD_BBBB(0x8B,0x7C,0x24,0x24);     // mov     edi, [esp+32+4]
      ADD_BR4(0xE8, 0xFFFFFF01);         // call    pop_packed
      ADD_P ();
      ADD_L (0xFFFFFF01);                // pop_packed:
      ADD_B (0x5E);                      // pop     esi
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
      ADD_BBBB(0x2B,0x7C,0x24,0x24);     // sub     edi, [esp+32+4]
      ADD_BBBB(0x89,0x7c,0x24,0x1c);     // mov     [esp+POPA.EAX], edi
      ADD_B(0x61);                       // popa
      ADD_B(0xC3);                       // retn
    }

    // link sfx decryptor

    Sfx->Link();

    // call generated unpacker && verify unpacked data

    if (!build)
    {
      if (Sfx->Verify(inptr_0,ilen) != 0)
      {
        printf("SFX VERIFY ERROR\n");
        exit(0);
      }
    }

    // copy <compressed+decryptor> into outptr

    memcpy(outptr, Sfx->x_data, Sfx->x_len);
    out_len = Sfx->x_len;

    // free CSfx

    Sfx->Done();
    delete Sfx;

    printf("sfx=%d ",out_len-(t_outptr-outptr));

  } // if (do_sfx)

  printf("bytes=%d time=%d\n", out_len, t1-t0);

  Graph->empty();

  return out_len;

} // CModUPX::PackReal

int CModUPX::ParseOption(char* s)
{
  if (!stricmp(s, "--nosfx")) { opt_dosfx = 0; return 1; }

  int v = atoi(s);
  if (!strcmp(s,"0") || v)
  {
    if (a_n == 0) { a_P1=v; a_n++; return 1; }
    if (a_n == 1) { b_P1=v; a_n++; return 1; }
    if (a_n == 2) { a_P2=v; a_n++; return 1; }
    if (a_n == 3) { b_P2=v; a_n++; return 1; }
    if (a_n == 4) { a_P3=v; a_n++; return 1; }
    if (a_n == 5) { b_P3=v; a_n++; return 1; }
    if (a_n == 6) { a_P4=v; a_n++; return 1; }
    if (a_n == 7) { b_P4=v; a_n++; return 1; }
    if (a_n == 8) { a_P5=v; a_n++; return 1; }
    if (a_n == 9) { b_P5=v; a_n++; return 1; }
  }

  return 0;

} // CModUPX::ParseOption
