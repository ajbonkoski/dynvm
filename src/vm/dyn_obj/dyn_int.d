module vm.dyn_obj.dyn_int;

import vm.dyn_obj.dyn_native;

import std.string;
import std.conv;
import vm.dyn_obj.core;
import vm.gc.gc;
import vm.gc.types;

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
  auto vtable = DynNativeBinInt_createVTable!op;
  auto func = &DynNativeBinInt_binop!op;
  DynNativeBin_init(self, vtable, func);
  return cast(DynObject) self;
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
