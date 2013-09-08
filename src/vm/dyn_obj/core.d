module vm.dyn_obj.core;

import std.string;
import datastruct.hashtable;
import vm.gc.gc;
import vm.gc.types;

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
