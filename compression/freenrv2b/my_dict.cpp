
#define USE_CACHED_FILE

DWORD total_mem_size = 0;
DWORD str_max;
DWORD str_cnt;
//DWORD* str_index;       // [i=0..str_cnt-1]    TEMP
DWORD* str_len;         // [i=0..str_cnt-1]
DWORD* str_o_max;       // [i=0..str_cnt-1]
DWORD* str_o_cnt;       // [i=0..str_cnt-1]
DWORD** str_o_ptr1;     // [i=0..str_cnt-1][j=0..str_o_cnt[i]-1]
DWORD** str_o_ptr2;     // [i=0..str_cnt-1][j=0..str_o_cnt[i]-1]

DWORD* h_cnt;           // [i=0..ilen-1]
DWORD** h_str;          // [i=0..ilen-1][j=0..h_cnt[i]-1]  --> str_index

DWORD t_cnt;
DWORD* t_str;

#define INT_CMP(x,l,r)  ((int)(x)<(int)(l)?(-1):((int)(x)>(int)(r)?(1):(0)))

void add_str_offs(DWORD str_n, DWORD offs)
{

  // check if offs exists

  DWORD a = 0;
  DWORD b = str_o_cnt[str_n];
  DWORD c = 0;

  while(a < b)
  {
    c = (a + b) / 2;
    int comp = INT_CMP(offs, str_o_ptr1[str_n][c]-1, str_o_ptr2[str_n][c]+1);
    if (comp == 0)
    {
      if ((c>0)&&(str_o_ptr2[str_n][c-1] == offs)) return;
      if ((c+1<str_o_cnt[str_n])&&(str_o_ptr1[str_n][c+1] == offs)) return;
      str_o_ptr1[str_n][c] = MIN(str_o_ptr1[str_n][c], offs);
      str_o_ptr2[str_n][c] = MAX(str_o_ptr2[str_n][c], offs);
      return;
    }
    else
    if (comp == 1) // <
      a = c + 1;
    else // >
      b = c;
  }

//  for(DWORD i=0; i<str_o_cnt[str_n]; i++)
//    assert(INT_CMP(offs, str_o_ptr1[str_n][i], str_o_ptr2[str_n][i]) != 0);
//  for(i=1; i<str_o_cnt[str_n]; i++)
//    assert(str_o_ptr2[str_n][i-1] < str_o_ptr1[str_n][i]);

  // alloc new offs -- check if enough space

  if (str_o_cnt[str_n] == str_o_max[str_n])
  {
    str_o_max[str_n] += 32;
    total_mem_size += 32 * 4 * 2;
    DWORD* x1 = str_o_ptr1[str_n];
    DWORD* x2 = str_o_ptr2[str_n];
    str_o_ptr1[str_n] = new DWORD[ str_o_max[str_n] ];
    str_o_ptr2[str_n] = new DWORD[ str_o_max[str_n] ];
    assert(str_o_ptr1[str_n]);
    assert(str_o_ptr2[str_n]);
    memcpy(str_o_ptr1[str_n], x1, str_o_cnt[str_n] * 4);
    memcpy(str_o_ptr2[str_n], x2, str_o_cnt[str_n] * 4);
    delete x1;
    delete x2;
  }

  // alloc new offs -- insert at pos A

  memmove(&str_o_ptr1[str_n][a+1], &str_o_ptr1[str_n][a], (str_o_cnt[str_n]-a)*4);
  memmove(&str_o_ptr2[str_n][a+1], &str_o_ptr2[str_n][a], (str_o_cnt[str_n]-a)*4);
  str_o_ptr1[str_n][a] = offs;
  str_o_ptr2[str_n][a] = offs;
  str_o_cnt[str_n]++;

  //printf("  str_n=%d, +offs=%d\n", str_n, offs);

} // add_str_offs

