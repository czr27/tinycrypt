
DWORD g_total_mem_size = 0, g_nodes = 0;

struct g_entry
{
  DWORD c_src;
  DWORD c_dst;
  DWORD c_pak;
  DWORD c_lmo;
  DWORD c_off;
  DWORD c_len;
  struct g_entry* c_prev;
  struct g_entry* c_next;
};

DWORD* g_max;
DWORD* g_cnt;
struct g_entry*** g_lst;

void graph_init(int ilen)
{

  DWORD sz = (ilen+1) << 2;

  g_max = (DWORD*) malloc( sz );
  assert(g_max);

  g_cnt = (DWORD*) malloc( sz );
  assert(g_cnt);

  g_lst = (struct g_entry***) malloc( sz );
  assert(g_lst);

  memset(g_max, 0x00, sz);
  memset(g_cnt, 0x00, sz);
  memset(g_lst, 0x00, sz);

  g_total_mem_size += sz * 3;

} // graph_init

void graph_done(DWORD ilen)
{
  printf("+ releasing allocated memory (graph)\n");

  DWORD sz = (ilen+1) << 2;

  free(g_lst);
  free(g_cnt);
  free(g_max);

  g_total_mem_size -= sz * 3;

  printf("  memory used = %d\n",g_total_mem_size);
}

struct g_entry* alloc_item(int id)
{
  struct g_entry* x = (struct g_entry*)malloc( sizeof(struct g_entry) );
  assert(x);
  memset(x, 0x00, sizeof(struct g_entry));

  g_total_mem_size += sizeof(struct g_entry);

  g_nodes++;

  if (g_cnt[id] == g_max[id])
  {
    if (g_max[id] == 0)
    {
      g_max[id] = 32;
      g_lst[id] = (struct g_entry**)malloc ( g_max[id]*4 );
    }
    else
    {
      g_max[id] += 32;
      g_lst[id] = (struct g_entry**)realloc( g_lst[id], g_max[id]*4 );
    }

    g_total_mem_size += 32*4;
  }

  g_lst[id][g_cnt[id]++] = x;

  return x;

} // alloc_new_item

void graph_empty(DWORD ilen)
{
  DWORD sz = (ilen+1) << 2;

  for(DWORD i=0; i<=ilen; i++)
  {
    for(DWORD j=0; j<g_cnt[i]; j++)
    {
      free(g_lst[i][j]);
      g_nodes--;
      g_total_mem_size -= sizeof(struct g_entry);
    }
    free(g_lst[i]);
    g_total_mem_size -= g_max[i] * 4;
  }
  memset(g_max, 0x00, sz);
  memset(g_cnt, 0x00, sz);
  memset(g_lst, 0x00, sz);

} // graph_empty

