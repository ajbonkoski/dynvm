module vm.dyn_obj;

import std.format;

import std.stdio;
import std.string;
import std.algorithm;
import std.conv;
import common.common;
import hlasm.literal;
import datastruct.stack;
import datastruct.hashtable;
import vm.gc.gc;
import vm.gc.types;

auto writeObjectStats(IndentedWriter iw)
{
  iw.formattedWrite("next_id: %d\n", DynObject.next_id);
  //iw.formattedWrite("DynIntClass pool dealloc count: %d\n", DynIntClass.singleton.pool_dealloc_cnt);
  return iw;
}


/*************************************************************/
/********* Helper functions to enable a UFCS style ***********/
/*************************************************************/

public DynObject Dyn_get(DynObject ctx, string name)
{ return DynObject_get(name, ctx); }

public DynObject Dyn__template_get(string name)(DynObject ctx)
{ return DynObject_get(name, ctx); }

public DynObject Dyn_binop(string op)(DynObject a, DynObject b)
{
  auto func_obj = cast(DynNativeBin) DynObject_get(op, a);
  assert(func_obj.obj.gcheader.rawtypedata == GCTypes.FuncArg2, "Expected binary op");
  auto f = func_obj.func;
  return f(a, b);
}

public string Dyn_toString(DynObject ctx_)
{
  long l = cast(long) ctx_;
  if((l&1) == 0)
    return format("%d", l>>1);

  auto ctx = cast(DynObject) (cast(long)ctx_ & ~1);
  return ctx.vtable.toString(ctx);
}

public string Dyn_pretty(DynObject ctx_)
{
  long l = cast(long) ctx_;
  if((l&1) == 0)
    return format("%d", l>>1);

  auto ctx = cast(DynObject) (cast(long)ctx_ & ~1);
  return ctx.vtable.pretty(ctx);
}

public bool Dyn_truthiness(DynObject ctx_)
{
  long l = cast(long)ctx_;
  if((l & 1) == 0)
    return l != 0;

  auto ctx = cast(DynObject) (cast(long)ctx_ & ~1);
  return ctx.vtable.truthiness(ctx);
}



/*************************************************************/
/******************** DynVTable Struct ***********************/
/*************************************************************/

alias DynVTableData* DynVTable;
struct DynVTableData
{
  string function(DynObject)                         toString;
  string function(DynObject)                         pretty;
  bool function(DynObject)                           truthiness;
}

DynVTable InheritVTable(DynVTable vtable)
{
  auto vt = GCAlloc!DynVTableData;
  *vt = *vtable; // bitwise copy
  return vt;
}


/*************************************************************/
/******************* DynNativeBin Struct *********************/
/*************************************************************/

alias DynNativeBinData* DynNativeBin;
struct DynNativeBinData
{
  DynObjectData obj;
  DynObject function(DynObject a, DynObject b) func;
};

/*************************************************************/
/******************** DynObject Struct ***********************/
/*************************************************************/

alias DynObjectData* DynObject;
struct DynObjectData
{
  GCObjectHeader gcheader;
  uint id;
  DynObject parent = null;
  DynVTable vtable = null;
  Hashtable!DynObject table;

  // statics
  static string parent_name = "__parent__";
  static uint next_id = 0;
};

static DynVTable DynObject_vtable;
static this(){
  alias DynObject_vtable vt;
  vt = GCAlloc!DynVTableData;
  vt.toString   = &DynObject_toString;
  vt.pretty     = &DynObject_toString;
  vt.truthiness = &DynObject_truthiness;
}

DynObject DynObject_create()
{
  auto self = GCAlloc!DynObjectData;
  DynObject_init(self);
  return self;
}

void DynObject_init(DynObject self)
{
  self.id = DynObject.next_id++;
  self.table = null;
  self.vtable = DynObject_vtable;
}

string DynObject_toString(DynObject self)
{
  return format("DynObject(id=%d)", self.id);
}

// DynObject DynObject_call(DynObject[] args, DynObject self)
// {
//   assert(0, "Call attempted on uncallable DynObject");
// }

// DynObject DynObject_call1(DynObject a, DynObject self)
// {
//   assert(0, "Call attempted on uncallable DynObject");
// }

// DynObject DynObject_call2(DynObject a, DynObject b, DynObject self)
// {
//   assert(0, "Call attempted on uncallable DynObject");
// }

