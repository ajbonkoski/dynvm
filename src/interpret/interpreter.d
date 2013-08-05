module interpret.interpreter;

import std.stdio;

import common.common;
import dasm.code_obj;
import dasm.instructions;
import interpret.dyn_obj;
import interpret.state;

private void runLoop(State state, CodeObject co, bool silent)
{
 EXECLOOP:
  while(true) {
    auto inst = state.fetchInstr();
    //if(!silent) writeln(inst.toString());

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
        state.ret = state.getRegister(inst.iA.a);
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
          args ~= state.getRegister(i);

        //writeln(args);
        auto obj = state.getRegister(inst.iABC.b).call(args);
        state.setRegister(inst.iABC.a, obj);
        break;

      case IOpcode.TEST:
        bool t  = state.getRegister(inst.iABx.a).truthiness;
        bool tl = state.getLiteralObj(inst.iABx.bx).truthiness;
        if(t != tl) state.pc += 1;
        break;

      case IOpcode.JMP:
        int offset = inst.isBx.sbx.sBx2int;
        state.pc += offset;
        break;

      case IOpcode.ADD:
        auto obj_b = state.getRegister(inst.iABC.b);
        auto obj_c = state.getRegister(inst.iABC.c);
        auto obj_a = obj_b.get("__op_add").call(obj_b, obj_c);
        state.setRegister(inst.iABC.a, obj_a);
        break;

      case IOpcode.SUB:
        auto obj_b = state.getRegister(inst.iABC.b);
        auto obj_c = state.getRegister(inst.iABC.c);
        auto obj_a = obj_b.get("__op_sub").call(obj_b, obj_c);
        state.setRegister(inst.iABC.a, obj_a);
        break;
    }
  }
}


void interpretCode(CodeObject co, bool silent)
{
  auto state = new State(co);

  try {
    state.runLoop(co, silent);
  } catch(Throwable t) {
    writeln("==== CRASH: ====");
    writeln(t.msg);
    writeln(t.info);
  }

  if(!silent) {
    writeln("==== Final State: ====");
    writeln(state.stringify(new IndentedWriter(4)).data);
  } else {
    writeln(state.ret.pretty());
  }

}
