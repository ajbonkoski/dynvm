module dasm.code_obj;

import std.conv;
import std.stdio;

import dasm.instructions;
import dasm.literal;

enum max_stack = 256;
enum init_size = 16;

class CodeObject
{
  Instruction[] inst;
  uint[Literal]  literal_to_uint;
  Literal[]      uint_to_literal;
  uint next_literal_id = 0;

  uint num_locals = max_stack;

  this()
  {
    uint_to_literal.length = init_size;
  }

  void addInstr(Instruction i)
  {
    inst ~= i;
  }

  uint addLiteral(Literal l)
  {
    uint *id = (l in literal_to_uint);
    if(id != null)
      return *id;

    literal_to_uint[l] = next_literal_id;
    if(uint_to_literal.length == next_literal_id)
      uint_to_literal.length *= 2;
    uint_to_literal[next_literal_id] = l;

    return next_literal_id++;
  }

  Literal getLiteral(uint i)
  {
    assert(i < next_literal_id);
    return uint_to_literal[i];
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
