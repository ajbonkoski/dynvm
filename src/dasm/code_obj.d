module dasm.code_obj;

import std.conv;
import std.stdio;

import dasm.instructions;

enum max_stack = 256;

class CodeObject
{
  Instruction[] inst;
  uint[int]     int_literal;
  uint[string]  string_literal;
  uint next_literal_id = 0;

  uint num_locals = max_stack;

  void addInstr(Instruction i)
  {
    inst ~= i;
  }

  uint addLiteral(T)(T literal)
    if(is(T == string) || is(T == int))
  {
    enum dict = T.stringof ~ "_literal";

    uint *id = (literal in mixin(dict));
    if(id != null)
      return *id;

    mixin(dict)[literal] = next_literal_id;
    return next_literal_id++;
  }

  override string toString()
  {
    string s = "[";
    foreach(n, i; inst) {
      s ~= "\"" ~ i.toString() ~ "\"";
      if(n != inst.length-1)
        s ~= ", ";
    }
    s ~= "]";
    return s;
  }


}
