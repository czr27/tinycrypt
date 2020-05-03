
// CModLZ class,
// LZ-like compression

// packing codes format:
// <1>
//     <0>  <orig_byte>
//     <1>  <orig_dword>
// <0>
//      <0>  <off:P1>    off==0 ? EOF
//      <1>  <off:P2>
//   &&
//      <0>  <(len-2):P3>
//      <10> <(len-2):P4>
//      <11> <(len-2):P5>

typedef struct lz_entry : GRAPH_ENTRY
{
  DWORD c_off;
  DWORD c_len;
  //DWORD c_state;
} LZ_ENTRY;

#define LZ_GRAPH_ENTRY(x,y)  ((LZ_ENTRY*)((void*)Graph->g_lst[x][y]))
#define LZ_GRAPH_ALLOC(idx)  ((LZ_ENTRY*)((void*)Graph->alloc_item(idx)))

class CModLZ : public CModule
{
  public:

  CModLZ();
  ~CModLZ() {};

  virtual void ModInit();
  virtual void ModDone();
  virtual DWORD Pack(BYTE* inptr, DWORD ilen, BYTE* outptr);
  virtual int ParseOption(char* s);

  private:

  void follow(int src, int i, int dst, int bitpaklen, int off, int len);
  DWORD PackReal(BYTE* inptr, DWORD ilen, BYTE* outptr, int dosfx, int build,
                 int P1, int P2, int P3, int P4, int P5);

  int opt_dosfx,
      a_n,
      a_P1, b_P1,
      a_P2, b_P2,
      a_P3, b_P3,
      a_P4, b_P4,
      a_P5, b_P5;

}; // class CModLZ

CModLZ::CModLZ() : CModule( sizeof(LZ_ENTRY) )
{
  opt_dosfx = 1;
  a_n = 0;
  a_P1=5; b_P1=13;
  a_P2=1; b_P2=13;
  a_P3=1; b_P3=9;
  a_P4=1; b_P4=9;
  a_P5=1; b_P5=9;
}

void CModLZ::ModInit()
{
} // CModLZ::ModInit

void CModLZ::ModDone()
{
} // CModLZ::ModDone

void CModLZ::follow(int src, int i, int dst, int bitpaklen, int off, int len)
{
  // 1. this subroutine will add new graph node, or overwrite existing one.
  // 2. we "follow" (i.e. add/overwrite link) from (src,i) to (dst,0..j)
  // 3. in case

  int n = LZ_GRAPH_ENTRY(src,i)->c_pak + bitpaklen;

  LZ_ENTRY* x = NULL;
  int skip = 0;

  for(int j=0; j<Graph->g_cnt[dst]; j++)
  {
    if (n >= LZ_GRAPH_ENTRY(dst,j)->c_pak)
    {
      // skip adding node
      skip = 1;
    }
    else
    {
      // overwrite existing node
      x = LZ_GRAPH_ENTRY(dst,j);
    }
  }

  if (!skip)
  {

    if (x == NULL)
    {
      // add new node
      x = LZ_GRAPH_ALLOC(dst);
    }

    x->c_src  = src;
    x->c_dst  = dst;
    x->c_prev = LZ_GRAPH_ENTRY(src,i);
    x->c_next = NULL;  // to be calculated while building reverse path

    x->c_pak  = n;
    x->c_off  = off;
    x->c_len  = len;

    //printf("follow(%d-->%d, %d/%d, lmo=%d, pak=%d)\n",src,dst,off,len,lmo,n);

  }

} // CModLZ::follow

