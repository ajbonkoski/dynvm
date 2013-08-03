module interpret.dyn_obj;

import std.string;
import std.algorithm;
import dasm.literal;

class DynObject
{
  uint id;
  static uint next_id = 0;
  DynObject[string] table;

  this(){ id = next_id++; }

  override string toString()
  {
    return format("DynObject(id=%d%s)", id, toStringMembers());
  }

  string pretty()
  {
    return format("DynObject(id=%s)", id);
  }

  DynObject call(DynObject[] args)
  {
    assert(0, "Call attempted on uncallable DynObject");
  }

  string toStringMembers()
  {
    string s;
    foreach(k; table.keys.sort) {
      if(k.startsWith("__op_"))
        continue;
      s ~= format(", '%s'=%s", k, table[k]);
    }
    return s;
  }

}

class DynString : DynObject
{
  string s;
  this(string s_) { super(); s = s_; }
  override string toString()
  {
    return format("DynString(id=%d, \"%s\"%s)", id, s, toStringMembers());
  }

  override string pretty()
  {
    return format("\"%s\"", s);
  }
}

class DynInt : DynObject
{
  long i;
  this(long i_)
  {
    super();
    i = i_;

    table["__op_add"] = new DynNativeBinFunc(&NativeBinIntAdd, this);
    table["__op_sub"] = new DynNativeBinFunc(&NativeBinIntSub, this);
    table["__op_mul"] = new DynNativeBinFunc(&NativeBinIntMul, this);
    table["__op_div"] = new DynNativeBinFunc(&NativeBinIntDiv, this);
  }

  override string toString()
  {
    return format("DynInt(id=%d, %d%s)", id, i, toStringMembers());
  }

  override string pretty()
  {
    return format("%d", i);
  }
}

abstract class DynFunc : DynObject {}

alias DynObject function(DynObject a, DynObject b) NativeBinFunc;
class DynNativeBinFunc : DynFunc
{
  NativeBinFunc func;
  DynObject bind;
  this(NativeBinFunc func_, DynObject bind_){ super(); func = func_; bind = bind_; }

  override DynObject call(DynObject[] args)
  {
    assert(args.length == 1);
    return func(bind, args[0]);
  }

  override string toString()
  {
    return format("DynNativeBinFunc(id=%d)", id);
  }
}

/*** Native Binary Functions ***/
DynObject NativeBinIntAdd(DynObject a_, DynObject b_)
{
  DynInt a = cast(DynInt) a_;
  DynInt b = cast(DynInt) b_;
  return new DynInt(a.i + b.i);
}

DynObject NativeBinIntSub(DynObject a_, DynObject b_)
{
  DynInt a = cast(DynInt) a_;
  DynInt b = cast(DynInt) b_;
  return new DynInt(a.i - b.i);
}

DynObject NativeBinIntMul(DynObject a_, DynObject b_)
{
  DynInt a = cast(DynInt) a_;
  DynInt b = cast(DynInt) b_;
  return new DynInt(a.i * b.i);
}

DynObject NativeBinIntDiv(DynObject a_, DynObject b_)
{
  DynInt a = cast(DynInt) a_;
  DynInt b = cast(DynInt) b_;
  return new DynInt(a.i / b.i);
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

