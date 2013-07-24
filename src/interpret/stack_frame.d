module interpret.stack_frame;

import dasm.code_obj;
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
    locals[regnum] = obj;
  }

  DynObject getLiteral(uint num)
  {
    return DynObjectBuiltin.create(code.getLiteral(num));
  }

  void print()
  {
    import std.stdio;
    writef("Num locals: %d\n", locals.length);
    foreach(i, obj; locals) {
      writef("%d: %s\n", i, obj);
    }
  }

}
