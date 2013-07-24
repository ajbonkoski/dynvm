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

  // DynObject getLiteral(uint num)
  // {
  //   return frame.getLiteral(num);
  // }

  void setRegister(uint regnum, DynObject obj)
  {
    assert(regnum < locals.length);
    locals[regnum] = obj;
  }

}
