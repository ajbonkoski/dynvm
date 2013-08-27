import core.memory;
import std.stdio;
import std.conv;
import std.getopt;

import hlasm.code_obj;
import hlasm.assembler;
import vm.executor;

int main(string args[])
{
  bool silent = false, junk;
  bool use_jit = false;
    getopt(args,
           "silent|s", &silent,
           "use-jit|j", &use_jit,

           // allow the single dash to pass through
           config.passThrough, "|", &junk);

    if(args.length < 2) {
      writeln("expected an input file parameter\n");
      return -1;
    }

    auto f = stdin;
    if(args[1] != "-")
      f = File(args[1], "r");

    CodeObject co;
    try {
      if(!silent) writef("==== Assembling DynAsm ====\n");
      co = assembleFile(f, silent);
    } catch(DynAssemblerException ex) {
      writeln(ex.msg);
      return -1;
    }

    if(!silent) writeln("==== Starting execution ====");
    co.execute(use_jit, silent);

    return 0;
}
