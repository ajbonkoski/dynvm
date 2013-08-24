module vm.dyn_obj;

import std.format;

import std.string;
import std.algorithm;
import std.conv;
import common.common;
import hlasm.literal;
import datastruct.stack;
import datastruct.hashtable;
import vm.gc.gc;

auto writeObjectStats(IndentedWriter iw)
{
  iw.formattedWrite("next_id: %d\n", DynObject.next_id);
  //iw.formattedWrite("DynIntClass pool dealloc count: %d\n", DynIntClass.singleton.pool_dealloc_cnt);
  return iw;
}

// a stub to perform the virt. table lookup, to make calling
// easier from jit'd code...
public DynObject DynObject_call2(DynObject a, DynObject b, DynObject ctx)
{
  return ctx.call2(a, b);
}

public bool DynObject_truthiness(DynObject ctx)
{
  return ctx.truthiness;
}

alias DynObjectVTableData* DynObjectVTable;
struct DynObjectVTableData
{
  string function(void*)                               toString;
  DynObject function(DynObject[] args, void*)          call;
  DynObject function(DynObject a, void*)               call1;
  DynObject function(DynObject a, DynObject b, void*)  call2;
  bool function(void*)                                 truthiness;
}

alias DynObjectData* DynObject;
immutable DynObjectInherit = "DynObjectData inherit; alias inherit this;";
struct DynObjectData
{
  /*** Data ***/
  GCObjectHeader gcheader;
  uint id;
  DynObject parent;
  DynObjectVTable vtable;

  static DynObjectVTable myvtable;
  static this(){
    myvtable = cast(DynObjectVTable)  GCAlloc(DynObjectVTableData.sizeof);
    myvtable.toString   = cast(string function(void*)) (&DynObject.toString).funcptr;
    myvtable.call       = cast(DynObject function(DynObject[],void*)) (&DynObject.call).funcptr;
    myvtable.call1      = cast(DynObject function(DynObject,void*)) (&DynObject.call1).funcptr;
    myvtable.call2      = cast(DynObject function(DynObject,DynObject,void*)) (&DynObject.call2).funcptr;
    myvtable.truthiness = cast(bool function(void*)) (&DynObject.truthiness).funcptr;
  }


  DynvmHashTable!DynObject my_table = null;
  DynvmHashTable!DynObject table = null;

  /*** Methods ***/
  static string parent_name = "__parent__";
  static uint next_id = 0;

  static DynObject create()
  {
    auto obj = GCAlloc!DynObjectData;
    (*obj).init();
    return obj;
  }

  void init()
  {
    id = next_id++;
    vtable = myvtable;
  }

  string toString()
  {
    return format("DynObject(id=%d)");
  }

  DynObject call(DynObject[] args)
  {
    assert(0, "Call attempted on uncallable DynObject");
  }

  DynObject call1(DynObject a)
  {
    assert(0, "Call attempted on uncallable DynObject");
  }

  DynObject call2(DynObject a, DynObject b)
  {
    assert(0, "Call attempted on uncallable DynObject");
  }

  DynObject __template_get(string s)()
  {
    return this.get(s);
  }

  DynObject get(string name)
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
    DynObject obj = &this;
    while(obj) {

      DynObject* val = null;
      val = table.get(name);
      if(val) return *val;
      else    obj = obj.parent;
    }

    assert(false, format("get operation failed in DynObject for '%s'", name));
  }

  void ensure_init()
  {
    if(table !is null)
      return;

    // we only init table on demand!
    my_table = new DynvmHashTable!DynObject();
    table = my_table;
  }

  void set(string name, DynObject obj)
  {
    if(name == parent_name) {
      parent = obj;
      return;
    }

    ensure_init();
    table.set(name, obj);
  }

  // generic objects are always true!
  bool truthiness(){ return true; }
}

// class DynStringClass : DynObject
// {
//   static DynStringClass singleton;
//   static this() { singleton = new DynStringClass(); }

//   this() {
//     set("__op_add", new DynNativeBinFunc(&NativeBinStrConcat));
//   }
// }

alias DynIntClassData* DynIntClass;
struct DynIntClassData
{
  // data: notice, this is just a simple DynObject that is preinit
  mixin(DynObjectInherit);

