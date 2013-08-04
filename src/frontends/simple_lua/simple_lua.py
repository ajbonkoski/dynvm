varMap = {}
nextReg = 0
lastAssignedReg = -1

def variableToRegister(variable):
    global varMap, nextReg
    if variable not in varMap:
        varMap[variable] = nextReg
        nextReg += 1
    return str(varMap[variable])


### Temp Registers are allocated on demand and pooled/reused
### However, once a temp, always a temp
TEMP_REG_PREFIX = '__temp_reg'
nextTemp = 0
tempRegPool = []

def allocTempReg():
    global tempRegPool, nextTemp, TEMP_REG_PREFIX
    if len(tempRegPool) > 0:
        return tempRegPool.pop()

    ## pool is empty... Allocate
    name = TEMP_REG_PREFIX + str(nextTemp)
    nextTemp += 1
    return variableToRegister(name)

def freeTempReg(reg):
    tempRegPool.append(reg)

nextLabel = 0
def allocLabel(prefix):
    global nextLabel
    id = nextLabel
    nextLabel += 1
    return "{}_{}".format(prefix, id)

binOpNameMap = {
    '+':  '__op_add',
    '-':  '__op_sub',
    '*':  '__op_mul',
    '/':  '__op_div',
    '<=': '__op_leq',
    '<':  '__op_lt',
    '>=': '__op_geq',
    '>':  '__op_gt',
    '==': '__op_eq',
    '!=': '__op_neq',
}

######################### INSTRUCTIONS ##############################
C1_SP  = ' '*20
C2_OP  = '{:15}'
C3_REG = ' r{:15}'
C3_SBX = ' {}'
C4_BX  = ' {}'
C4_REG = ' r{:15}'
C5_REG = ' r{:15}'
END    = '\n'

def genInstr_iABx(opcode, reg, literal):
    return (C1_SP + C2_OP + C3_REG + C4_BX + END).format(
                    opcode,   reg,  literal)

def genInstr_iA(opcode, rega):
    return (C1_SP + C2_OP + C3_REG + END).format(
                    opcode,   rega)

def genInstr_iAB(opcode, rega, regb):
    return (C1_SP + C2_OP + C3_REG + C4_REG + END).format(
                    opcode,   rega,    regb)

def genInstr_iABC(opcode, rega, regb, regc):
    return (C1_SP + C2_OP + C3_REG + C4_REG + C5_REG + END).format(
                    opcode,   rega,    regb,    regc)

def genInstr_isBx(opcode, sBx):
    return (C1_SP + C2_OP + C3_SBX + END).format(
                   opcode,   sBx)

def genInstr_iMb(opcode, self_reg, dest_reg, literal):
    return genInstr("SETSELF",  self_reg) + \
           genInstr(opcode[:3], dest_reg, literal)

def genInstr_iJc(opcode, rega, tf, label):
    return genInstr("TEST", rega, '#{}'.format(1 if tf else 0)) + \
           genInstr("JMP",  label)

LOAD_YES = 1
LOAD_NO = 2

instructions = {
    'LITERAL':      (genInstr_iABx, LOAD_YES),
    'LOADGLOBAL':   (genInstr_iABx, LOAD_YES),
    'STOREGLOBAL':  (genInstr_iABx, LOAD_NO),
    'MOVE':         (genInstr_iAB,  LOAD_YES),
    'RET':          (genInstr_iA,   LOAD_NO),
    'NEWOBJECT':    (genInstr_iA,   LOAD_YES),
    'SETSELF':      (genInstr_iA,   LOAD_NO),
    'GET':          (genInstr_iABx, LOAD_YES),
    'SET':          (genInstr_iABx, LOAD_NO),
    'GETMEMBER':    (genInstr_iMb,  LOAD_NO),  ## aggregate type
    'SETMEMBER':    (genInstr_iMb,  LOAD_NO),  ## aggregate type
    'CALL':         (genInstr_iABC, LOAD_YES),
    'TEST':         (genInstr_iABx, LOAD_NO),
    'JMP':          (genInstr_isBx, LOAD_NO),
    'JMPCOND':      (genInstr_iJc,  LOAD_NO),  ## aggregate type
}

class UnknownInstruction(Exception): pass
def genInstr(*args):
    assert len(args) >= 2
    opcode = args[0]
    rega = args[1]

    if opcode not in instructions:
        raise UnknownInstruction(opcode)
    f, ld = instructions[opcode]

    instr = f(opcode, *args[1:])
    if ld == LOAD_YES:
        global lastAssignedReg; lastAssignedReg = rega
    return instr

def genLabel(label):
    return "{}:\n".format(label)

#####################################################################




def genBinCall(val_a, ops_list):

    call_reg = allocTempReg()
    dest_reg = call_reg  # replace the function ptr with the ret val
    arg_reg1 = allocTempReg()
    arg_reg2 = allocTempReg()

    for op_name, val_b in ops_list:
        instr = ''
        instr += val_a.storeTo(arg_reg1)
        m = Member(Local.fromReg(arg_reg1), binOpNameMap[op_name])
        instr += m.storeTo(call_reg)
        instr += val_b.storeTo(arg_reg2)
        instr += genInstr("CALL", dest_reg, call_reg, arg_reg2)
        val_a = Local.fromReg(dest_reg, instr)

    return [val_a]


