
// CModule interface,
// to inherit compression modules from

class CModule
{
  public:

  DWORD entry_size;

  CDict*  Dict;
  CGraph* Graph;

  CModule(int entry_size_0);
  ~CModule();

  void Init(BYTE* inptr, DWORD ilen);
  void Done();

  virtual void ModInit();
  virtual void ModDone();
  virtual DWORD Pack(BYTE* inptr, DWORD ilen, BYTE* outptr);
  virtual int ParseOption(char* s);

}; // class CModule

CModule::CModule(int entry_size_0)
{
  entry_size = entry_size_0;
  //
  Dict  = new CDict;
  assert(Dict);
  //
  Graph = new CGraph;
  assert(Graph);
  //
} // CModule::CModule

CModule::~CModule()
{
  delete Dict;
  delete Graph;
} // CModule::~CModule

void CModule::Init(BYTE* inptr, DWORD ilen)
{

  Graph->alloc(ilen, entry_size);
  Dict->build_tree(inptr, ilen);

  ModInit();

} // CModule::Init

void CModule::Done()
{

  ModDone();

  Dict->done_tree();
  Graph->release();

} // CModule::Done

void CModule::ModInit()
{
  // virtual method called
  assert(0);
} // CModule::ModInit

void CModule::ModDone()
{
  // virtual method called
  assert(0);
} // CModule::ModDone

DWORD CModule::Pack(BYTE* inptr, DWORD ilen, BYTE* outptr)
{
  // virtual method called
  assert(0);
  return 0;
} // CModule::Pack

int CModule::ParseOption(char* s)
{
  assert(0);
  return 0;
} // CModule::ParseOption
