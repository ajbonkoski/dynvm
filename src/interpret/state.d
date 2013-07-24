import dyn_obj;
import stack_frame;

class State
{
  DynObject[string] globals;
  StackFrame[] stack;  // contains all non active frames
  StackFrame active_frame;


}
