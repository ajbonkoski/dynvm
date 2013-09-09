module vm.dyn_obj.dyn_array;

import vm.dyn_obj.dyn_native;

import std.stdio;
import std.string;
import std.conv;
import vm.dyn_obj.core;
import vm.dyn_obj.dyn_obj : DynObjectBuiltin, Dyn_pretty;
import vm.dyn_obj.dyn_tag;
import vm.gc.gc;
import vm.gc.types;

/*************************************************************/
/******************* Native Array Functions ******************/
/*************************************************************/

static DynVTable DynNativeArray_vtable;
static this() {
  alias DynNativeArray_vtable vt;
  vt            = DynObject_vtable.InheritVTable;
  vt.toString   = &DynNativeArray_toString;
}

DynObject DynNativeTriArray_create(DynTriFunc func)
{
  auto self = GCAlloc!DynNativeTriData;
  auto vtable = DynNativeArray_vtable;
  DynNativeTri_init(self, vtable, func);
  return cast(DynObject) self;
}

DynObject DynNativeBinArray_create(DynBinFunc func)
{
  auto self = GCAlloc!DynNativeBinData;
  auto vtable = DynNativeArray_vtable;
  DynNativeBin_init(self, vtable, func);
  return cast(DynObject) self;
}

DynObject DynNativeUnaryArray_create(DynUnaryFunc func)
{
  auto self = GCAlloc!DynNativeUnaryData;
  auto vtable = DynArray_vtable;
  DynNativeUnary_init(self, vtable, func);
  return cast(DynObject) self;
}

string DynNativeArray_toString(DynObject self)
{
  return format("DynNativeArray(id=%d)", self.id);
}

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
  DynObject_set("length", DynNativeUnaryArray_create(&DynArray_length), obj);
  DynObject_set("add",    DynNativeBinArray_create(&DynArray_add),      obj);
  DynObject_set("set",    DynNativeTriArray_create(&DynArray_set),      obj);
  DynObject_set("get",    DynNativeBinArray_create(&DynArray_get),      obj);
}



/*************************************************************/
/******************** DynArray Struct ************************/
/*************************************************************/

alias DynArrayData* DynArray;
struct DynArrayData
{
  DynObjectData obj;
  DynObject* array;
  ulong length;
  ulong alloc;
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
  assert(initalloc > 0);

  auto self = GCAlloc!DynArrayData;
  DynArray_init(initalloc, self);
  return cast(DynObject) self;
}

void DynArray_init(ulong initalloc, DynArray self)
{
  assert(initalloc > 0);

  auto obj = &self.obj;
  DynObject_init(obj);
  obj.parent = cast(DynObject) DynArrayClass.singleton;
  assert(obj.parent !is null);
  obj.vtable = DynArray_vtable;
  self.array = GCAlloc!DynObject(initalloc);
  self.alloc = initalloc;
  self.length = 0;
}

string DynArray_toString(DynObject self_)
{
  auto self = cast(DynArray) self_.Dyn_untag_obj;
  return format("DynArray(id=%d, length=%d)", self.obj.id, self.length);
}

string DynArray_pretty(DynObject self_)
{
  auto self = cast(DynArray) self_.Dyn_untag_obj;

  string s = "[";
  ulong len = self.length;
  for(ulong i = 0; i < len; i++) {
    s ~= self.array[i].Dyn_pretty;
    if(i != len-1)
      s ~= ", ";
  }
  s ~= "]";

  return s;
}

// int truthiness is C-style
bool DynArray_truthiness(DynObject self_)
{
  auto self = cast(DynArray) self_.Dyn_untag_obj;
  return self.length != 0;
}


/*********************/
/* special functions */
/*********************/

DynObject DynArray_length(DynObject self_)
{
  DynArray self = cast(DynArray) self_.Dyn_untag_obj;
  return DynObjectBuiltin.create(self.length);
}

DynObject DynArray_add(DynObject self_, DynObject obj)
{
  DynArray self = cast(DynArray) self_.Dyn_untag_obj;

  // need to realloc?
  if(self.length >= self.alloc) {
    auto old_alloc = self.alloc;
    self.alloc *= 2;
    self.array = GCRealloc!DynObject(self.array, old_alloc, self.alloc);
  }

  self.array[self.length] = obj;
  self.length++;

  return null;
}

DynObject DynArray_set(DynObject self_, DynObject index, DynObject obj)
{
  DynArray self = cast(DynArray) self_.Dyn_untag_obj;
  assert(index.Dyn_tag_is_int);
  long i = index.Dyn_untag_int;
  assert(i < self.length);
  self.array[i] = obj;

  return null;
}

DynObject DynArray_get(DynObject self_, DynObject index)
{
  DynArray self = cast(DynArray) self_.Dyn_untag_obj;
  assert(index.Dyn_tag_is_int);
  long i = index.Dyn_untag_int;
  assert(i < self.length);
  return self.array[i];

}

// DynObject DynArray_get(DynObject self_, DynObject obj)
// {
//   DynArray self = cast(DynArray) self_;
//   return DynObjectBuiltin.create(self.length);
// }

// DynObject DynArray_set(DynObject self_, DynObject obj)
// {
//   DynArray self = cast(DynArray) self_;
//   return DynObjectBuiltin.create(self.length);
// }
