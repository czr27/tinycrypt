
byte  l2,l1;
dword mem_c [16][256] [256];
dword mem_b [16][256] ;
byte  mem_x [16][256] ;

#define ACCESS  [l2&15][l1]               // not an error

void engine_init(void)
  {
    l1 = l2 = 0;
    memset(mem_c, 0, sizeof(mem_c));
    memset(mem_b, 0, sizeof(mem_b));
    memset(mem_x, 0, sizeof(mem_x));
  }

void engine_update(byte c)
  {
    mem_c ACCESS [c]++;

    if (mem_c ACCESS [c] > mem_b ACCESS)
      {
        mem_b ACCESS = mem_c ACCESS [c];
        mem_x ACCESS = c;
      }

    l2 = l1;
    l1 = c;

  }

byte engine_next(void)
  {
    return mem_x ACCESS;
  }
