module interpret.interpreter;

import std.stdio;

import common.common;
import dasm.code_obj;
import dasm.instructions;
import interpret.dyn_obj;
import interpret.state;

void interpretCode(CodeObject co)
{
  auto state = new State(co);

 EXECLOOP:
  while(true) {
    auto inst = state.fetchInstr();
    writeln(inst.toString());

    final switch(inst.opcode)
    {
      case IOpcode.LOADLITERAL:
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
    }
  }

  writeln("Finished!");
  writeln("==== Final State: ====");
  writeln(state.stringify(new IndentedWriter(4)).data);
}
