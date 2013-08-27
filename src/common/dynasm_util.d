module common.dynasm_util;

import core.stdc.string;
import std.stdio;
import std.file;
import std.string;
import std.process;
import ddynasm.dasm_x86;


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

enum TMPFILE = "/tmp/dynvm_jit.out";
void printDisassembly(ref Dasm d)
{
  char[] data;
  data.length = d.size;
  for(uint i = 0; i < data.length; i++)
    data[i] = d.mem[i];

  std.file.write(TMPFILE, data);

  auto CMD = ["objdump", "-D",
              "-b", "binary",
              "-m", "l1om",
              "-M", "intel",
              TMPFILE];

  auto res = execute(CMD);
  writeln(res.output);

  return;
}
