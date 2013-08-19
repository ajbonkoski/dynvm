module hlasm.assembler;

import std.c.stdlib;
import std.stdio;
import std.array;
import std.conv;
import std.exception;
import std.string;

import hlasm.instructions;
import hlasm.code_obj;
import hlasm.literal;

// global line tracking
int lineno = 0;
int[string] labelMap;

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
      if(label[$-1] == ':')  // trim off colon if needed
        label = label[0..$-1];
      fields = fields[1..$];
    } else {
      label = "".dup;
    }

    if(fields.length <= 1 || opcode == "")
      is_instruction = false;
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

uint requireSBX(const char[] s, int addr, bool *success)
{
  *success = true;

  try {
    // is it a hand-computed offset?
    if(s.length >= 2 && s[0] == '#') {
      return int2sBx(to!int(s[1..$]));
    }

    // try it as a label
    else {

      int *label_lineno = (s in labelMap);
      if(label_lineno) {
        return int2sBx(*label_lineno - (addr+1));
      }

      // admit failure (and sort it out latter)
      else {
        *success = false;
        return 0;
      }

    }

  } catch(Exception ex) {
    string msg = format("Failed to parse signed from %s on line %d", s, lineno);
    throw new DynAssemblerException(msg);
  }
}

void updateLabelMap(string label, int addr)
{
  if(label == "") return;

  // verify that all is well
  int *loc = (label in labelMap);
  if(loc) {
    string msg = format("Duplicate labels detected. First seen at lineno %d,"
                        "Seen again on lineno %d", *loc, lineno);
    throw new DynAssemblerException(msg);
  }

  // all good, add the label
  labelMap[label] = addr;
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
      updateLabelMap(line.label.idup, co.currentAddress);
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
          bool success;
          uint sbx = requireSBX(line.fieldA, co.currentAddress, &success);
          // if we didn't succeed, we'll have to come back later to fix it up...
          if(!success) co.addUnresovedRef(line.fieldA.idup);
          co.addInstr(Instruction.create(op, sbx));
          break;
      }

    }

    co.resolveRefs(labelMap);
    if(!co.complete) {
      string msg = format("Failed to link the final object. Some references are unresolved.");
      throw new DynAssemblerException(msg);
    }

    return co;
}
