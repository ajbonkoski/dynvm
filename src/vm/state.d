module vm.state;

import std.format;

import common.common;
import datastruct.stack;
import hlasm.code_obj;
import hlasm.literal;
import hlasm.instructions;
import vm.dyn_obj.dyn_obj;
import vm.stack_frame;

struct State
{
  DynObject[string] globals;
  auto stack = new Stack!(StackFrame)();  // contains all non active frames
  //@property auto frame() { return stack.top(); }
  StackFrame frame;
  alias frame this; // allow the user to directly call methods on the to StackFrame

  DynObject _self;
  @property auto self() { return _self; }
  @property void self(DynObject s) { _self = s; }

  DynObject _ret;
  @property auto ret() { return _ret; }
  @property void ret(DynObject r) { _ret = r; }

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
    if(frame !is null)
      stack.push(frame);
    frame = sf;
  }

  StackFrame popFrame()
  {
    assert(frame !is null);
    auto ret = frame;
    if(stack.isEmpty)
      frame = null;
    return ret;
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

  DynObject selfGet(uint num)
  {
    assert(self !is null);
    Literal l = frame.getLiteral(num);
    assert(l.type == LType.String);
    return DynObject_get(l.s, self);
  }

  void selfSet(uint num, DynObject obj)
  {
    assert(self !is null);
    Literal l = frame.getLiteral(num);
    assert(l.type == LType.String);
    return DynObject_set(l.s, obj, self);
  }

  auto stringify(IndentedWriter iw)
  {
    iw.formattedWrite("self: %s\n", self.Dyn_toString);
    iw.formattedWrite("ret:  %s\n", ret.Dyn_toString);
    iw.formattedWrite("Num Globals: %d\n", globals.length);
    iw.indent();
    foreach(s; globals.keys.sort){
      iw.formattedWrite("%s: %s\n", s, globals[s].Dyn_toString);
    }
    iw.unindent();
    iw.formattedWrite("Num Frames:  %d\n", stack.length);
    iw.formattedWrite("Top frame:\n");

    iw.indent();
    frame.stringify(iw);
    iw.unindent();

    iw.formattedWrite("Object Stats:\n");
    iw.indent();
    iw.writeObjectStats();
    iw.unindent();

    return iw;
  }

}

// raw functions for the jit - arghh this sucks
DynObject State_getRegister(State *state, uint regnum)
{
  return (*state).frame.getRegister(regnum);
}

void State_setRegister(State *state, uint regnum, DynObject obj)
{
  return (*state).frame.setRegister(regnum, obj);
}
