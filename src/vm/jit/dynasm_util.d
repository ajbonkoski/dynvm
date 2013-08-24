module vm.jit.dynasm_util;

  import ddynasm.dasm_x86;
  import std.exception;
  byte b(T)(T v)
  {
    enforce((v&(~0xff)) == 0);
    return cast(byte)(v&0xff);
  }

/*
** This file has been pre-processed with DynASM.
** http://luajit.org/dynasm.html
** DynASM version 1.3.0, DynASM x64 version 1.3.0
** DO NOT EDIT! The original file is in "vm/jit/dynasm_util.dasd".
*/

static if(DASM_VERSION != 10300) {
    static assert("Version mismatch between DynASM and included encoding engine");
}

//lineno=1, msg="vm/jit/dynasm_util.dasd"

import std.stdio;

// DynASM directives.
//|.arch x64
const byte[12] actions = [
  72.b,199.b,199.b,237.b,72.b,199.b,192.b,237.b,252.b,255.b,208.b,255.b
];

//lineno=7, msg="vm/jit/dynasm_util.dasd"


// should be used with UFCS, so it "looks" like a Dasm method
// e.g. d.genCall(...)
void *genCall(ref Dasm d, void *func, void *arg1)
{
  auto Dst = &d.state;
  d.setup(actions);

  //| mov   rdi, arg1
  //| mov   rax, func
  //| call  rax
  dasm_put(Dst, 0, arg1, func);
//lineno=19, msg="vm/jit/dynasm_util.dasd"

  return null;
}

void printMem(ref Dasm d)
{
  foreach(i; 0..d.size) {
    writef(" %x", d.mem[i]);
    if(i > 0 && i%16 == 0) writef("\n");
  }
}

void printMemRaw(ref Dasm d)
{
  foreach(i; 0..d.size) {
    writef("%c", d.mem[i]);
  }
}
