module interpret.interpreter;

import std.stdio;

import dasm.code_obj;
import dasm.instructions;
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
      case IOpcode.LOADLITERAL: break;
      case IOpcode.LOADGLOBAL:  break;
      case IOpcode.STOREGLOBAL: break;
      case IOpcode.MOVE:        break;
      case IOpcode.RET:
        break EXECLOOP;  // for now RET just exits
    }
  }

  writeln("Finished!");
}
