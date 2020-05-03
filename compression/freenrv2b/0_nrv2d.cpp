
DWORD pack_nrv2d( BYTE* inptr,
                  DWORD ilen,
                  BYTE* outptr,
                  void* (__cdecl*my_malloc)(unsigned int),
                  void (__cdecl*my_free)(void*) )
{
  BYTE*  t_outptr;
  DWORD* t_bitset;
  DWORD  t_bitcount;

  DWORD* ss11_len = (DWORD*)my_malloc((ilen+1)*4);
  DWORD* ss12_len = (DWORD*)my_malloc((ilen+1)*4);
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

  DWORD sz = (ilen+1) << 2;
  BYTE* mem1 = (BYTE*)my_malloc(sz*6);
  memset(mem1, 0x00, sz*6);
  DWORD*c_off = (DWORD*)(mem1);
  DWORD*c_len = (DWORD*)(mem1+sz);
  DWORD*c_pak = (DWORD*)(mem1+sz*2);
  DWORD*c_lmo = (DWORD*)(mem1+sz*3);
  DWORD*c_prv = (DWORD*)(mem1+sz*4);
  DWORD*c_nxt = (DWORD*)(mem1+sz*5);

  BYTE* mem2 = (BYTE*)my_malloc(65536*4*3);
  memset(mem2, 0x00, 65536*4*3);
  DWORD*c_hash_max = (DWORD*)(mem2);
  DWORD*c_hash_cnt = (DWORD*)(mem2+65536*4*1);
  DWORD**c_hash_ptr = (DWORD**)(mem2+65536*4*2);

  for(int i=0; i<ilen-1; i++)
  {
    DWORD w = *(WORD*)&inptr[i];
    if (c_hash_cnt[w] == c_hash_max[w])
    {
      if (c_hash_max[w] == 0)
        c_hash_max[w] = 1024;
      else
        c_hash_max[w] <<= 1;
      DWORD* newptr = (DWORD*)my_malloc(c_hash_max[w] << 2);
      if (c_hash_ptr[w] != NULL)
      {
        memcpy(newptr, c_hash_ptr[w], c_hash_cnt[w] << 2);
        my_free(c_hash_ptr[w]);
      }
      c_hash_ptr[w] = newptr;
    }
    c_hash_ptr[w][c_hash_cnt[w]++] = i;
  }

  c_lmo[0] = 1;

  // xxxxxxxxx

  for(i=0; i<ilen; i++)
  {

#define FOLLOW(src,dst,bitpaklen,lmo,off,len)                                 \
        {                                                                     \
          int n = c_pak[src] + (bitpaklen);                                   \
          if ( (c_pak[dst] == 0) ||                                           \
               (  c_pak[dst] > n )  )                                         \
          {                                                                   \
            c_pak[dst] = n;                                                   \
            c_lmo[dst] = lmo;                                                 \
            c_off[dst] = off;                                                 \
            c_len[dst] = len;                                                 \
            c_prv[dst] = src;                                                 \
          }                                                                   \
        }

    FOLLOW(i,i+1,9,c_lmo[i],0,0)

    if (i < ilen-1)
    {
      WORD w = *(WORD*)&inptr[i];
      DWORD cnt = c_hash_cnt[w];
      for(int c=0; c<cnt; c++)
      {
        int z = c_hash_ptr[w][c];
        if (z >= i) break;
        DWORD t_off = i - z;
        DWORD t_len = 1;
        while((i+t_len<ilen)&&(inptr[i+t_len] == inptr[z+t_len]))
        {
          t_len++;

        if ((t_len > 2) || ((t_len == 2) && (t_off <= 0x500)))
        {

          int l;
          if (t_off == c_lmo[i])
            l = 5;
          else
          {
            l = 10 + ss12_len[1 + ((t_off - 1) >> 8)];
          }
          int t = t_len - 1 - (t_off > 0x500);
          if (t >= 4)
            l += ss11_len[t-4];

          if (l < (t_len << 3))
            FOLLOW(i,i+t_len,l,t_off, t_off,t_len)
        }
        }

      }
    }

  }

  // yyyyyyyy

  DWORD x = ilen;
  for(;;)
  {
    DWORD y = c_prv[x];
    c_nxt[y] = x;
    x = y;
    if (x == 0) break;
  }

  t_outptr   = outptr;

  t_bitset   = (DWORD*)t_outptr;
  t_outptr   += 4;
  *t_bitset  = 0;
  t_bitcount = 0;

  DWORD last_m_off = 1;

  x = 0;
  while(1)
  {
    DWORD y = c_nxt[x];
    if (y == 0) break;

    DWORD m_off = c_off[y];
    DWORD m_len = c_len[y];

    if (m_len == 0)
    {
      bbPutBit(1);
      *t_outptr++ = *inptr++;
      ilen--;
    }
    else
    {
      inptr += m_len;
      ilen  -= m_len;

      //
      bbPutBit(0);
      m_len = m_len - 1 - (m_off > 0x500);
      DWORD m_low = (m_len >= 4) ? 0 : m_len;
      if (m_off == last_m_off)
      {
          bbPutBit(0);
          bbPutBit(1);
          bbPutBit(m_low > 1);
          bbPutBit(m_low & 1);
      }
      else
      {
          code_prefix_ss12(1 + ((m_off - 1) >> 7));
          *t_outptr++ = (((m_off - 1) & 0x7f) << 1) | ((m_low > 1) ? 0 : 1);
          bbPutBit(m_low & 1);
      }
      if (m_len >= 4)
          code_prefix_ss11(m_len - 4);
      last_m_off = m_off;
      //

    }

    x = y;
  }

  bbPutBit(0);
  code_prefix_ss12(0x1000000);
  *t_outptr++ = 0xff;

  while(t_bitcount != 32)
    bbPutBit(0);

  for(i=0; i<65536; i++)
    if (c_hash_ptr[i])
      my_free(c_hash_ptr[i]);
  my_free(mem1);
  my_free(mem2);

  my_free(ss11_len);
  my_free(ss12_len);

  return t_outptr - outptr;

} // pack_nrv2d
