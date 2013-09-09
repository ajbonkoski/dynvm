module vm.stack_frame;

import std.format;

import common.common;
import hlasm.code_obj;
import hlasm.literal;
import hlasm.instructions;
import vm.dyn_obj.dyn_obj;

final class StackFrame
{
  CodeObject code;
  DynObject[] locals;
  uint pc;

  this(CodeObject co)
  {
    code = co;
    locals.length = co.num_locals;
    pc = 0;
  }

  Instruction fetchInstr()
  {
    return code.inst[pc++];
  }

  void setRegister(uint regnum, DynObject obj)
  {
    assert(regnum < locals.length);
    //DynObject old = locals[regnum];
    //if(old !is null) old.decref();
    //if(obj !is null) obj.incref();
    locals[regnum] = obj;
  }

  DynObject getRegister(uint regnum)
  {
    assert(regnum < locals.length);
    return locals[regnum];
  }

  Literal getLiteral(uint num)
  {
    return code.getLiteral(num);
  }

  long requireLiteralInt(uint num)
  {
    Literal l = code.getLiteral(num);
    assert(l.type == LType.Int);
    return l.i;
  }

  DynObject getLiteralObj(uint num)
  {
    Literal l = code.getLiteral(num);

    // use integer unboxing?
    if(l.type == LType.Int)
      return cast(DynObject) (l.i<<1);

    // regular object... set the tag...
    auto obj = DynObjectBuiltin.create(l);
    return cast(DynObject) (cast(long)obj | 1);
  }

  auto stringify(IndentedWriter iw)
  {
    iw.formattedWrite("Num locals: %d\n", locals.length);
    iw.indent();
    foreach(i, obj; locals) {
      iw.formattedWrite("%d: %s\n", i, obj.Dyn_toString);
    }
    iw.unindent();

    return iw;
  }

}
