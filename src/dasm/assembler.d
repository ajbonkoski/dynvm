module dasm.assembler;

import std.c.stdlib;
import std.stdio;
import std.array;
import std.conv;
import std.exception;
import std.string;

import dasm.instructions;
import dasm.code_obj;
import dasm.literal;

// global line tracking
uint lineno = 0;

class DynAssemblerException : Exception
{
    this(string s) { super(s); }
}

auto iswhite(char c)
{
    return c == ' ' || c == '\t';
}

class Line
{
  public char[][] fields;
  public char[] label;

  this(char[] line)
  {
    fields = split(line);
    if(!iswhite(line[0])) {
      label = fields[0];
      fields = fields[1..$];
    } else {
      label = "".dup;
    }
  }

  @property char[] opcode() { return fields[0]; }
  @property char[] fieldA() { return fields[1]; }
  @property char[] fieldB() { return fields[2]; }
  @property char[] fieldC() { return fields.length >= 4 ? fields[3] : "0".dup; }
}

IOpcode getIOpcode(Line l)
{
  IOpcode *op = (l.opcode in instrLookup);
  if(op == null) {
    string msg = format("Invalid opcode '%s' at line %d\n", l.opcode, lineno);
    throw new DynAssemblerException(msg);
  }

  return *op;
}

uint parseRegister(CodeObject co, const char[] s)
{
  try {

    char r = s[0];
    enforce(r == 'r');
    auto num = s[1..$];
    return co.addRegister(to!uint(num));

  } catch(Exception ex) {
    string msg = format("Failed to parse register from %s on line %d", s, lineno);
    throw new DynAssemblerException(msg);
  }

}

uint parseLiteral(CodeObject co, const char[] s)
{
  try {
    // string literal?
    if(s.length >= 2 && s[0] == '"' && s[$-1] == '"') {
      return co.addLiteral(Literal(s[1..$-1].idup));
    }

    // interger literal?
    else {
      enforce(s.length >= 2 && s[0] == '#');
      return co.addLiteral(Literal(to!int(s[1..$])));
    }
  } catch(Exception ex) {
    string msg = format("Failed to parse literal from %s on line %d", s, lineno);
    throw new DynAssemblerException(msg);
  }
}

CodeObject assembleFile(File f)
{
    CodeObject co = new CodeObject();

    lineno = 0;
    foreach(l; f.byLine()) {
      lineno++;
      if(l.length == 0)
        continue;

      Line line = new Line(l);
      IOpcode op = line.getIOpcode();
      final switch(instrTable[op]) {
        case IFormat.iABC: {
          uint a = co.parseRegister(line.fieldA);
          uint b = co.parseRegister(line.fieldB);
          uint c = co.parseRegister(line.fieldC);
          co.addInstr(Instruction.create(op, a, b, c));
          break;
        }
        case IFormat.iAB: {
          uint a = co.parseRegister(line.fieldA);
          uint b = co.parseRegister(line.fieldB);
          co.addInstr(Instruction.create(op, a, b));
          break;
        }
        case IFormat.iABx: {
          uint a = co.parseRegister(line.fieldA);
          uint bx = co.parseLiteral(line.fieldB);
          co.addInstr(Instruction.create(op, a, bx));
          break;
        }
        case IFormat.iAsBx:
          string msg = format("IFormat.iAsBx is unimplemented at line %d", lineno);
          throw new DynAssemblerException(msg);
      }

    }

    return co;
}
