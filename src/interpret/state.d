module interpret.state;

import interpret.dyn_obj;
import interpret.stack_frame;

class State
{
  DynObject[string] globals;
  StackFrame[] stack;  // contains all non active frames
  StackFrame active_frame;


}
