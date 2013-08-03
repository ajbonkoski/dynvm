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

binOpNameMap = {
    '+': '__op_add',
    '-': '__op_sub',
    '*': '__op_mul',
    '/': '__op_div',
}

######################### INSTRUCTIONS ##############################
C1_SP  = ' '*4
C2_OP  = '{:15}'
C3_REG = ' r{:5}'
C4_BX  = ' {}'
C4_REG = ' r{:5}'
C5_REG = ' r{:5}'
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

def genInstr_iMb(opcode, self_reg, dest_reg, literal):
    return genInstr("SETSELF",  self_reg) + \
           genInstr(opcode[:3], dest_reg, literal)

instructions = {
    'LITERAL':      genInstr_iABx,
    'LOADGLOBAL':   genInstr_iABx,
    'STOREGLOBAL':  genInstr_iABx,
    'MOVE':         genInstr_iAB,
    'RET':          genInstr_iA,
    'NEWOBJECT':    genInstr_iA,
    'SETSELF':      genInstr_iA,
    'GET':          genInstr_iABx,
    'SET':          genInstr_iABx,
    'GETMEMBER':    genInstr_iMb,
    'SETMEMBER':    genInstr_iMb,
    'CALL':         genInstr_iABC,
}

class UnknownInstruction(Exception): pass
def genInstr(*args):
    assert len(args) >= 0
    opcode = args[0]
    if opcode not in instructions:
        raise UnknownInstruction(opcode)
    return instructions[opcode](opcode, *args[1:])

#####################################################################




def genBinCall(val_a, ops_list):

    call_reg = allocTempReg()
    dest_reg = call_reg  # replace the function ptr with the ret val
    arg_reg = allocTempReg()

    for op_name, val_b in ops_list:
        instr = ''
        m = Member(val_a, binOpNameMap[op_name])
        instr += m.storeTo(call_reg)
        instr += val_b.storeTo(arg_reg)
        global lastAssignedReg; lastAssignedReg = dest_reg
        instr += genInstr("CALL", dest_reg, call_reg, arg_reg)
        val_a = Local.fromReg(dest_reg, instr)

    return [val_a]


def genEnd():
    return genInstr("RET", lastAssignedReg);





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
            return self.instr
        else:
            return self.storeTo(allocTempReg())

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
        global lastAssignedReg; lastAssignedReg = dest_regnum
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
        global lastAssignedReg; lastAssignedReg = self.regnum
        return self.instr + source.storeTo(self.regnum)

    @assert_init
    def storeTo(self, dest_regnum):
        return self.instr + genInstr("MOVE", dest_regnum, self.regnum)

class Global(LValue):
    def __init__(self, name):
        LValue.__init__(self)
        self.name = name

    def genAssign(self, source):
        regnum = self.resolveSrcReg(source);
        global lastAssignedReg; lastAssignedReg = regnum
        return self.instr + genInstr("STOREGLOBAL", regnum, stringify(self.name))

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
        global lastAssignedReg; lastAssignedReg = regnum
        return self.instr + genInstr("SETMEMBER", self_regnum, regnum, stringify(self.name))
