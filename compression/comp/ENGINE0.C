
byte l4, l3, l2, l1;

void engine_init(void)
  {
    l4 = l3 = l2 = l1 = 0;
  }

void engine_update(byte c)
  {
    l4 = l3;
    l3 = l2;
    l2 = l1;
    l1 = c;
  }

byte engine_next(void)
  {
    if ((l3==l2)&&(l3==l1)) return l3;
    if ((l4==l2)&&(l3==l1)) return l4;

    return 0;
  }