def genIfStmt(if_data, elseif_data, else_data):

    label_end = allocLabel("IF_END")
    instr = ''

    for cond, body in [if_data]+elseif_data:
        label = allocLabel("IF")
        instr += cond.instr
        instr += genInstr("JMPCOND", cond.outreg, False, label);
        instr += body.instr
        instr += genInstr("JMP", label_end)
        instr += genLabel(label)

    # else?
    if else_data:
        instr += else_data.instr;

    instr += genLabel(label_end)
    return [CodeSequence(instr, None)]

def genWhileStmt(cond, body):

    label_start = allocLabel("WHILE_START")
    label_end = allocLabel("WHILE_END")
    instr = ''

    instr += genLabel(label_start)
    instr += cond.instr
    instr += genInstr("JMPCOND", cond.outreg, False, label_end);
    instr += body.instr
    instr += genInstr("JMP", label_start);

    instr += genLabel(label_end)
    return [CodeSequence(instr, None)]

def genFinal(code_seq):
    return code_seq.instr + genInstr("RET", lastAssignedReg)



class CodeSequence:
    def __init__(self, instr, outreg):
        self.instr = instr
        self.outreg = outreg

    def toString(self, name):
        s = "{} .text (outreg={})\n".format(name, self.outreg)
        return s + self.instr + "\n"

    @staticmethod
    def join(arg):
        return [CodeSequence(''.join(a.instr for a in arg), None)]

def stringify(s): return "\"{}\"".format(s)

def assert_init(f):
    def wrapper(*args):
        self = args[0]
        assert(self.init)
        return f(*args)
    return wrapper


class Value:
    def __init__(self):  self.instr = ''

    def resolveSrcReg(self, src):
        """This method returns a regnum of where the source
           can be found. It attempts to avoid allocating excess
           temporary registers."""
        if not src.hasRegister():
            regnum = allocTempReg()
            self.instr += src.storeTo(regnum)
        else:
            regnum = src.getRegister()
            self.instr += src.instr
        return regnum

    def ensureGen(self):
        if self.hasRegister():
            return [CodeSequence(self.instr, self.getRegister())]
        else:
            regnum = allocTempReg()
            instr = self.storeTo(regnum)
            return [CodeSequence(instr, regnum)]

class LValue(Value):
    def __init__(self): Value.__init__(self)

    ## defaults... in most cases
    def hasRegister(self): return False
    def getRegister(self): assert(False)


class RValue(Value):
    def __init__(self): Value.__init__(self)

    ## These should never be overridden for RValues
    def hasRegister(self): return False
    def getRegister(self): assert(False)
    def genAssign(self, source): assert(False)


class Literal(RValue):
    def __init__(self, val):
        RValue.__init__(self)
        self.val = val

    def storeTo(self, dest_regnum):
        return genInstr("LITERAL", dest_regnum, self.val)


class NewObjLiteral(RValue):
    def __init__(self): RValue.__init__(self)
    def storeTo(self, dest_regnum):
        return genInstr("NEWOBJECT", dest_regnum)

class Local(LValue):

    def __init__(self):
        LValue.__init__(self)
        self.init = False

    @staticmethod
    def fromVar(var, instr=''):
        self = Local()
        self.regnum = variableToRegister(str(var))
        self.instr = instr
        self.init = True
        return self

    @staticmethod
    def fromReg(reg, instr=''):
        self = Local()
        self.regnum = str(reg)
        self.instr = instr
        self.init = True
        return self

    @assert_init
    def hasRegister(self): return True
    @assert_init
    def getRegister(self): return self.regnum

    @assert_init
    def genAssign(self, source):
        instr = self.instr + source.storeTo(self.regnum)
        return [CodeSequence(instr, self.regnum)]

    @assert_init
    def storeTo(self, dest_regnum):
        return self.instr + genInstr("MOVE", dest_regnum, self.regnum)

class Global(LValue):
    def __init__(self, name):
        LValue.__init__(self)
        self.name = name

    def genAssign(self, source):
        regnum = self.resolveSrcReg(source);
        instr = self.instr + genInstr("STOREGLOBAL", regnum, stringify(self.name))
        return [CodeSequence(instr, regnum)]

    def storeTo(self, regnum):
        return self.instr + genInstr("LOADGLOBAL", regnum, stringify(self.name))


class Member(LValue):
    def __init__(self, var, name):
        LValue.__init__(self)
        assert(isinstance(var, Value))
        self.name = name
        self.var = var
        self.instr = var.instr

        # if this is a member, of a member, generate a load
        if not isinstance(var, Local): self.reduceVar()

        # if name is actually a list of names, we need to reduce them
        if type(self.name) == type([]): self.reduceName()

    def reduceVar(self):
        regnum = allocTempReg()
        self.instr += self.var.storeTo(regnum)
        self.var = Local.fromReg(regnum)

    def reduceName(self):
        assert(len(self.name) > 0)
        last_name = self.name[-1]
        assert(type(last_name) == type(''))
        name_list = self.name[:-1]

        ## reduce each name
        new_reg = allocTempReg()
        new_var = Local.fromReg(new_reg)
        for n in name_list:
            assert(type(n) == type(''))
            self.name = n
            self.instr = self.storeTo(new_reg)
            self.var = new_var

        ## set the final self.name
        self.name = last_name


    def storeTo(self, dest_regnum):
        self_regnum = self.var.getRegister()
        return self.instr + genInstr("GETMEMBER", self_regnum, dest_regnum, stringify(self.name))

    def genAssign(self, source):
        regnum = self.resolveSrcReg(source);
        self_regnum = self.var.getRegister()
        instr = self.instr + genInstr("SETMEMBER", self_regnum, regnum, stringify(self.name))
        return [CodeSequence(instr, regnum)]


