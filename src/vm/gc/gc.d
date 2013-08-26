module vm.gc.gc;
import core.stdc.stdlib;

union GCObjectHeader
{
  uint rawtypedata;
};

void *GCAlloc(size_t size)
{
  return GCState.alloc(size);
}

T *GCAlloc(T)()
{
  return cast(T*) GCState.alloc(T.sizeof);
}

/************* Private State **************/
private:

struct GCStateStruct
{
  ubyte *mem_start = null;
  ubyte *mem_end = null;
  ubyte *mem_ptr = null;

  static immutable BLOCK_SIZE = (2<<13);
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
      assert(mem_ptr > mem_end);
    }

    return ret;
  }
}

static GCStateStruct GCState = void;
static this() { GCState.alloc_new_block; }