  // methods/statics
  static DynIntClass singleton;
  static this()
  {
    singleton = GCAlloc!DynIntClassData;
    with(*singleton) {
      // set("__op_add", new DynNativeBinInt!("+"));
      // set("__op_sub", new DynNativeBinInt!("-"));
      // set("__op_mul", new DynNativeBinInt!("*"));
      // set("__op_div", new DynNativeBinInt!("/"));
      // set("__op_leq", new DynNativeBinInt!("<="));
      // set("__op_lt" , new DynNativeBinInt!("<"));
      // set("__op_geq", new DynNativeBinInt!(">="));
      // set("__op_gt" , new DynNativeBinInt!(">"));
      // set("__op_eq" , new DynNativeBinInt!("=="));
      // set("__op_neq", new DynNativeBinInt!("!="));
    }
  }
}

// class DynString : DynObject
// {
//   string s;
//   this(string s_)
//   {
//     s = s_;
//     parent = DynStringClass.singleton;
//     assert(parent !is null);
//   }

//   override string toString()
//   {
//     return format("DynString(id=%d, s=%s)", id, s);
//   }

//   override string pretty()
//   {
//     return format("\"%s\"", s);
//   }

//   // string truthiness is its length
//   override bool truthiness(){ return s.length != 0; }
// }

alias DynIntData* DynInt;
struct DynIntData
{
  // data
  mixin(DynObjectInherit);
  long i;

  // methods/statics
  static DynObjectVTable myvtable;
  static this(){
    myvtable = cast(DynObjectVTable) GCAlloc(DynObjectVTableData.sizeof);
    myvtable.toString  = cast(string function(void*)) (&DynInt.toString).funcptr;
    myvtable.call = DynObject.myvtable.call;
    myvtable.call1 = DynObject.myvtable.call1;
    myvtable.call2 = DynObject.myvtable.call2;
    myvtable.truthiness = cast(bool function(void*)) (&DynInt.truthiness).funcptr;
  }

  static DynInt create(long i_)
  {
    DynInt obj = GCAlloc!DynIntData;
    (*obj).init(i_);
    return obj;
  }

  void init(long i_)
  {
    i = i_;
    parent = DynIntClass.singleton;
    assert(parent !is null);
    vtable = myvtable;
  }

  string toString()
  {
    return format("DynInt(id=%d, %d)", id, i);
  }

  // int truthiness is C-style
  bool truthiness(){ return i != 0; }
}

//abstract class DynFunc : DynObject {}

// alias DynObject function(DynObject a, DynObject b) NativeBinFunc;
// class DynNativeBinFunc : DynObject
// {
//   NativeBinFunc func;
//   DynObject bind;
//   this(NativeBinFunc func_){ func = func_; }
//   this(NativeBinFunc func_, DynObject bind_){ func = func_; bind = bind_; }

//   override DynObject call(DynObject[] args)
//   {
//     if(bind !is null) {
//       assert(args.length == 1);
//       return func(bind, args[0]);
//     } else {
//       assert(args.length == 2);
//       return func(args[0], args[1]);
//     }
//   }

//   override DynObject call(DynObject a)
//   {
//     assert(bind !is null);
//     return func(bind, a);
//   }

//   override DynObject call(DynObject a, DynObject b)
//   {
//     assert(bind is null);
//     return func(a, b);
//   }

//   override string toString()
//   {
//     return format("DynNativeBinFunc(id=%d)", id);
//   }
// }



/*** Native Binary Functions ***/
// final class DynNativeBinInt(string op) : DynObject
// {

//   final DynInt f(DynObject a_, DynObject b_) {
//     auto a = cast(DynInt) a_;
//     auto b = cast(DynInt) b_;
//     return DynInt.create(mixin("a.i"~op~"b.i").to!long);
//   }

//   override DynObject call(DynObject[] args)
//   {  assert(args.length == 2); return f(args[0], args[1]);  }

//   override DynObject call(DynObject a)
//   {
//     assert(false);
//   }

//   override DynObject call(DynObject a, DynObject b)
//   {  return f(a, b);  }

//   override string toString()
//   {
//     return format("DynNativeBinInt(id=%d)", id);
//   }

// }



// DynObject NativeBinStrConcat(DynObject a_, DynObject b_)
// {
//   auto a = cast(DynString) a_;
//   auto b = cast(DynString) b_;
//   return new DynString(a.s ~ b.s);
// }


struct DynObjectBuiltin
{
  static DynObject create(T)(T val) if(is(T == Literal))
  {
    final switch(val.type)
    {
      case LType.String:  assert(false, "String in unimpl");//return new DynString(val.s);
      case LType.Int:     return DynInt.create(val.i);
    }
  }

  static DynObject create(string T)() if(T == "object")
  {
    return DynObject.create;
  }
}

