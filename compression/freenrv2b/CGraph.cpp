
// main graph class,
// keeps <ilen> linked lists of entries of size <entry_size>

#define CGraph_ALLOC_0          32
#define CGraph_ALLOC_BY         32

typedef struct _GRAPH_ENTRY
{

  DWORD c_src;                          // source index      } both can be rm'd
  DWORD c_dst;                          // destination index } if lo mem

  struct _GRAPH_ENTRY* c_next;          // next entry - set by follow()
  struct _GRAPH_ENTRY* c_prev;          // prev entry - set by ReversePath()

  DWORD c_pak;                          // packed length in BIT's

  //
  // module-specific data
  //

  // total structure size = <entry_size>, set by CModule::alloc()

} GRAPH_ENTRY;

class CGraph
{
  public:

  //
  DWORD   ilen;
  DWORD   sz;                   // (ilen + 1) * 4
  DWORD   entry_size;
  //
  DWORD   total_mem_size;       // } stats to check if mem leak
  DWORD   nodes;                // }
  //
  DWORD*  g_max;                // #of allocated nodes } in the 2nd-level array
  DWORD*  g_cnt;                // #of used nodes      } --//--
  GRAPH_ENTRY*** g_lst;         // array of arrays of graph node's
  //

  CGraph();
  ~CGraph();

  void alloc(int ilen_0, int entry_size_0);   // allocate/zero 1st-level arrays
  void empty();                               // set same state as after alloc()
  void release();                             // release all memory
  GRAPH_ENTRY* alloc_item(int idx);           // allocate new graph node
  DWORD ReversePath(void** first);            // sets ->c_prev fields

  private:

}; // class CGraph

CGraph::CGraph()
{
  g_max = NULL;
  g_cnt = NULL;
  g_lst = NULL;
  total_mem_size = 0;
  nodes          = 0;
} // CGraph::CGraph

CGraph::~CGraph()
{
  empty();
  release();
  assert(g_max == NULL && g_cnt == NULL && g_lst == NULL);
  assert(total_mem_size == 0 && nodes == 0);
} // CGraph::~CGraph

void CGraph::alloc(int ilen_0, int entry_size_0)
{
  ilen             = ilen_0;
  entry_size       = entry_size_0;

  sz = (ilen + 1) << 2;

  g_max = (DWORD*) malloc( sz );
  assert(g_max);

  g_cnt = (DWORD*) malloc( sz );
  assert(g_cnt);

  g_lst = (GRAPH_ENTRY***) malloc( sz );
  assert(g_lst);

  memset(g_max, 0x00, sz);
  memset(g_cnt, 0x00, sz);
  memset(g_lst, 0x00, sz);

  total_mem_size += sz * 3;

} // CGraph::alloc

void CGraph::empty()
{

  if (g_cnt && g_max && g_lst)
  {

    for(DWORD i=0; i<=ilen; i++)
    {
      for(DWORD j=0; j<g_cnt[i]; j++)
      {
        free(g_lst[i][j]);
        nodes--;
        total_mem_size -= entry_size;
      }
      free(g_lst[i]);
      total_mem_size -= g_max[i] * 4;
    }
    memset(g_max, 0x00, sz);
    memset(g_cnt, 0x00, sz);
    memset(g_lst, 0x00, sz);

  }

} // CGraph::empty

void CGraph::release()
{

  empty();

  if (g_cnt && g_max && g_lst)
  {

    free(g_lst);
    free(g_cnt);
    free(g_max);

    g_lst = NULL;
    g_cnt = NULL;
    g_max = NULL;

    total_mem_size -= sz * 3;

  }

} // CGraph::release

GRAPH_ENTRY* CGraph::alloc_item(int idx)
{
  GRAPH_ENTRY* x = (GRAPH_ENTRY*)malloc( entry_size );
  assert(x);
  memset(x, 0x00, entry_size);

  total_mem_size += entry_size;
  nodes++;

  if (g_cnt[idx] == g_max[idx])
  {
    if (g_max[idx] == 0)
    {
      g_max[idx] = CGraph_ALLOC_0;
      g_lst[idx] = (GRAPH_ENTRY**)malloc ( g_max[idx]*4 );
      total_mem_size += CGraph_ALLOC_0*4;
    }
    else
    {
      g_max[idx] += CGraph_ALLOC_BY;
      g_lst[idx] = (GRAPH_ENTRY**)realloc( g_lst[idx], g_max[idx]*4 );
      total_mem_size += CGraph_ALLOC_BY*4;
    }

  }

  g_lst[idx][g_cnt[idx]++] = x;

  return x;

} // CGraph::alloc_item

DWORD CGraph::ReversePath(void** first)
{

  DWORD best_k = 0;
  for(DWORD k=0; k < g_cnt[ilen]; k++)
  {
    if (g_lst[ilen][k]->c_pak < g_lst[ilen][best_k]->c_pak)
      best_k = k;
  }

  GRAPH_ENTRY* x = g_lst[ilen][best_k];
  while(1)
  {
    GRAPH_ENTRY* y = (GRAPH_ENTRY*)x->c_prev;
    if (y == NULL)
    {
      if (first != NULL)
        *first = (void*)x;   // store graph node where compression starts
      break;
    }
    y->c_next = x;
    x = y;
  }

  return best_k;

} // CGraph::ReversePath
