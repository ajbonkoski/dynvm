module vm.gc.gc;
import core.stdc.stdlib;
import core.stdc.string;

union GCObjectHeader
{
  uint rawtypedata;
};

void *GCAlloc(size_t size)
{
  return GCState.alloc(size);
}

T *GCAlloc(T)(size_t elts=1)
{
  return cast(T*) GCState.alloc(elts * T.sizeof);
}

void *GCRealloc(void *oldptr, size_t oldsize, size_t newsize)
{
  void *newptr = GCState.alloc(newsize);
  memcpy(newptr, oldptr, oldsize);
  return newptr;
}

T *GCRealloc(T)(T *oldptr, size_t oldelts, size_t newelts)
{
  void *newptr = GCState.alloc(newelts * T.sizeof);
  memcpy(newptr, oldptr, oldelts * T.sizeof);
  return cast(T*) newptr;
}

/************* Private State **************/
private:

struct GCStateStruct
{
  ubyte *mem_start = null;
  ubyte *mem_end = null;
  ubyte *mem_ptr = null;

  static immutable BLOCK_SIZE = (2<<12);
  void alloc_new_block()
  {
    mem_ptr = mem_start = cast(ubyte*) malloc(BLOCK_SIZE);
    assert(mem_start !is null);
    mem_end = mem_start += BLOCK_SIZE;
  }

  void *alloc(size_t size)
  {
    // assure the req size of 4-byte aligned
    auto size_align = ((size-1)/4 + 1)*4;
    void *ret = mem_ptr;
    mem_ptr += size_align;
    if(mem_ptr > mem_end) {
      alloc_new_block();
      ret = mem_ptr;
      mem_ptr += size_align;
      assert(mem_ptr <= mem_end);
    }

    return ret;
  }
}

static GCStateStruct GCState = void;
static this() { GCState.alloc_new_block; }
