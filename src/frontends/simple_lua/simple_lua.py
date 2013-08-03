
varMap = {}
nextReg = 2
lastAssignedReg = -1

def variableToRegister(variable):
    global varMap, nextReg
    if variable not in varMap:
        varMap[variable] = nextReg
        nextReg += 1
    return str(varMap[variable])

binOpNameMap = {
    '+': '__op_add',
    '-': '__op_sub',
    '*': '__op_mul',
    '/': '__op_div',
}

# r0,r1 are always considered the temp for this compiler
def getTempReg(which=0):
    return str(which)

def stringify(s): return "\"{}\"".format(s)

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

#####################################################################

def genLoadLiteral(regnum, literal):
    return genInstr_iABx("LITERAL", regnum, literal)

def genLoadGlobal(regnum, name):
    return genInstr_iABx("LOADGLOBAL", regnum, stringify(name))

def genStoreGlobal(regnum, name):
    return genInstr_iABx("STOREGLOBAL", regnum, stringify(name))

def genMove(dest_regnum, src_regnum):
    return genInstr_iAB("MOVE", dest_regnum, src_regnum)

def genRet(regnum):
    return genInstr_iA("RET", regnum)

def genNewObject(regnum):
    return genInstr_iA("NEWOBJECT", regnum)

def genGetMember(self_regnum, dest_regnum, name):
    return genInstr_iA  ("SETSELF", self_regnum) + \
           genInstr_iABx("GET",     dest_regnum, stringify(name))

def genSetMember(self_regnum, dest_regnum, name):
    return genInstr_iA  ("SETSELF", self_regnum) + \
           genInstr_iABx("SET",     dest_regnum, stringify(name))

def genCall(dest_regnum, call_regnum, arg_regnum):
    return genInstr_iABC("CALL", dest_regnum, call_regnum, arg_regnum)


def genBinCall(val_a, ops_list): #op_name, val_b):

    call_reg = getTempReg(0)
    dest_reg = call_reg  # replace the function ptr with the ret val
    arg_reg = getTempReg(1)
    instr = ''

    for op_name, val_b in ops_list:
        m = Member(val_a, binOpNameMap[op_name])
        instr += m.storeTo(call_reg);
        instr += val_b.storeTo(arg_reg);
        global lastAssignedReg; lastAssignedReg = dest_reg
        instr += genCall(dest_reg, call_reg, arg_reg)
        val_a = Local(int(dest_reg), instr)

    return [val_a]


def genEnd(): return genRet(lastAssignedReg);


class Value:
    def hasRegister(self):
        return False

class Literal(Value):
    def __init__(self, val):
        self.val = val
        self.instr = ''

    def storeTo(self, dest_regnum):
        return genLoadLiteral(dest_regnum, self.val)


class NewObjLiteral(Value):
    def storeTo(self, dest_regnum):
        return genNewObject(dest_regnum)


class Local(Value):
    def __init__(self, val, instr=''):
        self.instr = instr

        if type(val) == type(''):
            self.regnum = variableToRegister(val)
        elif type(val) == type(0):
            self.regnum = str(val)
        else:
            raise Exception("Local() constructor received invalid type")

    def genAssign(self, source):
        global lastAssignedReg; lastAssignedReg = self.regnum
        return self.instr + source.storeTo(self.regnum)

    def storeTo(self, dest_regnum):
        return self.instr + genMove(dest_regnum, self.regnum)

    def hasRegister(self):
        return True

    def getRegister(self):
        return self.regnum


class Global(Value):
    def __init__(self, name):
        self.name = name
        self.instr = ''

    def genAssign(self, source):
        instr = ''
        if not source.hasRegister():
            regnum = getTempReg()
            instr = source.storeTo(regnum)
        else:
            regnum = source.getRegister()

        global lastAssignedReg; lastAssignedReg = regnum
        return instr + genStoreGlobal(regnum, self.name)

    def storeTo(self, regnum):
        return genLoadGlobal(regnum, self.name)


class Member(Value):
    def __init__(self, var, name):
        self.name = name
        self.instr = ''

        # if this is a member, of a member, generate a load
        if not isinstance(var, Local):
            regnum = getTempReg()
            self.instr = var.instr + var.storeTo(regnum)
            self.var = Local(int(regnum))

        else:
            self.var = var

    def storeTo(self, dest_regnum):
        self_regnum = self.var.getRegister()
        return self.instr + genGetMember(self_regnum, dest_regnum, self.name)

    def genAssign(self, source):
        if not source.hasRegister():
            regnum = getTempReg()
            self.instr += source.storeTo(regnum)
        else:
            regnum = source.getRegister()
            self.instr += source.instr

        self_regnum = self.var.getRegister()
        global lastAssignedReg; lastAssignedReg = regnum
        return self.instr + genSetMember(self_regnum, regnum, self.name)
