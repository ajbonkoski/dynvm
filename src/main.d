import core.memory;
import std.stdio;
import std.conv;
import std.getopt;

import hlasm.code_obj;
import hlasm.assembler;
import vm.interpreter;

int main(string args[])
{
  bool silent = false, junk;
    getopt(args,
           "silent|s", &silent,

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
    interpretCode(co, silent);


    return 0;
}