DynObject DynObject__template_get(string s)(DynObject self)
{
  return DynObject_get(s, self);
}

DynObject DynObject_get(string name, DynObject self)
{
  if(name == self.parent_name)
    return self.parent;

  // search the inheritance chain
  auto obj = self;
  while(obj) {
    // find next mapped table
    if(obj.table is null) {
      obj = obj.parent;
      continue;
    }

    DynObject* val = obj.table.get(name);
    if(val) {
      return *val;
    } else {
      obj = obj.parent;
    }
  }

  assert(false, format("get operation failed in DynObject for '%s'", name));
}

void DynObject_set(string name, DynObject obj, DynObject self)
{
  if(self.table is null)
    self.table = new DynvmHashTable!DynObject;
  self.table.set(name, obj);
}

bool DynObject_truthiness(DynObject self){ return true; }



/*************************************************************/
/**************** Native Binary Int Functions ****************/
/*************************************************************/

DynVTable DynNativeBinInt_createVTable(string op)()
{
  auto vt       = DynObject_vtable.InheritVTable;
  vt.toString   = &DynNativeBinInt_toString!op;
  return vt;
}

DynObject DynNativeBinInt_create(string op)()
{
  auto self = GCAlloc!DynNativeBinData;
  DynNativeBinInt_init!op(self);
  return cast(DynObject) self;
}

void DynNativeBinInt_init(string op)(DynNativeBin self)
{
  DynObject_init(&self.obj);
  self.obj.gcheader.rawtypedata = GCTypes.FuncArg2;
  self.obj.vtable = DynNativeBinInt_createVTable!op;
  self.func = &DynNativeBinInt_binop!op;
}

DynObject DynNativeBinInt_binop(string op)(DynObject a_, DynObject b_) {
   auto a = cast(DynInt) a_;
   auto b = cast(DynInt) b_;
   return DynInt_create(mixin("(a.i"~op~"b.i)").to!long);
}

string DynNativeBinInt_toString(string op)(DynObject self_)
{
  auto self = cast(DynNativeBin) self_;
  return format("DynNativeBinInt(id=%d, op=%s)", self.obj.id, op);
}



/*************************************************************/
/******************* DynIntClass Struct **********************/
/*************************************************************/

alias DynIntClassData* DynIntClass;
struct DynIntClassData
{
  DynObjectData obj;

  // statics
  static DynIntClass singleton = null;
}

static this()
{
  DynIntClassData.singleton = GCAlloc!DynIntClassData;
  auto obj = &DynIntClassData.singleton.obj;
  DynObject_init(obj);
  DynObject_set("__op_add", DynNativeBinInt_create!"+",  obj);
  DynObject_set("__op_sub", DynNativeBinInt_create!"-",  obj);
  DynObject_set("__op_mul", DynNativeBinInt_create!"*",  obj);
  DynObject_set("__op_div", DynNativeBinInt_create!"/",  obj);
  DynObject_set("__op_leq", DynNativeBinInt_create!"<=", obj);
  DynObject_set("__op_lt" , DynNativeBinInt_create!"<",  obj);
  DynObject_set("__op_geq", DynNativeBinInt_create!">=", obj);
  DynObject_set("__op_gt" , DynNativeBinInt_create!">",  obj);
  DynObject_set("__op_eq" , DynNativeBinInt_create!"==", obj);
  DynObject_set("__op_neq", DynNativeBinInt_create!"!=", obj);
}



/*************************************************************/
/********************* DynInt Struct *************************/
/*************************************************************/

alias DynIntData* DynInt;
struct DynIntData
{
  DynObjectData obj;
  long i;
}

static DynVTable DynInt_vtable;
static this(){
  alias DynInt_vtable vt;
  vt            = DynObject_vtable.InheritVTable;
  vt.toString   = &DynInt_toString;
  vt.pretty     = &DynInt_pretty;
  vt.truthiness = &DynInt_truthiness;
}

DynObject DynInt_create(long i)
{
  auto self = GCAlloc!DynIntData;
  DynInt_init(i, self);
  return cast(DynObject) self;
}

