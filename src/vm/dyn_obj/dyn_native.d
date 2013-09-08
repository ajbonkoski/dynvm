module vm.dyn_obj.dyn_native;

import std.string;
import std.conv;
import vm.dyn_obj.core;
import vm.gc.gc;
import vm.gc.types;


alias DynNativeBinData* DynNativeBin;
struct DynNativeBinData
{
  DynObjectData obj;
  DynObject function(DynObject a, DynObject b) func;
};

void DynNativeBin_init(DynNativeBin self, DynVTable vtable, DynObject function(DynObject a, DynObject b) func)
{
  DynObject_init(&self.obj);
  self.obj.gcheader.rawtypedata = GCTypes.FuncArg2;
  self.obj.vtable = vtable;
  self.func = func;
}

alias DynNativeUnaryData* DynNativeUnary;
struct DynNativeUnaryData
{
  DynObjectData obj;
  DynObject function(DynObject a) func;
};

void DynNativeUnary_init(DynNativeUnary self, DynVTable vtable, DynObject function(DynObject a) func)
{
  DynObject_init(&self.obj);
  self.obj.gcheader.rawtypedata = GCTypes.FuncArg1;
  self.obj.vtable = vtable;
  self.func = func;
}
