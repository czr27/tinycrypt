
// CSfx class,
// used to build decompressor code on-the-fly && test decompression

#define SFXT_LABEL            1
#define SFXT_BYTE             2
#define SFXT_REL1             3
#define SFXT_REL4             4
#define SFXT_PAKDATA          5

#define ADD_L(x)                                                \
        {                                                       \
          assert(Sfx->x_count < Sfx->max_instr);                \
          Sfx->x_type [Sfx->x_count  ] = SFXT_LABEL;            \
          Sfx->x_value[Sfx->x_count++] = (x);                   \
        }

#define ADD_B(x)                                                \
        {                                                       \
          assert(Sfx->x_count < Sfx->max_instr);                \
          Sfx->x_type [Sfx->x_count  ] = SFXT_BYTE;             \
          Sfx->x_value[Sfx->x_count++] = (x);                   \
        }

#define ADD_R1(x)                                               \
        {                                                       \
          assert(Sfx->x_count < Sfx->max_instr);                \
          Sfx->x_type [Sfx->x_count  ] = SFXT_REL1;             \
          Sfx->x_value[Sfx->x_count++] = (x);                   \
        }

#define ADD_R4(x)                                               \
        {                                                       \
          assert(Sfx->x_count < Sfx->max_instr);                \
          Sfx->x_type [Sfx->x_count  ] = SFXT_REL4;             \
          Sfx->x_value[Sfx->x_count++] = (x);                   \
        }

#define ADD_P()                                                 \
        {                                                       \
          assert(Sfx->x_count < Sfx->max_instr);                \
          Sfx->x_type [Sfx->x_count++] = SFXT_PAKDATA;          \
        }

#define ADD_D(x)                                                \
        {                                                       \
          ADD_B((x)&0xFF);                                      \
          ADD_B(((x)>>8)&0xFF);                                 \
          ADD_B(((x)>>16)&0xFF);                                \
          ADD_B(((x)>>24)&0xFF);                                \
        }

#define ADD_BB(x,y)                                             \
        {                                                       \
          ADD_B(x);                                             \
          ADD_B(y);                                             \
        }

#define ADD_BBB(x,y,z)                                          \
        {                                                       \
          ADD_B(x);                                             \
          ADD_B(y);                                             \
          ADD_B(z);                                             \
        }

#define ADD_BBBB(x,y,z,w)                                       \
        {                                                       \
          ADD_B(x);                                             \
          ADD_B(y);                                             \
          ADD_B(z);                                             \
          ADD_B(w);                                             \
        }

#define ADD_BD(x,y)                                             \
        {                                                       \
          ADD_B(x);                                             \
          ADD_D(y);                                             \
        }

#define ADD_BBD(x,y,z)                                          \
        {                                                       \
          ADD_B(x);                                             \
          ADD_B(y);                                             \
          ADD_D(z);                                             \
        }

#define ADD_BR1(x,y)                                            \
        {                                                       \
          ADD_B(x);                                             \
          ADD_R1(y);                                            \
        }

#define ADD_BR4(x,y)                                            \
        {                                                       \
          ADD_B(x);                                             \
          ADD_R4(y);                                            \
        }

class CSfx
{
  public:

  CSfx();
  ~CSfx();

  void Init(BYTE* pakdata_0, DWORD pakdata_len_0, DWORD max_instr_0);
  void Link();
  int Verify(BYTE* orig_inptr, DWORD orig_ilen);
  void Done();

  BYTE* pakdata;
  DWORD pakdata_len;
  DWORD max_instr;

  DWORD x_count;                // # of entries, max = max_instr-1
  DWORD x_len;
  DWORD*x_value;
  DWORD*x_type;
  DWORD*x_offs;
  BYTE* x_data;

}; // class CSfx

CSfx::CSfx()
{
  x_value = NULL;
  x_type  = NULL;
  x_offs  = NULL;
  x_data  = NULL;
} // CSfx::CSfx

CSfx::~CSfx()
{
  Done();
  assert(x_value == NULL && x_type == NULL && x_offs == NULL && x_data == NULL);
} // CSfx::~CSfx