void DynInt_init(long i, DynInt self)
{
  auto obj = &self.obj;
  DynObject_init(obj);
  obj.parent = cast(DynObject) DynIntClass.singleton;
  assert(obj.parent !is null);
  obj.vtable = DynInt_vtable;
  self.i = i;
}

string DynInt_toString(DynObject self_)
{
  auto self = cast(DynInt) self_;
  return format("DynInt(id=%d, %d)", self.obj.id, self.i);
}

string DynInt_pretty(DynObject self_)
{
  auto self = cast(DynInt) self_;
  return format("%d", self.i);
}

// int truthiness is C-style
bool DynInt_truthiness(DynObject self_)
{
  auto self = cast(DynInt) self_;
  return self.i != 0;
}


/*************************************************************/
/**************** Native Binary Str Functions ****************/
/*************************************************************/

DynVTable DynNativeBinStr_createVTable(string op)()
{
  auto vt       = DynObject_vtable.InheritVTable;
  vt.toString   = &DynNativeBinStr_toString!op;
  return vt;
}

DynObject DynNativeBinStr_create(string op)()
{
  auto self = GCAlloc!DynNativeBinData;
  DynNativeBinStr_init!op(self);
  return cast(DynObject) self;
}

void DynNativeBinStr_init(string op)(DynNativeBin self)
{
  DynObject_init(&self.obj);
  self.obj.gcheader.rawtypedata = GCTypes.FuncArg2;
  self.obj.vtable = DynNativeBinStr_createVTable!op;
  self.func = &DynNativeBinStr_binop!op;
}


DynObject DynNativeBinStr_binop(string op)(DynObject a_, DynObject b_) {
   auto a = cast(DynString) a_;
   auto b = cast(DynString) b_;
   static if(op == "+") {
     return DynString_create(a.s ~ b.s);
   } else {
     static assert(false, format("Error, unrecogized op in DynNativeBinStr_binop: %s", op));
   }
}

string DynNativeBinStr_toString(string op)(DynObject self_)
{
  auto self = cast(DynNativeBin) self_;
  return format("DynNativeBinStr(id=%d, op=%s)", self.obj.id, op);
}



// /*************************************************************/
// /***************** DynStringClass Struct *********************/
// /*************************************************************/

alias DynStringClassData* DynStringClass;
struct DynStringClassData
{
  DynObjectData obj;

  // statics
  static DynStringClass singleton = null;
}

static this()
{
  DynStringClassData.singleton = GCAlloc!DynStringClassData;
  auto obj = &DynStringClassData.singleton.obj;
  DynObject_init(obj);
  DynObject_set("__op_add", DynNativeBinStr_create!"+",  obj);
}



// /*************************************************************/
// /******************** DynString Struct ***********************/
// /*************************************************************/

alias DynStringData* DynString;
struct DynStringData
{
  DynObjectData obj;
  string s;
}

static DynVTable DynString_vtable;
static this(){
  alias DynString_vtable vt;
  vt            = DynObject_vtable.InheritVTable;
  vt.toString   = &DynString_toString;
  vt.pretty     = &DynString_pretty;
  vt.truthiness = &DynString_truthiness;
}

DynObject DynString_create(string s)
{
  auto self = GCAlloc!DynStringData;
  DynString_init(s, self);
  return cast(DynObject) self;
}

void DynString_init(string s, DynString self)
{
  auto obj = &self.obj;
  DynObject_init(obj);
  obj.parent = cast(DynObject) DynStringClass.singleton;
  assert(obj.parent !is null);
  obj.vtable = DynString_vtable;
  self.s = s;
}

string DynString_toString(DynObject self_)
{
  auto self = cast(DynString) self_;
  return format("DynString(id=%d, \"%s\")", self.obj.id, self.s);
}

string DynString_pretty(DynObject self_)
{
  auto self = cast(DynString) self_;
  return format("\"%s\"", self.s);
}

// int truthiness is C-style
bool DynString_truthiness(DynObject self_)
{
  auto self = cast(DynString) self_;
  return self.s.length != 0;
}






struct DynObjectBuiltin
{
  static DynObject create(T)(T val) if(is(T == Literal))
  {
    final switch(val.type)
    {
      case LType.String:  return DynString_create(val.s);
      case LType.Int:     return DynInt_create(val.i);
    }
  }

  static DynObject create(string T)() if(T == "object")
  {
    return DynObject_create;
  }
}

