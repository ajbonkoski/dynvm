module dasm.instructions;

import std.exception;
import std.bitmanip;
import std.conv;
import std.string;
import std.stdio;

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
    SETSELF,
    GET,
    SET,
    CALL,
    TEST,
    JMP,
    ADD,
    SUB,
}

private struct IStruct(Fields...) { mixin(bitfields!(Fields)); }
enum IFormat { iABC, iAB, iA, iABx, isBx };

// convert functions between int and sbx
// this is needed because sbx is a odd size (26-bit)
uint int2sBx(int i ){
  int v = i>>25;
  enforce(v == 0xffffffff || v == 0x00000000);
  return cast(uint) (i&((1<<26)-1));
}

int sBx2int(uint i){
  return ((cast(int)i)<<6)>>6;
}


IFormat[IOpcode.max+1] instrTable =
[
    IOpcode.LITERAL:     IFormat.iABx,
    IOpcode.LOADGLOBAL:  IFormat.iABx,
    IOpcode.STOREGLOBAL: IFormat.iABx,
    IOpcode.MOVE:        IFormat.iAB,
    IOpcode.RET:         IFormat.iA,
    IOpcode.NEWOBJECT:   IFormat.iA,
    IOpcode.SETSELF:     IFormat.iA,
    IOpcode.GET:         IFormat.iABx,
    IOpcode.SET:         IFormat.iABx,
    IOpcode.CALL:        IFormat.iABC,
    IOpcode.TEST:        IFormat.iABx,
    IOpcode.JMP:         IFormat.isBx,
    IOpcode.ADD:         IFormat.iABC,
    IOpcode.SUB:         IFormat.iABC,
];

union IData
{
    uint raw;

    IStruct!(
        IOpcode, "opcode",  6,
        uint,    "rest",   26
    ) instr;

    IStruct!(
        IOpcode, "opcode",  6,
        uint,    "a",       8,
        uint,    "c",       9,
        uint,    "b",       9
             ) iABC, iAB, iA;

    IStruct!(
        IOpcode, "opcode",  6,
        uint,    "a",       8,
        uint,    "bx",     18
    ) iABx;

    IStruct!(
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

    static Instruction create(string T)(IOpcode op, uint a_, uint b_=0, uint c_=0)
    {
        Instruction i;

        static if(T == "iABC") {
          i.fmt = IFormat.iABC;
          with(i.iABC) {
            opcode = op;
            a = a_; b = b_; c = c_;
          }
        } else static if(T == "iAB") {
          i.fmt = IFormat.iAB;
          with(i.iAB) {
            opcode = op;
            a = a_; b = b_; c = c_;
          }
        } else static if(T == "iA") {
          i.fmt = IFormat.iA;
          with(i.iA) {
            opcode = op;
            a = a_; b = b_; c = c_;
          }
        } else static if(T == "iABx") {
          i.fmt = IFormat.iABx;
          with(i.iABx) {
            opcode = op;
            a = a_; bx = b_;
          }
        } else static if(T == "isBx") {
          i.fmt = IFormat.isBx;
          with(i.isBx) {
            opcode = op;
            sbx = a_;
          }
        } else {
          static assert(false, "Unrecognized instruction type in Instruction.create");
        }

        assert(i.fmt == instrTable[op]);

        return i;
    }

    static Instruction create(IOpcode op, uint a_, uint b_=0, uint c_=0)
    {
      IFormat fmt = instrTable[op];
      final switch(fmt) {
        case IFormat.iABC:  return create!("iABC")(op, a_, b_, c_);
        case IFormat.iAB:   return create!("iAB")(op, a_, b_, c_);
        case IFormat.iA:   return create!("iA")(op, a_, b_, c_);
        case IFormat.iABx:  return create!("iABx")(op, a_, b_, c_);
        case IFormat.isBx: return create!("isBx")(op, a_, b_, c_);
      }
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
          break;
          case IFormat.isBx: with(isBx) {
            return format("%s %d", opcode, sbx.sBx2int);
          }
          break;
        }
    }

    void resolveRef(uint sBx)
    {
        assert(fmt == IFormat.isBx);
        isBx.sbx = sBx;
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

    i = Instruction.create!("iABx")(IOpcode.LOADGLOBAL, 5, 10);
    assert(i.opcode         == 0x1);
    assert(i.instr.opcode   == 0x1);
    assert(i.instr.rest     == 0xa05);
    assert(i.iABx.opcode    == 1);
    assert(i.iABx.a         == 5);
    assert(i.iABx.bx        == 10);


    /** int <-> sBx conversion unittests **/

    assert(int2sBx(33554431)   ==  0x01ffffff);
    assert(int2sBx(1)          ==  0x00000001);
    assert(int2sBx(0)          ==  0x00000000);
    assert(int2sBx(-1)         ==  0x03ffffff);
    assert(int2sBx(-33554432)  ==  0x02000000);

    assert(sBx2int(0x01ffffff) ==  33554431);
    assert(sBx2int(0x00000001) ==  1);
    assert(sBx2int(0x00000000) ==  0);
    assert(sBx2int(0x03ffffff) == -1);
    assert(sBx2int(0x02000000) == -33554432);

    auto fail_throw(A,B)(A function(B) f, B i) {
      try { f(i); return false; } catch(Throwable t) { return true; }}

    assert(fail_throw(&int2sBx,   33554432));
    assert(fail_throw(&int2sBx,  123456789));
    assert(fail_throw(&int2sBx,  -33554433));
    assert(fail_throw(&int2sBx, -123456789));

}

