import std.c.stdlib;
import std.stdio;
import std.array;
import std.conv;
import std.exception;

import instructions;
import code_obj;

// gloabl line tracking
uint lineno = 0;

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
    writef("Invalid opcode '%s' at line %d\n", l.opcode, lineno);
    exit(-1);
  }

  return *op;
}

uint requireRegister(const char[] s)
{
  try {

    char r = s[0];
    enforce(r == 'r');
    auto num = s[1..$];
    return to!uint(num);

  } catch(Exception ex) {

    writeln("Failed to parse a register on line ", lineno);
    exit(-1);
    assert(0);

  }
}

uint requireLiteral(const char[] s, CodeObject co)
{
  try {
    // string literal?
    if(s.length >= 2 && s[0] == '"' && s[$-1] == '"') {
      return co.addLiteral(s[1..$-1].idup);
    }

    // interger literal?
    else {
      enforce(s.length >= 2 && s[0] == '#');
      return co.addLiteral(to!int(s[1..$]));
    }
  } catch(Exception ex) {

    writeln("Failed to parse literal on line ", lineno);
    exit(-1);
    assert(0);

  }
}


CodeObject assembleFile(File f)
{
    CodeObject co = new CodeObject();

    foreach(l; f.byLine()) {
      lineno++;
      if(l.length == 0)
        continue;

      Line line = new Line(l);
      IOpcode op = line.getIOpcode();
      final switch(instrTable[op]) {
        case IFormat.iABC: {
          uint a = requireRegister(line.fieldA);
          uint b = requireRegister(line.fieldB);
          uint c = requireRegister(line.fieldC);
          co.addInstr(Instruction.create(op, a, b, c));
          break;
        }
        case IFormat.iABx: {
          uint a = requireRegister(line.fieldA);
          uint bx = requireLiteral(line.fieldB, co);
          co.addInstr(Instruction.create(op, a, bx));
          break;
        }
        case IFormat.iAsBx:
          assert(0, "unimplemented");
          break;
      }

    }

    return co;
}