DWORD add_str(BYTE* inptr, DWORD ilen, DWORD offs1, DWORD offs2, DWORD len)
{
  DWORD str_n = 0xFFFFFFFF;

  // check if string exists

  DWORD a = 0;
  DWORD b = str_cnt;
  DWORD c = 0;
  while(a < b)
  {
    c = (a + b) / 2;

    int comp;

    if (str_len[c] == len)
      comp = memcmp(inptr+str_o_ptr1[c][0], inptr+offs1, len);
    else
      comp = str_len[c] < len ? -1 : 1;

    if (comp == 0)
    {
      str_n = c;
      break;
    }
    else
    if (comp < 0)
      a = c + 1;
    else
      b = c;
  }

//  if (str_n == 0xffffffff)
//  for(DWORD i = 0; i < str_cnt; i++)
//    if (str_len[i] == len)
//      assert(memcmp(inptr+str_o_ptr1[i][0], inptr+offs1, len) != 0);

  if (str_n == 0xFFFFFFFF)
  {

    // alloc new string -- check if enough space

    if (str_cnt == str_max)
    {
      str_max += 32;
      total_mem_size += 32 * 4 * 5;
      DWORD*  x1 = str_len;
      DWORD*  x2 = str_o_max;
      DWORD*  x3 = str_o_cnt;
      DWORD** x4 = str_o_ptr1;
      DWORD** x5 = str_o_ptr2;
      str_len    = new DWORD [ str_max ];
      str_o_max  = new DWORD [ str_max ];
      str_o_cnt  = new DWORD [ str_max ];
      str_o_ptr1 = new DWORD*[ str_max ];
      str_o_ptr2 = new DWORD*[ str_max ];
      assert(str_len   );
      assert(str_o_max );
      assert(str_o_cnt );
      assert(str_o_ptr1);
      assert(str_o_ptr2);
      memcpy(str_len   ,x1,str_cnt*4);
      memcpy(str_o_max ,x2,str_cnt*4);
      memcpy(str_o_cnt ,x3,str_cnt*4);
      memcpy(str_o_ptr1,x4,str_cnt*4);
      memcpy(str_o_ptr2,x5,str_cnt*4);
      delete x1;
      delete x2;
      delete x3;
      delete x4;
      delete x5;
    }

    // alloc new string -- insert at pos A

    for(DWORD q=0; q<ilen; q++)
    for(DWORD w=0; w<h_cnt[q]; w++)
    {
      //assert(h_str[q][w] < str_cnt);
      if (h_str[q][w] >= a)
        h_str[q][w]++;
    }
    for(DWORD w=0; w<t_cnt; w++)
    {
      //assert(t_str[w] < str_cnt);
      if (t_str[w] >= a)
        t_str[w]++;
    }

    memmove(&str_len   [a+1], &str_len   [a], (str_cnt-a)*4);
    memmove(&str_o_max [a+1], &str_o_max [a], (str_cnt-a)*4);
    memmove(&str_o_cnt [a+1], &str_o_cnt [a], (str_cnt-a)*4);
    memmove(&str_o_ptr1[a+1], &str_o_ptr1[a], (str_cnt-a)*4);
    memmove(&str_o_ptr2[a+1], &str_o_ptr2[a], (str_cnt-a)*4);

    str_n = a;
    str_cnt++;

    //printf("add: offs1=%d,offs2=%d,len=%d, cnt=%d,a=%d\n",offs1,offs2,len,str_cnt,a);

    str_len   [str_n] = len;
    str_o_max [str_n] = 32;
    str_o_cnt [str_n] = 0;
    str_o_ptr1[str_n] = new DWORD[ str_o_max[str_n] ];
    str_o_ptr2[str_n] = new DWORD[ str_o_max[str_n] ];
    assert(str_o_ptr1[str_n]);
    assert(str_o_ptr2[str_n]);
    total_mem_size += 32*4*2;

  }

  // add offsets

  add_str_offs(str_n, offs1);
  add_str_offs(str_n, offs2);

  // return string #

  return str_n;

} // add_str

