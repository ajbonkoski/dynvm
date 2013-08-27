DC = dmd
#DC = ldc2
#DC = gdc

INCLUDE_PATH = ../ddynasm/import
DEBUG_FLAGS = -O -m64 -unittest -debug -gc -I$(INCLUDE_PATH)
RELEASE_FLAGS = -O -gc -m64 -release -inline -noboundscheck -I$(INCLUDE_PATH)
PROFILE_FLAGS = -O -gc -m64 -profile -release -inline -noboundscheck -I$(INCLUDE_PATH)

DYNVM_BIN = ../bin/dynvm
DYNVM_DEBUG_BIN = ../bin/dynvm-debug
DYNVM_PROFILE_BIN = ../bin/dynvm-profile
DYNVM_OBJ = ../bin/dynvm.o ../bin/dynvm-debug.o ../bin/dynvm-profile.o
DYNVM_SRC =              \
common/common.d          \
common/dynasm_util.d     \
datastruct/stack.d       \
datastruct/hashtable.d   \
main.d                   \
hlasm/instructions.d     \
hlasm/literal.d          \
hlasm/code_obj.d         \
hlasm/assembler.d        \
vm/executor.d            \
vm/dyn_obj.d             \
vm/stack_frame.d         \
vm/state.d               \
vm/interpreter.d         \
vm/gc/gc.d               \

DYNVM_DASD_SRC =              \
	vm/jit/dynasm_util.d  \
	vm/jit/dispatch.d     \

DDYNASM_LINK = ../ddynasm/import/ddynasm/dasm_x86.d ../ddynasm/lib/ddynasm.a

DEBUG = $(DYNVM_DEBUG_BIN)
debug:  $(DEBUG)
	rm -f $(DYNVM_BIN) $(DYNVM_PROFILE_BIN)

PROFILE = $(DYNVM_PROFILE_BIN)
profile:  $(PROFILE)
	rm -f $(DYNVM_BIN) $(DYNVM_DEBUG_BIN)

RELEASE = $(DYNVM_BIN)
release: $(RELEASE)
	rm -f $(DYNVM_DEBUG_BIN) $(DYNVM_PROFILE_BIN)

all: $(DYNVM_DEBUG_BIN) $(DYNVM_PROFILE_BIN) $(DYNVM_BIN)

$(DYNVM_BIN): $(DYNVM_SRC) $(DYNVM_DASD_SRC) $(DDYNASM_LINK)
	$(DC) $(RELEASE_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(DYNVM_DEBUG_BIN): $(DYNVM_SRC) $(DYNVM_DASD_SRC) $(DDYNASM_LINK)
	$(DC) $(DEBUG_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(DYNVM_PROFILE_BIN): $(DYNVM_SRC) $(DYNVM_DASD_SRC) $(DDYNASM_LINK)
	$(DC) $(PROFILE_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

%.d: %.dasd
	../ddynasm/bin/ddynasm $< > $@

clean:
	rm -f $(RELEASE) $(DEBUG) $(PROFILE) $(DYNVM_OBJ) $(DYNVM_DASD_SRC) *.o
