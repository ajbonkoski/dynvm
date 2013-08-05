module interpret.stack_frame;

import std.format;

import common.common;
import dasm.code_obj;
import dasm.literal;
import dasm.instructions;
import interpret.dyn_obj;

class StackFrame
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
    DynObject old = locals[regnum];
    if(old !is null) old.decref();
    if(obj !is null) obj.incref();
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

  DynObject getLiteralObj(uint num)
  {
    return DynObjectBuiltin.create(code.getLiteral(num));
  }

  auto stringify(IndentedWriter iw)
  {
    iw.formattedWrite("Num locals: %d\n", locals.length);
    iw.indent();
    foreach(i, obj; locals) {
      iw.formattedWrite("%d: %s\n", i, obj);
    }
    iw.unindent();

    return iw;
  }

}
