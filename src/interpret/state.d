module interpret.state;

import datastruct.stack;
import dasm.code_obj;
import interpret.dyn_obj;
import interpret.stack_frame;

class State
{
  DynObject[string] globals;
  Stack!(StackFrame) stack;  // contains all non active frames
  @property auto frame() { return stack.top(); }

  this(CodeObject co)
  {
    this(new StackFrame(co));
  }

  this(StackFrame sf)
  {
    pushFrame(sf);
  }

  void pushFrame(StackFrame sf)
  {
    stack.push(sf);
  }

  StackFrame popFrame()
  {
    assert(!stack.isEmpty());
    return stack.pop();
  }

}
