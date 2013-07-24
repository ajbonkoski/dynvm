module interpret.interpreter;

import std.stdio;

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
        DynObject obj = state.getLiteral(inst.iABx.bx);
        state.setRegister(inst.iABx.a, null);
        break;
      case IOpcode.LOADGLOBAL:  break;
      case IOpcode.STOREGLOBAL: break;
      case IOpcode.MOVE:        break;
      case IOpcode.RET:
        break EXECLOOP;  // for now RET just exits
    }
  }

  writeln("Finished!");
  writeln("==== Final State: ====");
  state.print();
}
