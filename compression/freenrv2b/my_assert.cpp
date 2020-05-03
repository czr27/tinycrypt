
// since buggy icl dislike my asserts

#undef assert
#define assert(p)   ((p) ? (void)0 : _assert(#p, __FILE__, __LINE__))
void _assert(char * __cond, char * __file, int __line)
{
  printf("ASSERT: %s, file %s, line %d\n", __cond, __file, __line);
  exit(0);
}