void build_tree(BYTE* inptr, DWORD ilen)
{

#ifdef USE_CACHED_FILE
  DWORD crc = ~ilen;
  for(DWORD j=0; j<ilen; j++)
  {
    crc ^= inptr[j];
    crc = (crc << 1) | (crc >> 31);
  }
  char fn[1024];
  sprintf(fn,"%08x.dat",crc);

  FILE*f=fopen(fn,"rb");
  if (f!=NULL)
  {
    printf("+ reading: %s\n", fn);

    assert(fread(&str_cnt,1,4,f)==4);
    str_max = str_cnt;

    //str_index  = NULL;
    str_len    = new DWORD [str_max];
    str_o_max  = new DWORD [str_max];
    str_o_cnt  = new DWORD [str_max];
    str_o_ptr1 = new DWORD*[str_max];
    str_o_ptr2 = new DWORD*[str_max];
    assert(str_len   );
    assert(str_o_max );
    assert(str_o_cnt );
    assert(str_o_ptr1);
    assert(str_o_ptr2);
    total_mem_size += str_max * 4 * 5;

    assert(fread(str_len, 1,4*str_max,f)==4*str_max);
    assert(fread(str_o_cnt, 1,4*str_max,f)==4*str_max);
    memcpy(str_o_max, str_o_cnt, 4*str_max);

    for(DWORD i=0; i<str_cnt; i++)
    {
      str_o_ptr1[i] = new DWORD[ str_o_max[i] ];
      str_o_ptr2[i] = new DWORD[ str_o_max[i] ];
      assert(str_o_ptr1[i]);
      assert(str_o_ptr2[i]);
      total_mem_size += str_o_max[i] * 4 * 2;
      assert(fread(str_o_ptr1[i], 1,4*str_o_max[i], f) == 4*str_o_max[i]);
      assert(fread(str_o_ptr2[i], 1,4*str_o_max[i], f) == 4*str_o_max[i]);
    }

    h_cnt = new DWORD [ilen];
    h_str = new DWORD*[ilen];
    assert(h_cnt);
    assert(h_str);
    total_mem_size += ilen * 4 * 2;

    assert(fread(h_cnt, 1,4*ilen, f)==4*ilen);

    for(i=0; i<ilen; i++)
    {
      h_str[i] = new DWORD[ h_cnt[i] ];
      assert(h_str[i]);
      total_mem_size += h_cnt[i] * 4;
      assert(fread(h_str[i], 1,4*h_cnt[i], f)==4*h_cnt[i]);
    }

    fclose(f);

    printf("  memory used = %d\n",total_mem_size);

    return;
  }
#endif // USE_CACHED_FILE

  str_max    = 32;
  str_cnt    = 0;
  //str_index  = new DWORD [str_max];
  str_len    = new DWORD [str_max];
  str_o_max  = new DWORD [str_max];
  str_o_cnt  = new DWORD [str_max];
  str_o_ptr1 = new DWORD*[str_max];
  str_o_ptr2 = new DWORD*[str_max];
  //assert(str_index );
  assert(str_len   );
  assert(str_o_max );
  assert(str_o_cnt );
  assert(str_o_ptr1);
  assert(str_o_ptr2);
  total_mem_size += str_max * 4 * 5;

  DWORD*q_hash_max  = new DWORD [ 65536 ];
  DWORD*q_hash_cnt  = new DWORD [ 65536 ];
  DWORD**q_hash_ptr = new DWORD*[ 65536 ];
  assert(q_hash_max);
  assert(q_hash_cnt);
  assert(q_hash_ptr);
  total_mem_size += 65536*4*3;

  memset(q_hash_max,0,65536*4);
  memset(q_hash_cnt,0,65536*4);
  memset(q_hash_ptr,0,65536*4);

  for(int i=0; i<ilen-1; i++)
  {
    DWORD w = *(WORD*)&inptr[i];
    if (q_hash_cnt[w] == q_hash_max[w])
    {
      if (q_hash_max[w] == 0)
        q_hash_max[w] = 32;
      else
        q_hash_max[w] += 32;
      total_mem_size += 32*4;
      DWORD* newptr = new DWORD[ q_hash_max[w] ];
      assert(newptr);
      if (q_hash_ptr[w] != NULL)
      {
        memcpy(newptr, q_hash_ptr[w], q_hash_cnt[w] << 2);
        delete q_hash_ptr[w];
      }
      q_hash_ptr[w] = newptr;
    }
    q_hash_ptr[w][q_hash_cnt[w]++] = i;
  }

  h_cnt = new DWORD [ilen];
  h_str = new DWORD*[ilen];
  assert(h_cnt);
  assert(h_str);
  total_mem_size += ilen*2*4;
  memset(h_cnt,0,ilen*4);
  memset(h_str,0,ilen*4);

  t_str = new DWORD[ilen];
  assert(t_str);
  total_mem_size += ilen*4;

  for(i=0; i<ilen; i++)
  {
    //if (!(i&15))

    DWORD w = (i==(ilen-1))?0:*(WORD*)&inptr[i];

    int str_n = 0;
    t_cnt = 0;

    if (i != ilen-1)
    for(DWORD z=0; z<q_hash_cnt[w]; z++)
    {
      DWORD j = q_hash_ptr[w][z];
      if (j < i)
      {
        DWORD c = 2;
        while((i+c+3<ilen)&&(*(DWORD*)&inptr[i+c]==*(DWORD*)&inptr[j+c])) c+=4;
        while((i+c<ilen)&&(inptr[i+c]==inptr[j+c])) c++;

        str_n = add_str(inptr, ilen, j, i, c);

        for(DWORD k=0; k<t_cnt; k++)
        if (t_str[k] == str_n)
        {
          str_n = -1;
          break;
        }

        if (str_n != -1)
        {
          assert(t_cnt <= ilen);
          t_str[t_cnt++] = str_n;
          //printf("i=%d  str=%d  j=%d\n", i, str_n, j);
        }

      }
    }

    h_cnt[i] = t_cnt;
    if (h_cnt[i] != 0)
    {
      h_str[i] = new DWORD[ h_cnt[i] ];
      assert(h_str[i]);
      memcpy(h_str[i], t_str, h_cnt[i]*4);
      total_mem_size += h_cnt[i]*4;
    }

    printf("i=%6d, str_cnt=%6d,  len=%6d,o_cnt=%6d, %dM    \r",
      i,str_cnt,str_len[str_n],str_o_cnt[str_n],total_mem_size>>20);

  } // for i
  printf("\n");

  // optimize intervals
  for(i=0; i<str_cnt; i++)
  {
    for(DWORD j=1; j<str_o_cnt[i]; j++)
    {
      if (str_o_ptr2[i][j-1]+1 == str_o_ptr1[i][j])
      {
        str_o_ptr2[i][j-1] = str_o_ptr2[i][j];
        memcpy(&str_o_ptr1[i][j], &str_o_ptr1[i][j+1], (str_o_cnt[i]-j-1)*4);
        memcpy(&str_o_ptr2[i][j], &str_o_ptr2[i][j+1], (str_o_cnt[i]-j-1)*4);
        str_o_cnt[i]--;
      }
    }
  }

  delete t_str;
  total_mem_size -= ilen*4;

  for(i=0; i<=65535; i++)
    if (q_hash_ptr[i])
    {
      delete q_hash_ptr[i];
      total_mem_size -= q_hash_max[i]*4;
    }
  delete q_hash_max;
  delete q_hash_cnt;
  delete q_hash_ptr;
  total_mem_size -= 65536*4*3;

  //delete str_index;
  //total_mem_size -= str_max*4;

  printf("  memory used = %d\n",total_mem_size);

#ifdef USE_CACHED_FILE
  printf("+ writing: %s\n", fn);

  f=fopen(fn,"wb");
  assert(f);

  assert(fwrite(&str_cnt,1,4,f)==4);

  assert(fwrite(str_len, 1,4*str_cnt,f)==4*str_cnt);
  assert(fwrite(str_o_cnt, 1,4*str_cnt,f)==4*str_cnt);

  for(i=0; i<str_cnt; i++)
  {
    assert(fwrite(str_o_ptr1[i], 1,4*str_o_cnt[i], f) == 4*str_o_cnt[i]);
    assert(fwrite(str_o_ptr2[i], 1,4*str_o_cnt[i], f) == 4*str_o_cnt[i]);
  }

  assert(fwrite(h_cnt, 1,4*ilen, f)==4*ilen);

  for(i=0; i<ilen; i++)
  {
    assert(fwrite(h_str[i], 1,4*h_cnt[i], f)==4*h_cnt[i]);
  }

  fclose(f);
#endif // USE_CACHED_FILE

} // build_tree

void done_tree(DWORD ilen)
{
  printf("+ releasing allocated memory (dict)\n");

  for(DWORD i=0; i<str_cnt; i++)
  {
    delete str_o_ptr1[i];
    delete str_o_ptr2[i];
    total_mem_size -= str_o_max[i]*4*2;
  }
  delete str_len;
  delete str_o_max;
  delete str_o_cnt;
  delete str_o_ptr1;
  delete str_o_ptr2;
  total_mem_size -= str_max*4*5;

  for(i=0; i<ilen; i++)
  if (h_cnt[i] != 0)
  {
    delete h_str[i];
    total_mem_size -= h_cnt[i] * 4;
  }
  delete h_cnt;
  delete h_str;
  total_mem_size -= ilen * 4 * 2;

  printf("  memory used = %d\n",total_mem_size);

} // done_tree
