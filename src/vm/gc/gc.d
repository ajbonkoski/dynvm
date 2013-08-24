module vm.gc.gc;
import core.stdc.stdlib;

union GCObjectHeader
{
  uint rawtypedata;
};

void *GCAlloc(size_t size)
{
  return malloc(size);
}

T *GCAlloc(T)()
{
  void *mem = malloc(T.sizeof);
  return cast(T*) mem;
}

