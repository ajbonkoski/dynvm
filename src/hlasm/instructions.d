module hlasm.instructions;

import common.common;
import std.exception;
import std.conv;
import std.string;
import std.stdio;
import std.bitmanip;

// TEST(iABx)          register   boolean              |  if(bool(R[A]) != Bx) PC++, skip next instruction
// JMP(isBx)                     signed-int            |  PC += sBx

enum IOpcode
{
    LITERAL,
    LOADGLOBAL,
    STOREGLOBAL,
    MOVE,
    RET,
    NEWOBJECT,
    NEWARRAY,
    SETSELF,
    GET,
    SET,
    CALL,
    TEST,
    JMPTRUE,
    JMPFALSE,
    JMP,

    ADD,
    SUB,
    MUL,
    DIV,
    LEQ,
    LT,
    GEQ,
    GT,
    EQ,
    NEQ,
}

enum IFormat { iABC, iAB, iA, iABx, iAsBx, isBx };

// convert functions between int and sbx
// this is needed because sbx is a odd size (26-bit)
uint int_to_sBx26(int i ){
  int v = i>>25;
  enforce(v == 0xffffffff || v == 0x00000000);
  return cast(uint) (i&((1<<26)-1));
}

int sBx26_to_int(uint i){
  return ((cast(int)i)<<6)>>6;
}

uint int_to_sBx18(int i ){
  int v = i>>17;
  enforce(v == 0xffffffff || v == 0x00000000);
  return cast(uint) (i&((1<<18)-1));
}

int sBx18_to_int(uint i){
  return ((cast(int)i)<<14)>>14;
}


IFormat[IOpcode.max+1] instrTable =
[
    IOpcode.LITERAL:     IFormat.iABx,
    IOpcode.LOADGLOBAL:  IFormat.iABx,
    IOpcode.STOREGLOBAL: IFormat.iABx,
    IOpcode.MOVE:        IFormat.iAB,
    IOpcode.RET:         IFormat.iA,
    IOpcode.NEWOBJECT:   IFormat.iA,
    IOpcode.NEWARRAY:    IFormat.iABx,
    IOpcode.SETSELF:     IFormat.iA,
    IOpcode.GET:         IFormat.iABx,
    IOpcode.SET:         IFormat.iABx,
    IOpcode.CALL:        IFormat.iABC,
    IOpcode.TEST:        IFormat.iABx,
    IOpcode.JMPTRUE:     IFormat.iAsBx,
    IOpcode.JMPFALSE:    IFormat.iAsBx,
    IOpcode.JMP:         IFormat.isBx,
    IOpcode.ADD:         IFormat.iABC,
    IOpcode.SUB:         IFormat.iABC,
    IOpcode.MUL:         IFormat.iABC,
    IOpcode.DIV:         IFormat.iABC,
    IOpcode.LEQ:         IFormat.iABC,
    IOpcode.LT:          IFormat.iABC,
    IOpcode.GEQ:         IFormat.iABC,
    IOpcode.GT:          IFormat.iABC,
    IOpcode.EQ:          IFormat.iABC,
    IOpcode.NEQ:         IFormat.iABC,
];

private struct BitFieldStruct(Fields...) { mixin(bitfields!(Fields)); }
union IData
{
    uint raw;

    BitFieldStruct!(
        IOpcode, "opcode",  6,
        uint,    "rest",   26
    ) instr;

    BitFieldStruct!(
        IOpcode, "opcode",  6,
        uint,    "a",       8,
        uint,    "c",       9,
        uint,    "b",       9
             ) iABC, iAB, iA;

    BitFieldStruct!(
        IOpcode, "opcode",  6,
        uint,    "a",       8,
        uint,    "bx",     18
    ) iABx;

    BitFieldStruct!(
        IOpcode, "opcode",  6,
        uint,    "a",       8,
        uint,    "sbx",    18
    ) iAsBx;

    BitFieldStruct!(
        IOpcode, "opcode",  6,
        uint,    "sbx",    26
    ) isBx;
}

// this builds an opcode lookup table at compile-time
// essentially: a map from the string format to the enum IOpcode
enum instrLookup = {
    IOpcode[string] table;
    foreach(m; __traits(allMembers, IOpcode))
      table[m] = mixin("IOpcode."~m);
    return table;
}();

struct Instruction
{
    IData data;
    IFormat fmt;
    @property auto opcode() { return data.instr.opcode; }
    alias data this;  // allow user to access the IData union directly

