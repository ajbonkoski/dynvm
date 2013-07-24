module interpret.interpret;

import dasm.code_obj;
import interpret.state;

void interpretCode(CodeObject co)
{
    auto state = new State(co);

}
