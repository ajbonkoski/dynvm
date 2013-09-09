module vm.dyn_obj.dyn_obj;

public import vm.dyn_obj.core;
public import vm.dyn_obj.dyn_native;
public import vm.dyn_obj.dyn_int;
public import vm.dyn_obj.dyn_str;
public import vm.dyn_obj.dyn_array;
public import vm.dyn_obj.dyn_tag;

import std.stdio;
import std.string;
import std.algorithm;
import std.conv;
import std.format;
import common.common;
import hlasm.literal;
import vm.gc.gc;
import vm.gc.types;

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

  static DynObject create(T)(T val) if(is(T : long) || is(T : ulong))
  {
    return cast(DynObject) (val<<1);
  }

  static DynObject create(string T)() if(T == "object")
  {
    return DynObject_create;
  }
}

/******************************************************************/
/*** Helper functions to enable a UFCS style and ASM interfacing **/
/******************************************************************/

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

public string Dyn_toString(DynObject ctx)
{
  if(ctx.Dyn_tag_is_int)
    return format("%d", ctx.Dyn_untag_int);

  else {
    auto c = ctx.Dyn_untag_obj;
    return c.vtable.toString(c);
  }
}

public string Dyn_pretty(DynObject ctx)
{
  if(ctx.Dyn_tag_is_int)
    return format("%d", ctx.Dyn_untag_int);

  else {
    auto c = ctx.Dyn_untag_obj;
    return c.vtable.pretty(c);
  }
}

public bool Dyn_truthiness(DynObject ctx)
{
  if(ctx.Dyn_tag_is_int)
    return cast(long)ctx != 0 ? 1 : 0;

  else {
    auto c = ctx.Dyn_untag_obj;
    return c.vtable.truthiness(c);
  }
}


/*************************************************************/
/**************** Internal stats functions *******************/
/*************************************************************/

auto writeObjectStats(IndentedWriter iw)
{
  iw.formattedWrite("next_id: %d\n", DynObject.next_id);
  //iw.formattedWrite("DynIntClass pool dealloc count: %d\n", DynIntClass.singleton.pool_dealloc_cnt);
  return iw;
}
