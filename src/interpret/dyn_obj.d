module interpret.dyn_obj;

import dasm.literal;

class DynObject
{

}

class DynString : DynObject
{
  string s;
  this(string s_) { s = s_; }
}

class DynInt : DynObject
{
  int i;
  this(int i_) { i = i_; }
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
}

