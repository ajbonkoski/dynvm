module interpret.stack_frame;

import dasm.code_obj;
import interpret.dyn_obj;

class StackFrame
{
  CodeObject code;
  DynObject[] locals;
  uint pc;
}
