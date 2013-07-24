module interpret.state;

import datastruct.stack;
import dasm.code_obj;
import dasm.instructions;
import interpret.dyn_obj;
import interpret.stack_frame;

// helper for forwarding StackFrame methods
// used with a mixin in State's definition
// private string FrameMethod(string name, string args...)
// {
//   return
// }

class State
{
  DynObject[string] globals;
  auto stack = new Stack!(StackFrame)();  // contains all non active frames
  @property auto frame() { return stack.top(); }
  alias frame this; // allow the user to directly call methods on the to StackFrame

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

  void print()
  {
    import std.stdio;
    writef("Num Globals: %d\n", globals.length);
    writef("Num Frames:  %d\n", stack.length);
    writef("Top frame:\n");
    frame.print();
  }

}
