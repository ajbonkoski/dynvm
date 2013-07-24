import code_obj;
import dyn_obj;

class StackFrame
{
  CodeObject code;
  DynObject[] locals;
  uint pc;
}
