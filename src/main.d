import std.stdio;
import std.conv;

import code_obj;
import assembler;

int main(string args[])
{
    if(args.length < 2) {
      writeln("expected an input file parameter\n");
      return -1;
    }

    auto f = File(args[1], "r");
    CodeObject co = assembleFile(f);
    writeln(to!string(co));
    return 0;
}
