import std.bitmanip;
import std.conv;
import std.format;
import std.array;
import std.stdio;


enum IOpcode
{
    LOADLITERAL,
    LOADGLOBAL,
    STOREGLOBAL,
    MOVE
}

private struct IStruct(Fields...) { mixin(bitfields!(Fields)); }
enum IFormat { iABC, iABx, iAsBx };

IFormat[IOpcode.max+1] instrTable =
[
    IOpcode.LOADLITERAL: IFormat.iABx,
    IOpcode.LOADGLOBAL:  IFormat.iABx,
    IOpcode.STOREGLOBAL: IFormat.iABx,
    IOpcode.MOVE:        IFormat.iABC
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
    ) iABC;

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

    static Instruction create(string T)(IOpcode op, uint a_, uint b_, uint c_=0)
    {
        Instruction i;

        static if(T == "iABC") {
          i.fmt = IFormat.iABC;
          with(i.data.iABC) {
            opcode = op;
            a = a_; b = b_; c = c_;
          }
        } else static if(T == "iABx") {
          i.fmt = IFormat.iABx;
          with(i.data.iABx) {
            opcode = op;
            a = a_; bx = b_;
          }
        } else static if(T == "iAsBx") {
          i.fmt = IFormat.iAsBx;
          with(i.data.iAsBx) {
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
        case IFormat.iABx:  return create!("iABx")(op, a_, b_, c_);
        case IFormat.iAsBx: return create!("iAsBx")(op, a_, b_, c_);
      }
    }

    string toString()
    {
        auto s = appender!string();
        final switch(fmt) {
          case IFormat.iABC: with(data.iABC) {
            formattedWrite(s, "%s %d %d %d", to!string(opcode), a, b, c);
          }
          break;
          case IFormat.iABx: with(data.iABx) {
            formattedWrite(s, "%s %d %d", to!string(opcode), a, bx);
          }
          break;
          case IFormat.iAsBx: with(data.iAsBx) {
            formattedWrite(s, "%s %d %d", to!string(opcode), a, sbx);
          }
          break;
        }
        return s.data;
    }
}

unittest
{
    Instruction i;
    i.data.raw = 0xffffffff;
    assert(i.data.instr.opcode == 0x3f);
    assert(i.data.instr.rest   == 0x3ffffff);
    assert(i.data.iABC.opcode  == 0x3f);
    assert(i.data.iABC.a       == 0xff);
    assert(i.data.iABC.b       == 0x1ff);
    assert(i.data.iABC.c       == 0x1ff);
    assert(i.data.iABC.opcode  == 0x3f);
    assert(i.data.iABC.a       == 0xff);
    assert(i.data.iABC.b       == 0x1ff);
    assert(i.data.iABC.c       == 0x1ff);
    assert(i.data.iABx.opcode  == 0x3f);
    assert(i.data.iABx.a       == 0xff);
    assert(i.data.iABx.bx      == 0x3ffff);
    assert(i.data.iAsBx.opcode == 0x3f);
    assert(i.data.iAsBx.a      == 0xff);
    assert(i.data.iAsBx.sbx    == 0x3ffff);

    i = Instruction.create!("iABx")(IOpcode.LOADGLOBAL, 5, 10);
    assert(i.data.instr.opcode == 0x1);
    assert(i.data.instr.rest   == 0xa05);
    assert(i.data.iABx.opcode  == 1);
    assert(i.data.iABx.a       == 5);
    assert(i.data.iABx.bx      == 10);

    writeln(typeid(typeof(instrLookup)));
}
