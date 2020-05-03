
byte l1;
dword mem_c[256][256];
dword mem_b[256];
byte  mem_x[256];

void engine_init(void)
  {
    l1 = 0;
    memset(mem_c, 0, sizeof(mem_c));
    memset(mem_b, 0, sizeof(mem_b));
    memset(mem_x, 0, sizeof(mem_x));
  }

void engine_update(byte c)
  {
    mem_c[l1][c]++;
    if (mem_c[l1][c] >= mem_b[l1])
      {
        mem_b[l1] = mem_c[l1][c];
        mem_x[l1] = c;
      }
    l1 = c;
  }

byte engine_next(void)
  {
    return mem_x[l1];
  }
