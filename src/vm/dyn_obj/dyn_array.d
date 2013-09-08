module vm.dyn_obj.dyn_array;

import vm.dyn_obj.dyn_native;

import std.string;
import vm.dyn_obj.core;
import vm.gc.gc;
import vm.gc.types;

/*************************************************************/
/****************** DynArrayClass Struct *********************/
/*************************************************************/

alias DynArrayClassData* DynArrayClass;
struct DynArrayClassData
{
  DynObjectData obj;

  // statics
  static DynArrayClass singleton = null;
}

static this()
{
  DynArrayClassData.singleton = GCAlloc!DynArrayClassData;
  auto obj = &DynArrayClassData.singleton.obj;
  DynObject_init(obj);
}



/*************************************************************/
/******************** DynArray Struct ************************/
/*************************************************************/

alias DynArrayData* DynArray;
struct DynArrayData
{
  DynObjectData obj;
  DynObject[] array;
  ulong length;
}

static DynVTable DynArray_vtable;
static this(){
  alias DynArray_vtable vt;
  vt            = DynObject_vtable.InheritVTable;
  vt.toString   = &DynArray_toString;
  vt.pretty     = &DynArray_pretty;
  vt.truthiness = &DynArray_truthiness;
}

DynObject DynArray_create(ulong initalloc)
{
  auto self = GCAlloc!DynArrayData;
  DynArray_init(initalloc, self);
  return cast(DynObject) self;
}

void DynArray_init(ulong initalloc, DynArray self)
{
  auto obj = &self.obj;
  DynObject_init(obj);
  obj.parent = cast(DynObject) DynArrayClass.singleton;
  assert(obj.parent !is null);
  obj.vtable = DynArray_vtable;
  self.array.length = initalloc;
  self.length = 0;
}

string DynArray_toString(DynObject self_)
{
  auto self = cast(DynArray) self_;
  return format("DynArray(id=%d, length=%d)", self.obj.id, self.length);
}

string DynArray_pretty(DynObject self_)
{
  auto self = cast(DynArray) self_;
  return format("length=%d", self.length);
}

// int truthiness is C-style
bool DynArray_truthiness(DynObject self_)
{
  auto self = cast(DynArray) self_;
  return self.length != 0;
}
