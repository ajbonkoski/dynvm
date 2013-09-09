module vm.dyn_obj.dyn_native;

import std.string;
import std.conv;
import vm.dyn_obj.core;
import vm.gc.gc;
import vm.gc.types;


alias DynObject function(DynObject, DynObject) DynBinFunc;

alias DynNativeBinData* DynNativeBin;
struct DynNativeBinData
{
  DynObjectData obj;
  DynBinFunc func;
};

void DynNativeBin_init(DynNativeBin self, DynVTable vtable, DynBinFunc func)
{
  DynObject_init(&self.obj);
  self.obj.gcheader.rawtypedata = GCTypes.FuncArg2;
  self.obj.vtable = vtable;
  self.func = func;
}



alias DynObject function(DynObject) DynUnaryFunc;

alias DynNativeUnaryData* DynNativeUnary;
struct DynNativeUnaryData
{
  DynObjectData obj;
  DynUnaryFunc  func;
};

void DynNativeUnary_init(DynNativeUnary self, DynVTable vtable, DynUnaryFunc func)
{
  DynObject_init(&self.obj);
  self.obj.gcheader.rawtypedata = GCTypes.FuncArg1;
  self.obj.vtable = vtable;
  self.func = func;
}