    static Instruction create(IOpcode op, uint a_, uint b_=0, uint c_=0)
    {
      Instruction i;
      i.fmt = instrTable[op];
      final switch(i.fmt) {

        case IFormat.iABC: with(i.iABC) {
          opcode = op;
          a = a_; b = b_; c = c_;
        } break;

        case IFormat.iAB: with(i.iAB) {
          opcode = op;
          a = a_; b = b_; c = c_;
        } break;

        case IFormat.iA: with(i.iA) {
          opcode = op;
          a = a_; b = b_; c = c_;
        } break;

        case IFormat.iABx: with(i.iABx) {
          opcode = op;
          a = a_; bx = b_;
        } break;

        case IFormat.iAsBx: with(i.iAsBx) {
          opcode = op;
          a = a_; sbx = b_;
        } break;

        case IFormat.isBx: with(i.isBx) {
          opcode = op;
          sbx = a_;
        } break;
      }

      return i;
    }

    string toString()
    {
        final switch(fmt) {
          case IFormat.iABC: with(iABC) {
            return format("%s %d %d %d", opcode, a, b, c);
          }
          break;
          case IFormat.iAB: with(iAB) {
            return format("%s %d %d", opcode, a, b);
          }
          break;
          case IFormat.iA: with(iA) {
            return format("%s %d", opcode, a);
          }
          break;
          case IFormat.iABx: with(iABx) {
            return format("%s %d %d", opcode, a, bx);
          }
          case IFormat.iAsBx: with(iAsBx) {
            return format("%s %d %d", opcode, a, sbx.sBx18_to_int);
          }
          break;
          case IFormat.isBx: with(isBx) {
            return format("%s %d", opcode, sbx.sBx26_to_int);
          }
          break;
        }
    }

    void resolveRef(int offset)
    {
      if(fmt == IFormat.isBx)
        isBx.sbx = int_to_sBx26(offset);
      else if(fmt == IFormat.iAsBx)
        iAsBx.sbx = int_to_sBx18(offset);
      else
        assert(false, "Invalid format in Instruction.resolveRef");
    }
}

unittest
{
    Instruction i;
    i.raw = 0xffffffff;
    assert(i.opcode         == 0x3f);
    assert(i.instr.opcode   == 0x3f);
    assert(i.instr.rest     == 0x3ffffff);
    assert(i.iABC.opcode    == 0x3f);
    assert(i.iABC.a         == 0xff);
    assert(i.iABC.b         == 0x1ff);
    assert(i.iABC.c         == 0x1ff);
    assert(i.iABC.opcode    == 0x3f);
    assert(i.iABC.a         == 0xff);
    assert(i.iABC.b         == 0x1ff);
    assert(i.iABC.c         == 0x1ff);
    assert(i.iABx.opcode    == 0x3f);
    assert(i.iABx.a         == 0xff);
    assert(i.iABx.bx        == 0x3ffff);

    i = Instruction.create(IOpcode.LOADGLOBAL, 5, 10);
    assert(i.opcode         == 0x1);
    assert(i.instr.opcode   == 0x1);
    assert(i.instr.rest     == 0xa05);
    assert(i.iABx.opcode    == 1);
    assert(i.iABx.a         == 5);
    assert(i.iABx.bx        == 10);


    /** int <-> sBx conversion unittests **/

    assert(int_to_sBx26(33554431)   ==  0x01ffffff);
    assert(int_to_sBx26(1)          ==  0x00000001);
    assert(int_to_sBx26(0)          ==  0x00000000);
    assert(int_to_sBx26(-1)         ==  0x03ffffff);
    assert(int_to_sBx26(-33554432)  ==  0x02000000);

    assert(sBx26_to_int(0x01ffffff) ==  33554431);
    assert(sBx26_to_int(0x00000001) ==  1);
    assert(sBx26_to_int(0x00000000) ==  0);
    assert(sBx26_to_int(0x03ffffff) == -1);
    assert(sBx26_to_int(0x02000000) == -33554432);

    auto fail_throw(A,B)(A function(B) f, B i) {
      try { f(i); return false; } catch(Throwable t) { return true; }}

    assert(fail_throw(&int_to_sBx26,   33554432));
    assert(fail_throw(&int_to_sBx26,  123456789));
    assert(fail_throw(&int_to_sBx26,  -33554433));
    assert(fail_throw(&int_to_sBx26, -123456789));

}

