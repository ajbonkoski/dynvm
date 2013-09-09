module vm.interpreter;

import std.stdio;

import common.common;
import hlasm.code_obj;
import hlasm.instructions;
import vm.dyn_obj.dyn_obj;
import vm.state;
import vm.gc.types;

enum LOUD = false;

bool isUnboxedInt(DynObject obj) { return (cast(long)obj&1) == 0; }

DynObject integerBinOp(string name)(DynObject obj_b, DynObject obj_c) {
    long b = cast(long)obj_b;
    long c = cast(long)obj_c;
    static if(name == "__op_sub") {
      return cast(DynObject) (b - c);
    } else static if(name == "__op_add") {
        return cast(DynObject) (b + c);
    } else static if(name == "__op_mul") {
      return cast(DynObject) (((b>>1) * (c>>1))<<1);
    } else static if(name == "__op_div") {
      return cast(DynObject) (((b>>1) / (c>>1))<<1);
    } else static if(name == "__op_leq") {
      return cast(DynObject) (((b>>1)<=(c>>1)?1:0)<<1);
    } else static if(name == "__op_lt") {
      return cast(DynObject) (((b>>1)<(c>>1)?1:0)<<1);
    } else static if(name == "__op_geq") {
      return cast(DynObject) (((b>>1)>=(c>>1)?1:0)<<1);
    } else static if(name == "__op_gt") {
      return cast(DynObject) (((b>>1)>(c>>1)?1:0)<<1);
    } else static if(name == "__op_eq") {
      return cast(DynObject) (((b>>1)==(c>>1)?1:0)<<1);
    } else static if(name == "__op_neq") {
      return cast(DynObject) (((b>>1)!=(c>>1)?1:0)<<1);
    } else {
      static assert(0, "unimpl");
    }
}

DynObject objectBinOp(string name)(DynObject obj_b, DynObject obj_c) {
  auto b = cast(DynObject) (cast(long)obj_b & ~1);
  auto c = cast(DynObject) (cast(long)obj_c & ~1);
  auto obj = Dyn_binop!name(b, c);
  return cast(DynObject) (cast(long)obj | 1);
}

void interpretCode(ref State state, bool silent)
{
  Instruction inst;

  void binOp(string name)() {
    auto obj_b = state.getRegister(inst.iABC.b);
    auto obj_c = state.getRegister(inst.iABC.c);
    DynObject obj_a;

    if(obj_b.isUnboxedInt && obj_c.isUnboxedInt) {
      obj_a = integerBinOp!name(obj_b, obj_c);
    }

    else {
      assert(!obj_b.isUnboxedInt && !obj_c.isUnboxedInt);
      obj_a = objectBinOp!name(obj_b, obj_c);
    }

    state.setRegister(inst.iABC.a, obj_a);
  }


 EXECLOOP:
  while(true) {
    inst = state.fetchInstr();
    if(LOUD) writeln(inst.toString());

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
        state.setRegister(inst.iA.a, DynObjectBuiltin.create!"object");
        break;

      case IOpcode.NEWARRAY:
        ulong initalloc = state.requireLiteralInt(inst.iABx.bx);
        auto obj = DynArray_create(initalloc);
        obj = cast(DynObject) (cast(long)obj | 1);
        state.setRegister(inst.iABx.a, obj);
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
        auto f_obj = state.getRegister(inst.iABC.b);
        uint arg_start = inst.iABC.b+1;
        uint arg_end = inst.iABC.c;
        uint num_arg = (arg_end+1) - arg_start;

        DynObject ret_obj = null;
        switch(num_arg) {

          case 1:
            assert(f_obj.gcheader.rawtypedata == GCTypes.FuncArg1);
            auto unary_func = cast(DynNativeUnary) f_obj;
            auto func = unary_func.func;
            ret_obj = func(state.getRegister(arg_start));
            break;

          case 2:
            assert(f_obj.gcheader.rawtypedata == GCTypes.FuncArg2);
            auto bin_func = cast(DynNativeBin) f_obj;
            auto func = bin_func.func;
            ret_obj = func(state.getRegister(arg_start),
                           state.getRegister(arg_start+1));
            break;

          default:
            assert(0, "VM only supports 1 and 2 arg calls currently");
        }

        state.setRegister(inst.iABC.a, ret_obj);
        break;

      case IOpcode.TEST:
        bool t  = state.getRegister(inst.iABx.a).Dyn_truthiness;
        bool tl = state.getLiteral(inst.iABx.bx).truthiness;
        if(t != tl) state.pc += 1;
        break;

      case IOpcode.JMPTRUE:
        if(state.getRegister(inst.iAsBx.a).Dyn_truthiness)
          state.pc += inst.iAsBx.sbx.sBx18_to_int;
        break;

      case IOpcode.JMPFALSE:
        if(!state.getRegister(inst.iAsBx.a).Dyn_truthiness)
          state.pc += inst.iAsBx.sbx.sBx18_to_int;
        break;

      case IOpcode.JMP:
        int offset = inst.isBx.sbx.sBx26_to_int;
        state.pc += offset;
        break;

      // binary operations
      case IOpcode.ADD:   binOp!"__op_add";   break;
      case IOpcode.SUB:   binOp!"__op_sub";   break;
      case IOpcode.MUL:   binOp!"__op_mul";   break;
      case IOpcode.DIV:   binOp!"__op_div";   break;
      case IOpcode.LEQ:   binOp!"__op_leq";   break;
      case IOpcode.LT:    binOp!"__op_lt";    break;
      case IOpcode.GEQ:   binOp!"__op_geq";   break;
      case IOpcode.GT:    binOp!"__op_gt";    break;
      case IOpcode.EQ:    binOp!"__op_eq";    break;
      case IOpcode.NEQ:   binOp!"__op_neq";   break;

    }
  }
}
