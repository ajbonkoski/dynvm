module vm.dyn_obj.dyn_str;

import vm.dyn_obj.dyn_native;

import std.string;
import vm.dyn_obj.core;
import vm.gc.gc;
import vm.gc.types;

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
  auto vtable = DynNativeBinStr_createVTable!op;
  auto func = &DynNativeBinStr_binop!op;
  DynNativeBin_init(self, vtable, func);
  return cast(DynObject) self;
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



/*************************************************************/
/***************** DynStringClass Struct *********************/
/*************************************************************/

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
