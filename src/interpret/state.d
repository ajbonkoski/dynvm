module interpret.state;

import std.format;

import common.common;
import datastruct.stack;
import dasm.code_obj;
import dasm.literal;
import dasm.instructions;
import interpret.dyn_obj;
import interpret.stack_frame;

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

  DynObject getGlobal(uint num)
  {
    Literal l = frame.getLiteral(num);
    assert(l.type == LType.String);
    return globals[l.s];
  }

  void setGlobal(uint num, DynObject obj)
  {
    Literal l = frame.getLiteral(num);
    assert(l.type == LType.String);
    globals[l.s] = obj;
  }

  auto stringify(IndentedWriter iw)
  {
    iw.formattedWrite("Num Globals: %d\n", globals.length);
    iw.indent();
    foreach(s; globals.keys.sort){
      iw.formattedWrite("%s: %s\n", s, globals[s]);
    }
    iw.unindent;
    iw.formattedWrite("Num Frames:  %d\n", stack.length);
    iw.formattedWrite("Top frame:\n");

    iw.indent();
    frame.stringify(iw);
    iw.unindent();

    return iw;
  }

}