void CSfx::Done()
{
  if (x_value && x_type && x_offs && x_data)
  {
    delete x_value;
    delete x_type;
    delete x_offs;
    delete x_data;
    x_value = NULL;
    x_type  = NULL;
    x_offs  = NULL;
    x_data  = NULL;
  }
} // CSfx::Done

void CSfx::Init(BYTE* pakdata_0, DWORD pakdata_len_0, DWORD max_instr_0)
{

  Done();

  pakdata     = pakdata_0;
  pakdata_len = pakdata_len_0;
  max_instr   = max_instr_0;

  // build unpacker

  x_count = 0;
  x_value = new DWORD[max_instr];
  x_type  = new DWORD[max_instr];      // 1=byte 2=label 3=R4 4=packed 5=R1
  x_offs  = new DWORD[max_instr];
  x_data  = new BYTE[pakdata_len+max_instr*16];
  assert(x_value && x_type && x_offs && x_data);

} // CSfx::Init

void CSfx::Link()
{
  // link -- pass 1/2 -- build code

  x_len = 0;

  for(int i=0; i<x_count; i++)
  {
    if (x_type[i]==SFXT_PAKDATA) // packed
    {
      memcpy(x_data+x_len,pakdata,pakdata_len);
      x_len += pakdata_len;
    }
    else
    if ((x_type[i]==SFXT_BYTE)||(x_type[i]==SFXT_REL1))  // BYTE or R1
    {
      x_offs[i] = x_len;
      x_data[x_len++] = x_value[i];
    }
    else
    if (x_type[i]==SFXT_REL4)   // R4
    {
      x_offs[i] = x_len;
      x_len += 4;
    }
    else
    if (x_type[i]==SFXT_LABEL) // LABEL
    {
      x_offs[i] = x_len;
    }
  }

  // link -- pass 2/2 -- fix rel. jmps

  for(DWORD i=0; i<x_count; i++)
  {
    DWORD dst=0;
    if ((x_type[i]==SFXT_REL1)||(x_type[i]==SFXT_REL4)) // R1,R4
    {
      for(int j=0; j<x_count; j++)
        if (x_type [j] == SFXT_LABEL)
        if (x_value[j] == x_value[i])
        {
          if (dst != 0)
          {
            printf("INTERNAL ERROR: LABEL DEFINED TWICE, i=%d,j=%d,ID=%08X\n", i,j,x_value[i]);
            exit(0);
          }
          dst = x_offs[j];
        }
      if (dst == 0)
      {
        printf("INTERNAL ERROR: LABEL NOT FOUND, ID=%08X\n", x_value[i]);
        exit(0);
      }
    }
    if (x_type[i]==SFXT_REL1) // R1
    {
      long d = dst - (x_offs[i]+1);
      if ((d > 127) || (d < -128))
      {
        printf("INTERNAL ERROR: SHORT JMP OUT OF RANGE\n");
        exit(0);
      }
      x_data[x_offs[i]] = d;
    }
    else
    if (x_type[i]==SFXT_REL4) // R4
    {
      *(DWORD*)&x_data[x_offs[i]] = dst - (x_offs[i]+4);
    }
  }

} // CSfx::Link

int CSfx::Verify(BYTE* orig_inptr, DWORD orig_ilen)
{
  BYTE* temp = new BYTE[ orig_ilen+65536 ]; // +64k on unpack overflow
  assert(temp);
  memset(temp, 0x00, orig_ilen+65536);

  typedef DWORD (__cdecl* functype)(BYTE*);

  DWORD temp_len = ((functype)x_data)( temp );   // call generated code

  if (temp_len != orig_ilen)
  {

//    FILE*f=fopen("_verify.bin","wb");
//    fwrite(temp,1,temp_len,f);
//    fclose(f);

    printf("verify SIZE error (got %d,need %d)\n",temp_len,orig_ilen);
    delete temp;
    return 1;
  }

  if (memcmp(temp, orig_inptr, orig_ilen) != 0)
  {
    printf("verify DATA error\n");
    delete temp;
    return 2;
  }

  delete temp;
  return 0;

} // CSfx::Verify
