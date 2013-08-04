module interpret.dyn_obj;

import std.string;
import std.algorithm;
import std.conv;
import dasm.literal;

class DynObject
{
  uint id;
  DynObject parent;
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

  DynObject get(string name)
  {
    // search the inheritance chain
    DynObject obj = this;
    while(obj !is null) {
      DynObject* val = (name in obj.table);
      if(val)
        return *val;
      else
        obj = obj.parent;
    }

    assert(false, format("get operation failed in DynObject for '%s'", name));
  }

  void set(string name, DynObject obj)
  {
    table[name] = obj;
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

  // generic objects are always true!
  bool truthiness(){ return true; }
}

DynObject[string] classes;
static this() {
  classes["DynInt"]    = new DynIntClass();
  classes["DynString"] = new DynStringClass();
}

class DynStringClass : DynObject
{
  this() {
    table["__op_add"] = new DynNativeBinFunc(&NativeBinStrConcat);
  }
}

class DynIntClass : DynObject
{
  this() {
    table["__op_add"] = new DynNativeBinFunc(&NativeBinIntAdd);
    table["__op_sub"] = new DynNativeBinFunc(&NativeBinIntSub);
    table["__op_mul"] = new DynNativeBinFunc(&NativeBinIntMul);
    table["__op_div"] = new DynNativeBinFunc(&NativeBinIntDiv);
    table["__op_leq"] = new DynNativeBinFunc(&NativeBinIntLeq);
    table["__op_lt" ] = new DynNativeBinFunc(&NativeBinIntLt);
    table["__op_geq"] = new DynNativeBinFunc(&NativeBinIntGeq);
    table["__op_gt" ] = new DynNativeBinFunc(&NativeBinIntGt);
    table["__op_eq" ] = new DynNativeBinFunc(&NativeBinIntEq);
    table["__op_neq"] = new DynNativeBinFunc(&NativeBinIntNeq);
  }
}

class DynString : DynObject
{
  string s;
  this(string s_)
  {
    s = s_;
    parent = classes["DynString"];
  }

  override string toString()
  {
    return format("DynString(id=%d, \"%s\"%s)", id, s, toStringMembers());
  }

  override string pretty()
  {
    return format("\"%s\"", s);
  }

  // string truthiness is its length
  override bool truthiness(){ return s.length != 0; }
}

class DynInt : DynObject
{
  long i;

  this(long i_)
  {
    i = i_;
    parent = classes["DynInt"];
    assert(parent !is null);
  }

  override string toString()
  {
    return format("DynInt(id=%d, %d%s)", id, i, toStringMembers());
  }

  override string pretty()
  {
    return format("%d", i);
  }

  // int truthiness is C-style
  override bool truthiness(){ return i != 0; }
}

abstract class DynFunc : DynObject {}

alias DynObject function(DynObject a, DynObject b) NativeBinFunc;
class DynNativeBinFunc : DynFunc
{
  NativeBinFunc func;
  DynObject bind;
  this(NativeBinFunc func_){ func = func_; }
  this(NativeBinFunc func_, DynObject bind_){ func = func_; bind = bind_; }

  override DynObject call(DynObject[] args)
  {
    if(bind !is null) {
      assert(args.length == 1);
      return func(bind, args[0]);
    } else {
      assert(args.length == 2);
      return func(args[0], args[1]);
    }
  }

  override string toString()
  {
    return format("DynNativeBinFunc(id=%d)", id);
  }
}

/*** Native Binary Functions ***/
auto genNativeBinInt(string name, string op) { return
  "DynObject NativeBinInt"~name~"(DynObject a_, DynObject b_)"~
  "{"~
      "auto a = cast(DynInt) a_;"~
      "auto b = cast(DynInt) b_;"~
      "return new DynInt(to!long(a.i "~op~" b.i));"~
   "}";
}

mixin(genNativeBinInt("Add", "+"));
mixin(genNativeBinInt("Sub", "-"));
mixin(genNativeBinInt("Mul", "*"));
mixin(genNativeBinInt("Div", "/"));
mixin(genNativeBinInt("Leq", "<="));
mixin(genNativeBinInt("Lt",  "<"));
mixin(genNativeBinInt("Geq", ">="));
mixin(genNativeBinInt("Gt",  ">"));
mixin(genNativeBinInt("Eq",  "=="));
mixin(genNativeBinInt("Neq", "!="));

DynObject NativeBinStrConcat(DynObject a_, DynObject b_)
{
  auto a = cast(DynString) a_;
  auto b = cast(DynString) b_;
  return new DynString(a.s ~ b.s);
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

