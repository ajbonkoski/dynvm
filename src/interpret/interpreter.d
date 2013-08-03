module interpret.interpreter;

import std.stdio;

import common.common;
import dasm.code_obj;
import dasm.instructions;
import interpret.dyn_obj;
import interpret.state;

private void runLoop(State state, CodeObject co)
{
 EXECLOOP:
  while(true) {
    auto inst = state.fetchInstr();
    writeln(inst.toString());

    final switch(inst.opcode)
    {
      case IOpcode.LITERAL:
        auto obj = state.getLiteralObj(inst.iABx.bx);
        state.setRegister(inst.iABx.a, obj);
        break;

      case IOpcode.LOADGLOBAL:
        auto obj = state.getGlobal(inst.iABx.bx);
        state.setRegister(inst.iABx.a, obj);
        break;

      case IOpcode.STOREGLOBAL:
        auto obj = state.getRegister(inst.iABx.a);
        state.setGlobal(inst.iABx.bx, obj);
        break;

      case IOpcode.MOVE:
        auto obj = state.getRegister(inst.iAB.b);
        state.setRegister(inst.iAB.a, obj);
        break;

      case IOpcode.RET:
        break EXECLOOP;  // for now RET just exits

      case IOpcode.NEWOBJECT:
        state.setRegister(inst.iA.a, DynObjectBuiltin.create!("object"));
        break;

      case IOpcode.SETSELF:
        state.self = state.getRegister(inst.iAB.a);
        break;

      case IOpcode.GET:
        auto obj = state.selfGet(inst.iABx.bx);
        state.setRegister(inst.iABx.a, obj);
        break;

      case IOpcode.SET:
        auto obj = state.getRegister(inst.iABx.a);
        state.selfSet(inst.iABx.bx, obj);
        break;

      case IOpcode.CALL:
        DynObject[] args;
        uint arg_num = inst.iABC.b+1;
        uint arg_end = inst.iABC.c;
        foreach(i; arg_num..arg_end+1)
          args ~= state.getRegister(arg_num);

        auto obj = state.getRegister(inst.iABC.b).call(args);
        state.setRegister(inst.iABC.a, obj);
        break;
    }
  }
}


void interpretCode(CodeObject co)
{
  auto state = new State(co);

  try {
    state.runLoop(co);
  } catch(Throwable t) {
    writeln("==== CRASH: ====");
    writeln(t.msg);
    writeln(t.info);
  }

  writeln("==== Final State: ====");
  writeln(state.stringify(new IndentedWriter(4)).data);
}
