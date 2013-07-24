import std.stdio;
import std.conv;

import dasm.code_obj;
import dasm.assembler;

int main(string args[])
{
    if(args.length < 2) {
      writeln("expected an input file parameter\n");
      return -1;
    }

    auto f = File(args[1], "r");
    try {

      CodeObject co = assembleFile(f);
      writeln(to!string(co));

    } catch(DynAssemblerException ex) {
      writeln(ex.msg);
      return -1;
    }

    return 0;
}
