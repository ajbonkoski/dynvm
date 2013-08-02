
varMap = {}
nextReg = 1

def variableToRegister(variable):
    global varMap, nextReg
    if variable not in varMap:
        varMap[variable] = nextReg
        nextReg += 1
    return str(varMap[variable])

def getTempReg():
    return str(0) # r0 is always considered the temp for this compiler

def genLoadLiteral(regnum, literal):
    return "    LITERAL        r" + regnum + "  " + literal + "\n"

def genNewObject(regnum):
    return "    NEWOBJECT      r" + regnum + "\n"

def genStoreGlobal(regnum, name):
    return "    STOREGLOBAL    r"+regnum + "  \"" + name + "\"\n"

def genLoadGlobal(regnum, name):
    return "    LOADGLOBAL     r"+regnum + "  \"" + name + "\"\n"

def genGetMember(self_regnum, dest_regnum, name):
    return "    SETSELF        r"+self_regnum+"\n" + \
           "    GET            r"+dest_regnum+"  \""+name+"\"\n"

def genSetMember(self_regnum, dest_regnum, name):
    return "    SETSELF        r"+self_regnum+"\n" + \
           "    SET            r"+dest_regnum+"  \""+name+"\"\n"

def genMove(dest_regnum, src_regnum):
    return "    MOVE           r"+dest_regnum+"  r"+src_regnum+"\n"

def genEnd():
    return "    RET            r0  r0\n"


class Value:
    def hasRegister(self):
        return False

class Literal(Value):
    def __init__(self, val):
        self.val = val

    def storeTo(self, dest_regnum):
        return genLoadLiteral(dest_regnum, self.val)


class NewObjLiteral(Value):
    def storeTo(self, dest_regnum):
        return genNewObject(dest_regnum)


class Local(Value):
    def __init__(self, val):
        if type(val) == type(''):
            self.regnum = variableToRegister(val)
        elif type(val) == type(0):
            self.regnum = str(val)
        else:
            raise Exception("Local() constructor received invalid type")

    def genAssign(self, source):
        return source.storeTo(self.regnum)

    def storeTo(self, dest_regnum):
        return genMove(dest_regnum, self.regnum)

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
        return genGetMember(self_regnum, dest_regnum, self.name)

    def genAssign(self, source):
        if not source.hasRegister():
            regnum = getTempReg()
            self.instr += source.storeTo(regnum)
        else:
            regnum = source.getRegister()

        self_regnum = self.var.getRegister()
        return self.instr + genSetMember(self_regnum, regnum, self.name)
