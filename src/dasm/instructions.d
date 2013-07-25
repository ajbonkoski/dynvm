module dasm.instructions;

import std.bitmanip;
import std.conv;
import std.string;
import std.stdio;


enum IOpcode
{
    LOADLITERAL,
    LOADGLOBAL,
    STOREGLOBAL,
    MOVE,
    RET
}

private struct IStruct(Fields...) { mixin(bitfields!(Fields)); }
enum IFormat { iABC, iAB, iABx, iAsBx };

IFormat[IOpcode.max+1] instrTable =
[
    IOpcode.LOADLITERAL: IFormat.iABx,
    IOpcode.LOADGLOBAL:  IFormat.iABx,
    IOpcode.STOREGLOBAL: IFormat.iABx,
    IOpcode.MOVE:        IFormat.iAB,
    IOpcode.RET:         IFormat.iAB
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
    ) iABC, iAB;

    IStruct!(
        IOpcode, "opcode",  6,
        uint,    "a",       8,
        uint,    "bx",     18
    ) iABx;

    IStruct!(
        IOpcode, "opcode",  6,
        uint,    "a",       8,
        uint,    "sbx",    18
    ) iAsBx;
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

    static Instruction create(string T)(IOpcode op, uint a_, uint b_, uint c_=0)
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
        } else static if(T == "iABx") {
          i.fmt = IFormat.iABx;
          with(i.iABx) {
            opcode = op;
            a = a_; bx = b_;
          }
        } else static if(T == "iAsBx") {
          i.fmt = IFormat.iAsBx;
          with(i.iAsBx) {
            opcode = op;
            a = a_; sbx = b_;
          }
        } else {
          static assert(false, "Unrecognized instruction type in Instruction.create");
        }

        assert(i.fmt == instrTable[op]);

        return i;
    }

    static Instruction create(IOpcode op, uint a_, uint b_, uint c_=0)
    {
      IFormat fmt = instrTable[op];
      final switch(fmt) {
        case IFormat.iABC:  return create!("iABC")(op, a_, b_, c_);
        case IFormat.iAB:   return create!("iAB")(op, a_, b_, c_);
        case IFormat.iABx:  return create!("iABx")(op, a_, b_, c_);
        case IFormat.iAsBx: return create!("iAsBx")(op, a_, b_, c_);
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
          case IFormat.iABx: with(iABx) {
            return format("%s %d %d", opcode, a, bx);
          }
          break;
          case IFormat.iAsBx: with(iAsBx) {
            return format("%s %d %d", opcode, a, sbx);
          }
          break;
        }
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
    assert(i.iAsBx.opcode   == 0x3f);
    assert(i.iAsBx.a        == 0xff);
    assert(i.iAsBx.sbx      == 0x3ffff);

    i = Instruction.create!(iABx)(IOpcode.LOADGLOBAL, 5, 10);
    assert(i.opcode         == 0x1);
    assert(i.instr.opcode   == 0x1);
    assert(i.instr.rest     == 0xa05);
    assert(i.iABx.opcode    == 1);
    assert(i.iABx.a         == 5);
    assert(i.iABx.bx        == 10);
}

