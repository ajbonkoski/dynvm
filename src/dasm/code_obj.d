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
  uint num_locals = 0;

  int[][string] unresovedRefs; // a string hashtable of int[] arrays
  @property auto complete(){ return unresovedRefs.length == 0; }
  @property auto currentAddress() { return to!int(inst.length); }

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
    if(id) return *id;

    literal_to_uint[l] = next_literal_id;
    if(uint_to_literal.length == next_literal_id)
      uint_to_literal.length *= 2;
    uint_to_literal[next_literal_id] = l;

    return next_literal_id++;
  }

  uint addRegister(uint num)
  {
    if(num >= num_locals)
      num_locals = num+1;
    return num;
  }

  void addUnresovedRef(string unresolved, int lineno)
  {
    int[]* line_array = (unresolved in unresovedRefs);
    if(!line_array) {
      unresovedRefs[unresolved] = new int[0];
      line_array = (unresolved in unresovedRefs);
    }

    *line_array ~= lineno;
  }

  void resolveRefs(int[string] labelMap)
  {
    foreach(r; unresovedRefs.keys) {
      int l = labelMap[r];
      foreach(line; unresovedRefs[r]) {
        uint offset = int2sBx(l - (line+1));
        inst[line].resolveRef(offset);
      }
      unresovedRefs.remove(r);
    }
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