DWORD CModLZ::Pack( BYTE* inptr,
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
  for(int P2=MAX(P1+1,a_P2); P2<=b_P2; P2++)
  for(int P3=a_P3; P3<=b_P3; P3++)
  for(int P4=MAX(P3+1,a_P4); P4<=b_P4; P4++)
  for(int P5=MAX(P4+1,a_P5); P5<=b_P5; P5++)
  {
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

  return PackReal(inptr,ilen,outptr,opt_dosfx,1,
                  min_P1,min_P2,min_P3,min_P4,min_P5);

} // CModLZ::Pack

DWORD CModLZ::PackReal( BYTE* inptr,
                        DWORD ilen,
                        BYTE* outptr,
                        int   dosfx,
                        int   build,
                        int   P1,
                        int   P2,
                        int   P3,
                        int   P4,
                        int   P5 )
{
  printf("P(%d,%d,%d,%d,%d): ", P1,P2,P3,P4,P5);
  //
  assert(P2>P1);
  assert(P4>P3);
  assert(P5>P4);

  BYTE*  t_outptr;
  DWORD* t_bitset;
  DWORD  t_bitcount;
  BYTE*  inptr_0 = inptr;

  //LZ_GRAPH_ALLOC(0)->c_lmo = 1;

  DWORD t0 = GetTickCount();

  LZ_GRAPH_ALLOC(0)->c_len = 0;

  for(int i=0; i<ilen; i++)
  {

    for(int ii=0; ii < Graph->g_cnt[i]; ii++)
    {
      if (i+1 <= ilen) follow(i,ii,i+1,1+1+8*1,0,1);
      if (i!=0) // 'coz 1st thing we encode is always 1 byte (MOVSB)
      if (i+4 <= ilen) follow(i,ii,i+4,1+1+8*4,0,4);
    }

    FOR_EACH_MATCH_BEGIN(Dict,i,s_off,t_len1)
    {
      if (s_off >= i) break;
      DWORD t_off = i - s_off;

//      assert(memcmp(inptr+i, inptr+i-t_off, t_len1) == 0);

      if (t_off < (1<<P2))

      for(DWORD t_len=2; t_len <= t_len1; t_len++)
      {
        int l0;
        if (t_off < (1<<P1))
          l0 = 2 + P1;
        else
          l0 = 2 + P2;

        if (t_len-2 < (1<<P3))
        {
          int l = l0 + 1 + P3;
          if (l <= (t_len << 3))
          for(int ii=0; ii < Graph->g_cnt[i]; ii++)
            follow(i,ii,i+t_len,l, t_off,t_len);
        }
        else
        if (t_len-2 < (1<<P4))
        {
          int l = l0 + 2 + P4;
          if (l <= (t_len << 3))
          for(int ii=0; ii < Graph->g_cnt[i]; ii++)
            follow(i,ii,i+t_len,l, t_off,t_len);
        }
        else
        if (t_len-2 < (1<<P5))
        {
          int l = l0 + 2 + P5;
          if (l <= (t_len << 3))
          for(int ii=0; ii < Graph->g_cnt[i]; ii++)
            follow(i,ii,i+t_len,l, t_off,t_len);
        }
      }//for t_len

    }
    FOR_EACH_MATCH_END;

  }//for i

  // build reverse path

  assert(Graph->g_cnt[ilen] > 0);

  DWORD best_k = Graph->ReversePath(NULL);

  printf("nodes=%d end=%d bits=%d ",
    Graph->nodes,
    Graph->g_cnt[ilen],
    LZ_GRAPH_ENTRY(ilen,best_k)->c_pak );

  t_outptr   = outptr;

  *t_outptr++ = *inptr++;               // copy 1st byte as is (save 1 bit ;-)
  t_bitset   = (DWORD*)t_outptr;
  t_outptr   += 4;
  *t_bitset  = 0;
  t_bitcount = 0;

  assert(Graph->g_cnt[0] > 0);
  LZ_ENTRY* x = (LZ_ENTRY*) LZ_GRAPH_ENTRY(0,0)->c_next;
  assert(x);
  while(1)
  {
    LZ_ENTRY* y = (LZ_ENTRY*) x->c_next;
    if (y == NULL) break;

    assert(y->c_src == x->c_dst);

    DWORD m_off = y->c_off;
    DWORD m_len = y->c_len;

//    if (memcmp(inptr, inptr-m_off, m_len) != 0)
//    {
//      printf("%08x: (%d,%d) -- match error\n", inptr-inptr_0, m_off,m_len);
//      exit(0);
//    }

    if (m_off == 0)
    {

      bbPutBit(1);
      if (m_len == 1)
      {
        //printf("%08x: <%02x>\n", inptr-inptr_0, inptr[0]);
        bbPutBit(0);
        *t_outptr++ = *inptr++;
      }
      else
      {
        //printf("%08x: <%08x>\n", inptr-inptr_0, *(DWORD*)&inptr[0]);
        assert(m_len == 4);
        bbPutBit(1);
        *t_outptr++ = *inptr++;
        *t_outptr++ = *inptr++;
        *t_outptr++ = *inptr++;
        *t_outptr++ = *inptr++;
      }
    }
    else
    {
      //printf("%08x: (%d,%d)\n", inptr-inptr_0, m_off,m_len);

      inptr += m_len;
      //ilen  -= m_len;

      bbPutBit(0);

      if (m_off < (1<<P1))
      {
        bbPutBit(0);
        for(int k=0; k<P1; k++)
          bbPutBit(m_off >> (P1-k-1));
      }
      else
      {
        assert(m_off < (1<<P2));
        bbPutBit(1);
        for(int k=0; k<P2; k++)
          bbPutBit(m_off >> (P2-k-1));
      }

      if (m_len-2 < (1<<P3))
      {
        m_len = m_len - 2;
        assert(m_len < (1<<P3));
        bbPutBit(0);
        for(int k=0; k<P3; k++)
          bbPutBit(m_len >> (P3-k-1));
      }
      else
      if (m_len-2 < (1<<P4))
      {
        m_len = m_len - 2;
        assert(m_len < (1<<P4));
        bbPutBit(1);
        bbPutBit(0);
        for(int k=0; k<P4; k++)
          bbPutBit(m_len >> (P4-k-1));
      }
      else
      {
        m_len = m_len - 2;
        assert(m_len < (1<<P5));
        bbPutBit(1);
        bbPutBit(1);
        for(int k=0; k<P5; k++)
          bbPutBit(m_len >> (P5-k-1));
      }

    }

    x = y;
  }

  // put EOF code
  bbPutBit(0);
  bbPutBit(0);
  for(int k=0; k<P1; k++)
    bbPutBit(0);

  while(t_bitcount != 32)
    bbPutBit(0);

  DWORD t1 = GetTickCount();
  DWORD out_len = t_outptr - outptr;

  if (dosfx)
  {

    CSfx* Sfx = new CSfx;
    assert(Sfx);

    Sfx->Init(outptr,out_len,2048);

    // build sfx decryptor

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
      ADD_BBBB(0x8B,0x7C,0x24,0x24);     // mov     edi, [esp+32+4]
    }

    //
    // input:  ECX = <length>-1, in BIT's
    // output: ECX = 0
    //         EAX = number of <length> bits
    // uses:   EBX = current bitset
    //         ESI = bit stream
    //

    ADD_BR4(0xE8,0xFFFFFF04);            // call    __pop_getbits
    ADD_BB(0x31,0xC0);                   // xor     eax, eax
    ADD_B(0x41);                         // inc     ecx
    ADD_L(0xFFFFFF05);                   // __cl_cycle:
    ADD_BB(0x01,0xDB);                   // add     ebx, ebx
    ADD_BR1(0x75,0xFFFFFF03);            // jnz     __x1
    ADD_BB(0x8B,0x1E);                   // mov     ebx, [esi]
    ADD_BBB(0x83,0xee,0xfc);             // sub     esi, -4
    ADD_BB(0x13,0xDB);                   // adc     ebx, ebx
    ADD_L(0xFFFFFF03);                   // __x1:
    ADD_BB(0x11,0xC0);                   // adc     eax, eax
    ADD_BR1(0xE2,0xFFFFFF05);            // loop    __cl_cycle
    ADD_B(0xC3);                         // retn
    ADD_L(0xFFFFFF04);                   // __pop_getbits:
    ADD_B(0x5D);                         // pop     ebp

    // init regs

    ADD_BB(0x31,0xC9);                   // xor     ecx, ecx
    ADD_BB(0x31,0xDB);                   // xor     ebx, ebx

    // lets go

    ADD_L(0xF0000001);                   // __copy_byte:

    ADD_B(0xA4);                         // movsb

    ADD_L(0xF0000000);                   // __main_cycle:

    ADD_BB(0xFF,0xD5);                   // call    ebp   ; getbits
    ADD_BR1(0x74,0xF0000002);            // jz      __copy_string

    ADD_BB(0xFF,0xD5);                   // call    ebp   ; getbits
    ADD_BR1(0x74,0xF0000001);            // jz      __copy_byte

    ADD_B(0xA5);                         // movsd

    ADD_BR1(0xEB,0xF0000000);            // jmp     __main_cycle

    ADD_L(0xF0000002);                   // __copy_string:

//      <0>  <off:P1>    off==0 ? EOF
//      <1>  <(off-(1<<P1)):P2>
//   &&
//      <0>  <(len-2):P3>
//      <10> <(len-2-(1<<P3)):P4>
//      <11> <(len-2-(1<<P4)):P5>

    // 1. get offset into EDX

    ADD_BB(0xFF,0xD5);                   // call    ebp   ; getbits

    // i: eax=0|1
    //    ecx=0
    // o: ecx=(P1-1)|(P2-1)
    //    edx=0|(1<<P1)

    if (P1==P2)
    {
      if (P1==1)
        ;
      else
      if (P1==2)
        ADD_B(0x41)                      // inc     ecx
      else // P1>=3
        ADD_BB(0xB1, P1-1)               // mov     cl, P1-1
    }
    else
    {

      if (P2-P1==1)
      {
        // do nothing, eax=delta=0|1
      }
      else
      if (P2-P1==2)
      {
        ADD_BB(0xd1,0xe0);               // shl     eax, 1   ; eax=delta=0|2
      }
      else // (P2-P1>=3)
      {
        ADD_BBB(0x6B,0xC0,P2-P1);        // imul    eax, eax, imm8  ; eax=delta=0|(P2-P1)
      }

      if (P1==1)
      {
        // 0|1
      }
      else
      if (P1==2)
        ADD_B(0x40)                      // inc     eax    ; 1|(1+delta)
      else // (P1>=3)
        ADD_BB(0x04,P1-1)                // add     al, P1-1  ; (P1-1)|(P1-1+delta)

      ADD_B(0x91);                       // xchg    ecx, eax  ; ecx=(P1-1)|(P2-1)

    }

    ADD_BB(0xFF,0xD5);                   // call    ebp   ; getbits

    ADD_BR1(0x74,0xF000DEAD);            // jz      __quit

    ADD_B(0x92);                         // xchg    edx, eax

    // 2. get length into ECX

    ADD_BB(0xFF,0xD5);                   // call    ebp   ; getbits
    ADD_BR1(0x75,0xF0000008);            // jnz     __45

    // i: eax=0
    // o: ecx=P3-1
    //    edx=0

    if (P3==1)
      ;
    else
    if (P3==2)
      ADD_B(0x41)                        // inc     ecx
    else // (P3>=3)
      ADD_BB(0xB1, P3-1);                // mov     cl, P3-1

    ADD_BR1(0xEB,0xF0000005);            // jmp     __cpy

    ADD_L(0xF0000008);                   // __45:

    ADD_BB(0xFF,0xD5);                   // call    ebp   ; getbits

    // i: eax=0|1
    //    ecx=0
    // o: ecx=(P4-1)|(P5-1)

    if (P4==P5)
    {

      if (P4==1)
        ;
      else
      if (P4==2)
        ADD_B(0x41)                      // inc     ecx
      else // P4>=3
        ADD_BB(0xB1, P1-1)               // mov     cl, P4-1

    }
    else
    {

      if (P5-P4==1)
      {
        // do nothing, eax=delta=0|1
      }
      else
      if (P5-P4==2)
      {
        ADD_BB(0xd1,0xe0);               // shl     eax, 1
      }
      else // (P5-P4>=2)
      {
        ADD_BBB(0x6B,0xC0,P5-P4);        // imul    eax, eax, imm8  ; eax=delta=0|(P2-P1)
      }

      if (P4==1)
      {
        // 0|1
      }
      else
      if (P4==2)
        ADD_B(0x40)                      // inc     eax    ; 1|(1+delta)
      else // (P4>=3)
        ADD_BB(0x04,P4-1)                // add     al, P4-1  ; (P4-1)|(P4-1+delta)

      ADD_B(0x91);                       // xchg    ecx, eax

    }

    //

    ADD_L(0xF0000005);                   // __cpy:

    ADD_BB(0xFF,0xD5);                   // call    ebp   ; getbits

    ADD_B(0x91);                         // xchg    ecx, eax
    ADD_B(0x41);                         // inc     ecx
    ADD_B(0x41);                         // inc     ecx

    // 3. copy string

    ADD_B(0x56);                         // push    esi
    ADD_BB(0x89,0xFE);                   // mov     esi, edi
    ADD_BB(0x29,0xD6);                   // sub     esi, edx
    ADD_BB(0xf3,0xa4);                   // rep     movsb
    ADD_B(0x5E);                         // pop     esi

    ADD_BR1(0xEB,0xF0000000);            // jmp     __main_cycle

    ADD_L(0xF000DEAD);                   // __quit:

    if (build)
    {
      ADD_BB(0xFF,0xE4);                 // jmp     esp
    }
    else
    {
      ADD_BBBB(0x2B,0x7C,0x24,0x24);     // sub     edi, [esp+32+4]
      ADD_BBBB(0x89,0x7c,0x24,0x1c);     // mov     [esp+7*4], edi  ; set POPA.EAX
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

} // CModLZ::PackReal

int CModLZ::ParseOption(char* s)
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

} // CModLZ::ParseOption
