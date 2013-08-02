module interpret.dyn_obj;

import std.string;
import dasm.literal;

class DynObject
{
  uint id;
  static uint next_id = 0;
  DynObject[string] table;

  this(){ id = next_id++; }

  override string toString()
  {
    string s = format("DynObject(id=%d", id);
    foreach(k; table.keys.sort)
      s ~= format(", %s=%s", k, table[k]);
    return s ~ ")";
  }
}

class DynString : DynObject
{
  string s;
  this(string s_) { super(); s = s_; }
  override string toString()
  {
    return format("DynString(id=%d, \"%s\")", id, s);
  }
}

class DynInt : DynObject
{
  int i;
  this(int i_) { super(); i = i_; }
  override string toString()
  {
    return format("DynInt(id=%d, %d)", id, i);
  }
}

struct DynObjectBuiltin
{
  static DynObject create(T)(T val) if(is(T == Literal))
  {
    final switch(val.type)
    {
      case LType.String:  return new DynString(val.s);
      case LType.Int:     return new DynInt(val.i);
    }
  }

  static DynObject create(string T)() if(T == "object")
  {
    return new DynObject();
  }
}

