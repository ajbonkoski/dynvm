module vm.dyn_obj;

import std.format;

import std.string;
import std.algorithm;
import std.conv;
import common.common;
import hlasm.literal;
import datastruct.stack;
import datastruct.hashtable;

auto writeObjectStats(IndentedWriter iw)
{
  iw.formattedWrite("next_id: %d\n", DynObject.next_id);
  iw.formattedWrite("DynIntClass pool dealloc count: %d\n", DynIntClass.singleton.pool_dealloc_cnt);
  return iw;
}

// a stub to perform the virt. table lookup, to make calling
// easier from jit'd code...
public DynObject DynObject_call2(DynObject a, DynObject b, DynObject ctx)
{
  return ctx.call(a, b);
}

public bool DynObject_truthiness(DynObject ctx)
{
  return ctx.truthiness;
}

class DynObject
{
  uint id;
  static uint next_id = 0;
  int refcnt = 0;

  DynvmHashTable!DynObject my_table = null;
  DynvmHashTable!DynObject table = null;

  DynObject parent;
  static string parent_name = "__parent__";

  this(){
    id = next_id++;
  }

  final void incref(){ refcnt++; }
  final void decref(){ if(--refcnt <= 0) this.freed(); }

  // ignore the freed signal by default
  void freed(){}

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

  DynObject call(DynObject a)
  {
    assert(0, "Call attempted on uncallable DynObject");
  }

  DynObject call(DynObject a, DynObject b)
  {
    assert(0, "Call attempted on uncallable DynObject");
  }

  final DynObject __template_get(string s)()
  {
    return this.get(s);
  }

  final DynObject get(string name)
  {
    if(name == parent_name)
      return parent;

    if(table is null) {
      if(my_table is null)
        table = parent.table;
      else
        table = my_table;
    }

    // precompute the hash (to save time)
    ulong hash = table.computeHash(name);

    // search the inheritance chain
    DynObject obj = this;
    while(obj) {

      DynObject* val = null;

      ////////////////////////////////////////////////////
      // table.get: manually inlined because DMD won't
      auto data = obj.table.table[hash];
      if(data.length == 1)
        val = &data[0].value;
      else {
        foreach(pair; data) {
          if(pair.key == name) {
            val = &pair.value;
            break;
          }
        }
      }
      //////////////////////////////////////////////


      if(val) return *val;
      else    obj = obj.parent;
    }

    assert(false, format("get operation failed in DynObject for '%s'", name));
  }

  final void ensure_init()
  {
    if(table !is null)
      return;

    // we only init table on demand!
    my_table = new DynvmHashTable!DynObject();
    table = my_table;
  }

  final void set(string name, DynObject obj)
  {
    if(name == parent_name) {
      parent = obj;
      return;
    }

    ensure_init();
    table.set(name, obj);
  }

  string toStringMembers()
  {
    // string s;
    // foreach(k; table.keys.sort) {
    //   if(k.startsWith("__op_"))
    //     continue;
    //   s ~= format(", '%s'=%s", k, table[k]);
    // }
    // return s;
    return "";
  }

  // generic objects are always true!
  bool truthiness(){ return true; }
}

class DynStringClass : DynObject
{
  static DynStringClass singleton;
  static this() { singleton = new DynStringClass(); }

  this() {
    set("__op_add", new DynNativeBinFunc(&NativeBinStrConcat));
  }
}

class DynIntClass : DynObject
{
  static DynIntClass singleton;
  static this() { singleton = new DynIntClass(); }

  this() {
    set("__op_add", new DynNativeBinInt!("+"));
    set("__op_sub", new DynNativeBinInt!("-"));
    set("__op_mul", new DynNativeBinInt!("*"));
    set("__op_div", new DynNativeBinInt!("/"));
    set("__op_leq", new DynNativeBinInt!("<="));
    set("__op_lt" , new DynNativeBinInt!("<"));
    set("__op_geq", new DynNativeBinInt!(">="));
    set("__op_gt" , new DynNativeBinInt!(">"));
    set("__op_eq" , new DynNativeBinInt!("=="));
    set("__op_neq", new DynNativeBinInt!("!="));
  }

  auto pool = new Stack!DynInt;
  int pool_dealloc_cnt = 0;
  DynInt allocate(long i)
  {
    if(pool.length) {
      DynInt di = pool.pop();
      di.refcnt = 0;
      di.init(i);
      return di;
    }

    else
      return new DynInt(i);
  }

  void deallocate(DynInt di)
  {
    //import std.stdio;
    //writeln("DynInt dealloc\n");
    pool.push(di);
    pool_dealloc_cnt++;
  }

}

DynObject[string] classes;
static this() {
  classes["DynInt"]    = DynIntClass.singleton;
  classes["DynString"] = DynStringClass.singleton;
}

class DynString : DynObject
{
  string s;
  this(string s_)
  {
    s = s_;
    parent = DynStringClass.singleton;
    assert(parent !is null);
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

  private this(long i_)
  {
    i = i_;
    parent = DynIntClass.singleton;
    assert(parent !is null);
  }

  private void init(long i_) { i = i_; }

  override void freed()
  {
    DynIntClass.singleton.deallocate(this);
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

//abstract class DynFunc : DynObject {}

alias DynObject function(DynObject a, DynObject b) NativeBinFunc;
class DynNativeBinFunc : DynObject
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

  override DynObject call(DynObject a)
  {
    assert(bind !is null);
    return func(bind, a);
  }

  override DynObject call(DynObject a, DynObject b)
  {
    assert(bind is null);
    return func(a, b);
  }

  override string toString()
  {
    return format("DynNativeBinFunc(id=%d)", id);
  }
}

/*** Native Binary Functions ***/
final class DynNativeBinInt(string op) : DynObject
{

  final DynInt f(DynObject a_, DynObject b_) {
    auto a = cast(DynInt) a_;
    auto b = cast(DynInt) b_;
    return DynIntClass.singleton.allocate(mixin("a.i"~op~"b.i").to!long);
  }

  override DynObject call(DynObject[] args)
  {  assert(args.length == 2); return f(args[0], args[1]);  }

  override DynObject call(DynObject a)
  {
    assert(false);
  }

  override DynObject call(DynObject a, DynObject b)
  {  return f(a, b);  }

  override string toString()
  {
    return format("DynNativeBinInt(id=%d)", id);
  }

}

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
      case LType.Int:     return DynIntClass.singleton.allocate(val.i);
    }
  }

  static DynObject create(string T)() if(T == "object")
  {
    return new DynObject();
  }
}

