module vm.executor;

import std.stdio;
import common.common;
import hlasm.code_obj;
import vm.state;
import vm.dyn_obj;
import vm.interpreter;
import vm.jit.dispatch;

void execute(CodeObject co, bool use_jit, bool silent)
{
  auto state = State(co);

  try {

    if(use_jit)
      state.jitCode(silent);
    else
      state.interpretCode(silent);

  } catch(Throwable t) {
    writeln("==== CRASH: ====");
    writeln(t.msg);
    writeln(t.info);
  }

  if(!silent) {
    writeln("==== Final State: ====");
    writeln(state.stringify(new IndentedWriter(4)).data);
  } else {
    writeln(state.ret.Dyn_pretty);
  }

}
