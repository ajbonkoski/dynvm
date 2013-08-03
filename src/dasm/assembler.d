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

// respects spaces if inside quotes
char[][] customSplit(char[] s)
{
  char[][] ret;
  int n = 0;

  enum State { IGNORE_WHITE, FIND_WHITE, INSIDE_QUOTE };
  State state = State.IGNORE_WHITE;
  ulong start = 0;

  foreach(i; 0..s.length) {
    char c = s[i];
    final switch(state) {

      case State.IGNORE_WHITE:
        if(!c.iswhite) {
          start = i;
          state = (c == '"') ? State.INSIDE_QUOTE :
                               State.FIND_WHITE;
        }
        break;

      case State.FIND_WHITE:
        if(c.iswhite) {
          ret ~= s[start..i];
          state = State.IGNORE_WHITE;
        }
        else if(c == '"') {
          state = State.FIND_WHITE;
        }
        break;

      case State.INSIDE_QUOTE:
        if(c == '"') {
          ret ~= s[start..i+1];
          state = State.IGNORE_WHITE;
        }
        break;

    }
  }

  // We shouldn;t be in the INSIDE_QUOTE state here
  // this would mean there are mismatching quotes
  if(state == State.INSIDE_QUOTE)
    throw new DynAssemblerException("Quote mismatch in customSplit");

  // if we run out of chars and we were in FIND_WHITE mode,
  // its a valid field, so add it!
  if(state == State.FIND_WHITE)
    ret ~= s[start..$];

  return ret;
}

class Line
{
  char[][] fields;
  char[] label;
  bool is_instruction = true;

  this(char[] line)
  {
    fields = line.customSplit();
    if(fields[0][0..2] == ";;") {
      is_instruction = false;
      return;
    }

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

uint requireSBX(const char[] s)
{
  try {
    enforce(s.length >= 2 && s[0] == '#');
    return int2sBx(to!int(s[1..$]));
  } catch(Exception ex) {
    string msg = format("Failed to parse signed from %s on line %d", s, lineno);
    throw new DynAssemblerException(msg);
  }
}

CodeObject assembleFile(File f, bool silent)
{
    CodeObject co = new CodeObject();

    lineno = 0;
    foreach(l; f.byLine()) {
      lineno++;
      if(!silent) writeln(l);
      if(l.length == 0)
        continue;

      Line line = new Line(l);
      if(!line.is_instruction)
        continue;

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
        case IFormat.iA: {
          uint a = co.parseRegister(line.fieldA);
          co.addInstr(Instruction.create(op, a));
          break;
        }
        case IFormat.iABx: {
          uint a = co.parseRegister(line.fieldA);
          uint bx = co.parseLiteral(line.fieldB);
          co.addInstr(Instruction.create(op, a, bx));
          break;
        }
        case IFormat.isBx:
          uint sbx = requireSBX(line.fieldA);
          co.addInstr(Instruction.create(op, sbx));
          break;
      }

    }

    return co;
}
