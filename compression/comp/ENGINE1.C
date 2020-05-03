
byte l1;
byte mem[256];

void engine_init(void)
  {
    l1 = 0;
    memset(mem, 0, sizeof(mem));
  }

void engine_update(byte c)
  {
    mem[l1] = c;
    l1 = c;
  }

byte engine_next(void)
  {
    return mem[l1];
  }
